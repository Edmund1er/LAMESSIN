# ====================================================================================================
# IMPORTATIONS
# ====================================================================================================
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView

from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
from django.db import transaction
from django.utils.dateparse import parse_date
from django.utils import timezone
from django.shortcuts import get_object_or_404
import json
import requests
from datetime import datetime, timedelta

# Importation pour les notifications Firebase
from firebase_admin import messaging


#pourle chat bot
import os
from dotenv import load_dotenv
import google.generativeai as genai

from .models import *
from .serializers import *

# Configuration Globale FedaPay

FEDAPAY_SECRET_KEY = "sk_sandbox_-OZyOtHCUyKTfru8x0_xdeP8"
FEDAPAY_URL = "https://sandbox-api.fedapay.com/v1"


# Si api.env est dans le même dossier que manage.py :

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(BASE_DIR, 'api.env'))

# Vérification de sécurité
# Configuration de Gemini

genai.configure(api_key=os.environ.get("GEMINI_KEY"))
model_gemini = genai.GenerativeModel('gemini-1.5-flash')


# ====================================================================================================
# FONCTION UTILITAIRE : NOTIFICATIONS PUSH
# ====================================================================================================

def notifier_paiement_reussi(utilisateur, commande_id):

    if not utilisateur.fcm_token:
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title="Paiement validé",
            body=f"Votre commande n°{commande_id} est confirmée. La pharmacie a été créditée.",
        ),
        data={
            "type": "PAIEMENT_VALIDE",
            "commande_id": str(commande_id),
        },
        token=utilisateur.fcm_token,
    )

    try:
        messaging.send(message)
    except Exception as e:
        print(f"Erreur FCM: {e}")

# ====================================================================================================
# AUTHENTIFICATION & PROFIL
# ====================================================================================================

class Login(TokenObtainPairView):

    pass

class inscription(APIView):

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = InscriptionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"success": True, "message": "Compte créé avec succès"}, status=status.HTTP_201_CREATED)
        return Response({"success": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

class UserProfil(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.est_un_compte_patient:
            profile = Patient.objects.get(compte_utilisateur=user)
            data = PatientSerializer(profile).data
        elif user.est_un_compte_medecin:
            profile = Medecin.objects.get(compte_utilisateur=user)
            data = MedecinSerializer(profile).data
        elif user.est_un_compte_pharmacien:
            profile = Pharmacien.objects.get(compte_utilisateur=user)
            data = PharmacienSerializer(profile).data
        else:
            data = UtilisateurSerializer(user).data
        return Response(data)

class UpdateProfilView(APIView):

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        user = request.user
        data = request.data
        user.first_name = data.get('first_name', user.first_name)
        user.last_name = data.get('last_name', user.last_name)
        user.numero_telephone = data.get('numero_telephone', user.numero_telephone)
        user.save()
        return Response({"success": True})

# ====================================================================================================
# GESTION MÉDICALE (MÉDICAMENTS, SOINS, ÉTABLISSEMENTS)
# ====================================================================================================

class RechercheMedicament(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '')
        if query:
            medicaments = Medicament.objects.filter(nom_commercial__istartswith=query)
        else:
            medicaments = Medicament.objects.all()[:50]
        serializer = MedicamentsSerializer(medicaments, many=True)
        return Response(serializer.data)

class EnregistrerSoin(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not request.user.est_un_compte_medecin:
            return Response({"error": "Accès réservé aux médecins"}, status=403)
        serializer = ConsultationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ListeEtablissements(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        type_filtre = request.query_params.get('type')
        if type_filtre:
            etablissements = EtablissementSante.objects.filter(type_etablissement=type_filtre)
        else:
            etablissements = EtablissementSante.objects.all()
        return Response(EtablissementSanteSerializer(etablissements, many=True).data)

# ====================================================================================================
# RENDEZ-VOUS
# ====================================================================================================

class LiteMedecins(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        medecins = Medecin.objects.all()
        serializer = MedecinSerializer(medecins, many=True)
        return Response(serializer.data)

class CreezRendezVous(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
        except Patient.DoesNotExist:
            return Response({"error": "Seuls les patients peuvent prendre RDV"}, status=403)
        data = request.data.copy()
        data['patient_demandeur'] = patient.pk
        serializer = RendezVousCreateSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response({"success": True, "message": "RDV enregistré"}, status=201)
        return Response(serializer.errors, status=400)

class CreneauxDispo(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        medecin_id = request.query_params.get('medecin')
        date_str = request.query_params.get('date')
        if not medecin_id or not date_str:
            return Response({"error": "Paramètres requis."}, status=400)
        date_obj = parse_date(date_str)
        maintenant = timezone.localtime(timezone.now())
        plages = PlageHoraire.objects.filter(medecin_id=medecin_id, date=date_obj)
        rdvs_existants = RendezVous.objects.filter(
            medecin_concerne_id=medecin_id, date_rdv=date_obj
        ).exclude(statut_actuel_rdv="annulé").values_list('heure_rdv', flat=True)
        creneaux = []
        for plage in plages:
            t = datetime.combine(plage.date, plage.heure_debut)
            fin = datetime.combine(plage.date, plage.heure_fin)
            pas = timedelta(minutes=plage.duree_consultation)
            while t + pas <= fin:
                h = t.time()
                if h not in rdvs_existants and not (date_obj == maintenant.date() and h <= maintenant.time()):
                    fmt = h.strftime('%H:%M')
                    creneaux.append({"id": fmt, "heure": fmt})
                t += pas
        return Response(creneaux)

class ListeRendezVousPatient(generics.ListAPIView):

    serializer_class = RendezVousSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return RendezVous.objects.filter(patient_demandeur__compte_utilisateur=self.request.user).order_by('date_rdv', 'heure_rdv')

class AnnulerRendezVous(generics.UpdateAPIView):

    queryset = RendezVous.objects.all()
    serializer_class = RendezVousSerializer
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.patient_demandeur.compte_utilisateur != request.user:
            return Response({"error": "Action non autorisée"}, status=403)
        instance.statut_actuel_rdv = "annulé"
        instance.save()
        return Response({"success": True, "message": "Rendez-vous annulé."})

# ====================================================================================================
# COMMANDES & PAIEMENTS
# ====================================================================================================
class MesCommandesView(generics.ListAPIView):
    serializer_class = CommandeSerializer # Assure-toi que ce serializer existe
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # On ne renvoie que les commandes du patient connecté
        return Commande.objects.filter(patient_acheteur__compte_utilisateur=self.request.user).order_by('-date_commande')


class CreerCommandeMultiple(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        articles = request.data.get('articles', [])
        if not articles:
            return Response({"error": "Panier vide"}, status=400)

        try:
            with transaction.atomic():

                patient = Patient.objects.get(compte_utilisateur=request.user)
                commande = Commande.objects.create(
                    patient_acheteur=patient,
                    prix_total=0,
                    statut_commande='en_attente'
                )

                total_general = 0
                for item in articles:
                    medoc = get_object_or_404(Medicament, id=item['id'])
                    pharma = get_object_or_404(EtablissementSante, id=item['pharmacie_id'])
                    quantite = int(item.get('qte', 1))
                    prix_unitaire = float(medoc.prix_unitaire)

                    LigneCommande.objects.create(
                        ma_commande=commande,  # Vérifie le nom ici
                        medicament_ajoute=medoc,  # Vérifie le nom ici
                        pharmacie_vendeuse=pharma,
                        quantite_commandee=quantite,
                        prix_unitaire=prix_unitaire
                    )
                    total_general += (prix_unitaire * quantite)

                commande.prix_total = total_general
                commande.save()


            headers = {
                "Authorization": f"Bearer {FEDAPAY_SECRET_KEY}",
                "Content-Type": "application/json"
            }

            data_trans = {
                "amount": int(total_general),
                "currency": {"iso": "XOF"},
                "description": f"Commande N°{commande.id} - Lamessin",
                "metadata": {"commande_id": commande.id},
                "callback_url": "https://votre-domaine.com/api/callback",
                "customer": {
                    "firstname": request.user.first_name,
                    "lastname": request.user.last_name,
                    "email": request.user.email or "client@lamessin.tg",
                    "phone_number": {"number": request.user.numero_telephone, "country": "tg"}
                }
            }


            resp = requests.post(f"{FEDAPAY_URL}/transactions", headers=headers, json=data_trans)
            if resp.status_code not in [200, 201]:
                return Response({"error": "Erreur creation FedaPay"}, status=400)

            res_data = resp.json()
            trans_id = res_data['v1/transaction']['id']

            resp_token = requests.post(f"{FEDAPAY_URL}/transactions/{trans_id}/token", headers=headers)
            token_data = resp_token.json()

            return Response({
                'success': True,
                'payment_url': token_data['v1/token']['url'],
                'commande_id': commande.id
            })

        except Exception as e:
            return Response({'error': str(e)}, status=400)


class GenererLienPaiement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        commande = get_object_or_404(Commande, id=commande_id, patient_acheteur__compte_utilisateur=request.user)
        if commande.statut_commande == 'paye':
            return Response({'error': 'Déjà payée'}, status=400)

        headers = {"Authorization": f"Bearer {FEDAPAY_SECRET_KEY}", "Content-Type": "application/json"}
        data = {
            "amount": int(commande.prix_total),
            "currency": {"iso": "XOF"},
            "description": f"Paiement N°{commande.id}",
            "customer": {
                "firstname": request.user.first_name,
                "lastname": request.user.last_name,
                "email": request.user.email or "client@lamessin.tg",
                "phone_number": {"number": request.user.numero_telephone, "country": "tg"}
            }
        }

        try:
            resp = requests.post(f"{FEDAPAY_URL}/transactions", headers=headers, json=data)
            res_data = resp.json()
            trans_id = res_data['v1/transaction']['id']

            resp_token = requests.post(f"{FEDAPAY_URL}/transactions/{trans_id}/token", headers=headers)
            return Response({'payment_url': resp_token.json()['v1/token']['url']})
        except Exception as e:
            return Response({'error': str(e)}, status=400)


@csrf_exempt
def fedapay_webhook(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)

            entity = data.get('entity')
            status_feda = data.get('status')

            if entity == 'transaction' and status_feda == 'approved':
                metadata = data.get('metadata', {})
                commande_id = metadata.get('commande_id')

                if commande_id:
                    commande = Commande.objects.filter(id=commande_id).first()
                    if commande and commande.statut_commande != 'paye':
                        commande.statut_commande = 'paye'
                        commande.save()

                        notifier_paiement_reussi(
                            commande.patient_acheteur.compte_utilisateur,
                            commande.id
                        )
            return HttpResponse(status=200)
        except Exception as e:
            print(f"Erreur Webhook: {e}")
            return HttpResponse(status=400)
    return HttpResponse(status=405)
# ====================================================================================================
# NOTIFICATIONS & FCM
# ====================================================================================================

class ListeTraitementsPatient(APIView):
# Liste des traitements
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            traitements = Traitement.objects.filter(patient_concerne=patient)
            return Response(TraitementSerializer(traitements, many=True).data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)

class ListeNotifications(APIView):
# Historique des notifications
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(destinataire=request.user).order_by('-heure_envoi')
        return Response(NotificationSerializer(notifications, many=True).data)

class EnregistrerFCMToken(APIView):
# Enregistrement du token
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        if not token: return Response({"error": "Token requis"}, status=400)
        request.user.fcm_token = token
        request.user.save()
        return Response({"success": True})


# ======================================================================================================================================
# ORDONNANCES ET TRAITEMENTS CÔTÉ PATIENT
# ======================================================================================================================================

class ListeOrdonnancesPatient(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            ordonnances = Ordonnance.objects.filter(patient_beneficiaire=patient).order_by('-date_prescription')
            serializer = OrdonnanceSerializer(ordonnances, many=True)
            return Response(serializer.data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)

class DetailTraitement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        traitement = get_object_or_404(Traitement, id=pk, patient_concerne__compte_utilisateur=request.user)
        # On récupère aussi les prises associées à ce traitement
        prises = PriseMedicament.objects.filter(traitement=traitement).order_by('date_prise_reelle','heure_prise_prevue')

        data = TraitementSerializer(traitement).data
        data['historique_prises'] = PriseMedicamentSerializer(prises, many=True).data
        return Response(data)

class ValiderPriseMedicament(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, prise_id):
        prise = get_object_or_404(PriseMedicament, id=prise_id,
                                  traitement__patient_concerne__compte_utilisateur=request.user)
        prise.prise_effectuee = True
        prise.date_prise_reelle = timezone.now().date()
        prise.save()
        return Response({"success": True, "message": "Prise enregistrée"})

# ======================================================================================================================================
# ASSISTANT CHATBOT
# ======================================================================================================================================
class ChatbotGeminiView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user_prompt = request.data.get("prompt")

        if not user_prompt:
            return Response({"error": "Le message ne peut pas être vide."}, status=400)

# 1. On récupère ou on crée la session Chatbot liée à l'utilisateur
        session, _ = Chatbot.objects.get_or_create(utilisateur=request.user)

# 2. On sauvegarde le message envoyé par le patient
        Message.objects.create(
            chatbot_associe=session,
            contenu_texte=user_prompt,
            envoye_par_utilisateur=True
        )

        try:
# 3. Appel à l'IA Gemini avec des paramètres de sécurité
            response = model_gemini.generate_content(
                user_prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=500,
                    temperature=0.7,
                )
            )

            reponse_ia = response.text

# 4. On sauvegarde la réponse de l'IA dans l'historique
            message_bot = Message.objects.create(
                chatbot_associe=session,
                contenu_texte=reponse_ia,
                envoye_par_utilisateur=False
            )

# 5. On renvoie le message de l'IA au format JSON (via le Serializer)
            return Response(MessageSerializer(message_bot).data, status=status.HTTP_201_CREATED)

        except Exception as e:
            print(f"--- ERREUR GEMINI --- : {str(e)}")
            return Response({
                "error": "L'assistant est indisponible pour le moment.",
                "details": str(e)
            }, status=500)


class AssistantHistoriqueView(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):
# On récupère la session de l'utilisateur
        session, _ = Chatbot.objects.get_or_create(utilisateur=request.user)

# On récupère tous les messages triés par heure
        messages = Message.objects.filter(chatbot_associe=session).order_by('heure_message')

        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)
