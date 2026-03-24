# ====================================================================================================
# IMPORTATIONS CONSOLIDÉES
# ====================================================================================================
import os
import json
import requests
from datetime import datetime, timedelta

from django.db import transaction
from django.utils.dateparse import parse_date
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from dotenv import load_dotenv

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

import google.generativeai as genai
from firebase_admin import messaging

from .models import *
from .serializers import *

# ====================================================================================================
# CONFIGURATION GLOBALE & ENVIRONNEMENT
# ====================================================================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(BASE_DIR, 'api.env'))

FEDAPAY_SECRET_KEY = "sk_sandbox_-OZyOtHCUyKTfru8x0_xdeP8"
FEDAPAY_URL = "https://sandbox-api.fedapay.com/v1"

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
# AUTHENTIFICATION & SESSION PERMANENTE (LOGIQUE MODERNE)
# ====================================================================================================

class Login(TokenObtainPairView):
    """
    Retourne Access et Refresh Token.
    Flutter doit stocker le 'refresh' pour renouveler la session automatiquement.
    """
    serializer_class = CustomTokenObtainPairSerializer
    pass


class LogoutView(APIView):
    """
    Déconnexion manuelle : invalide le refresh token.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"success": True, "message": "Déconnecté"}, status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response({"error": "Token invalide ou déjà révoqué"}, status=status.HTTP_400_BAD_REQUEST)


class InscriptionView(APIView):
    """
    Inscription + Connexion automatique (génération de tokens).
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = InscriptionSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                "success": True,
                "message": "Compte créé avec succès",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }, status=status.HTTP_201_CREATED)
        return Response({"success": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)


# ====================================================================================================
# PROFIL & UTILISATEUR
# ====================================================================================================

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
        medicaments = Medicament.objects.filter(
            nom_commercial__istartswith=query) if query else Medicament.objects.all()[:50]
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
        etablissements = EtablissementSante.objects.filter(
            type_etablissement=type_filtre) if type_filtre else EtablissementSante.objects.all()
        return Response(EtablissementSanteSerializer(etablissements, many=True).data)


# ====================================================================================================
# RENDEZ-VOUS
# ====================================================================================================

class LiteMedecins(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medecins = Medecin.objects.all()
        return Response(MedecinSerializer(medecins, many=True).data)


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
        return RendezVous.objects.filter(patient_demandeur__compte_utilisateur=self.request.user).order_by('date_rdv',
                                                                                                           'heure_rdv')


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
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Commande.objects.filter(patient__compte_utilisateur=self.request.user).order_by(
            '-date_creation')


# ====================================================================================================
# CONFIGURATION CINETPAY
# ====================================================================================================
CINETPAY_API_KEY = os.environ.get("CINETPAY_API_KEY")
CINETPAY_SITE_ID = os.environ.get("CINETPAY_SITE_ID")
CINETPAY_URL = "https://api-checkout.cinetpay.com/v2/payment"


class CreerCommandeMultiple(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        articles = request.data.get('articles', [])
        if not articles:
            return Response({"error": "Panier vide"}, status=400)

        try:
            with transaction.atomic():
                patient = Patient.objects.get(compte_utilisateur=request.user)
                trans_id = f"CMD-{datetime.now().strftime('%Y%m%d%H%M%S')}-{request.user.id}"

                # CORRECTION ICI : Utilisation des champs exacts du modèle
                commande = Commande.objects.create(
                    patient=patient,
                    total=0,
                    statut='EN_ATTENTE',
                )

                total_general = 0

                for item in articles:

                    medoc = get_object_or_404(Medicament, id=item['id'])

                    # On cherche la pharmacie via l'ID contenu dans l'objet StockPharmacie
                    pharmacie = get_object_or_404(Pharmacie, id=item['id_pharmacie'])

                    qte = int(item.get('qte', 1))
                    pv = float(medoc.prix_vente)

                    LigneCommande.objects.create(
                        ma_commande=commande,
                        produit=medoc,
                        pharmacie=pharmacie,  # Maintenant, on a la bonne pharmacie (ID 1)
                        quantite=qte,
                        prix_unitaire=pv
                    )
                    total_general += (pv * qte)

                commande.total = total_general
                commande.save()

            payload = {
                "apikey": CINETPAY_API_KEY,
                "site_id": CINETPAY_SITE_ID,
                "transaction_id": trans_id,
                "amount": int(total_general),
                "currency": "XOF",
                "alternative_currency": "",
                "description": f"Achat médicaments Commande N°{commande.id}",
                "customer_name": request.user.last_name,
                "customer_surname": request.user.first_name,
                "customer_email": request.user.email or "client@lamessin.tg",
                "customer_phone_number": request.user.numero_telephone,
                "customer_address": "Lomé",
                "customer_city": "Lomé",
                "customer_country": "TG",
                "customer_state": "TG",
                "customer_zip_code": "00228",
                "notify_url": f"{os.environ.get('MY_DOMAIN')}/api/cinetpay-webhook/",
                "return_url": "https://ton-domaine.com/paiement-succes/",
                "channels": "ALL",
                "metadata": str(commande.id)
            }

            resp = requests.post(CINETPAY_URL, json=payload)
            resp_data = resp.json()

            if resp_data.get('code') == '201':
                return Response({
                    'success': True,
                    'payment_url': resp_data['data']['payment_url'],
                    'commande_id': commande.id
                })
            else:
                return Response({'error': resp_data.get('message')}, status=400)

        except Exception as e:
            return Response({'error': str(e)}, status=400)


class GenererLienPaiement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        commande = get_object_or_404(Commande, id=commande_id, patient__compte_utilisateur=request.user)
        # CORRECTION ICI : Vérification du statut
        if commande.statut == 'PAYE':
            return Response({'error': 'Déjà payée'}, status=400)

        trans_id = f"CMD-RETRY-{commande.id}-{int(datetime.now().timestamp())}"

        payload = {
            "apikey": CINETPAY_API_KEY,
            "site_id": CINETPAY_SITE_ID,
            "transaction_id": trans_id,
            "amount": int(commande.total),
            "currency": "XOF",
            "description": f"Relance Paiement Commande N°{commande.id}",
            "customer_name": request.user.last_name,
            "customer_surname": request.user.first_name,
            "metadata": str(commande.id),
            "notify_url": f"{os.environ.get('MY_DOMAIN')}/api/cinetpay-webhook/",
            "return_url": f"{os.environ.get('MY_DOMAIN')}/paiement-succes/",
            "channels": "ALL"
        }

        try:
            resp = requests.post(CINETPAY_URL, json=payload)
            resp_data = resp.json()
            return Response({'payment_url': resp_data['data']['payment_url']})
        except Exception as e:
            return Response({'error': "Impossible de générer le lien"}, status=400)


@csrf_exempt
def cinetpay_webhook(request):
    if request.method == 'POST':
        trans_id = request.POST.get('cpm_trans_id')
        site_id = request.POST.get('cpm_site_id')

        check_url = "https://api-checkout.cinetpay.com/v2/payment/check"
        payload = {
            "apikey": CINETPAY_API_KEY,
            "site_id": CINETPAY_SITE_ID,
            "transaction_id": trans_id
        }

        try:
            response = requests.post(check_url, json=payload)
            res_data = response.json()

            if res_data.get('code') == '00':
                commande_id = res_data['data'].get('metadata')

                with transaction.atomic():
                    commande = Commande.objects.get(id=commande_id)
                    # CORRECTION ICI : Vérification et mise à jour du statut correct
                    if commande.statut != 'PAYE':
                        commande.statut = 'PAYE'
                        commande.save()

                        for ligne in commande.lignes.all():
                            stock = Stock.objects.filter(
                                produit_concerne=ligne.produit,
                                pharmacie_detentrice=ligne.pharmacie
                            ).first()
                            if stock:
                                stock.quantite_actuelle_en_stock -= ligne.quantite
                                stock.save()
                        notifier_paiement_reussi(commande.patient.compte_utilisateur, commande.id)

            return HttpResponse(status=200)
        except Exception as e:
            print(f"Erreur Webhook: {e}")
            return HttpResponse(status=400)

    return HttpResponse(status=405)


# ====================================================================================================
# TRAITEMENTS & NOTIFICATIONS
# ====================================================================================================

class ListeTraitementsPatient(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            traitements = Traitement.objects.filter(patient_concerne=patient)
            return Response(TraitementSerializer(traitements, many=True).data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)


class DetailTraitement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        traitement = get_object_or_404(Traitement, id=pk, patient_concerne__compte_utilisateur=request.user)
        prises = PriseMedicament.objects.filter(traitement=traitement).order_by('date_prise_reelle',
                                                                                'heure_prise_prevue')
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


class ListeOrdonnancesPatient(generics.ListAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Ordonnance.objects.filter(
            patient_beneficiaire__compte_utilisateur=self.request.user
        ).order_by('-date_prescription')


class ListeNotifications(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(destinataire=request.user).order_by('-heure_envoi')
        return Response(NotificationSerializer(notifications, many=True).data)


class EnregistrerFCMToken(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        if not token: return Response({"error": "Token requis"}, status=400)
        request.user.fcm_token = token
        request.user.save()
        return Response({"success": True})


# ====================================================================================================
# DOCUMENTS MÉDICAUX (UPLOAD)
# ====================================================================================================

class UploadDocumentMedicalView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        fichier = request.FILES.get('document')
        if not fichier: return Response({"error": "Aucun fichier fourni"}, status=400)

        if request.user.est_un_compte_medecin:
            consultation_id = request.data.get('consultation_id')
            consultation = get_object_or_404(Consultation, id=consultation_id)
            consultation.document_joint = fichier
            consultation.save()
            return Response({"success": True, "message": "Document enregistré"})

        return Response({"error": "Action non autorisée"}, status=403)


# ====================================================================================================
# ASSISTANT CHATBOT GEMINI
# ====================================================================================================

class ChatbotGeminiView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user_prompt = request.data.get("prompt")
        if not user_prompt: return Response({"error": "Le message ne peut pas être vide."}, status=400)

        session, _ = Chatbot.objects.get_or_create(utilisateur=request.user)
        Message.objects.create(chatbot_associe=session, contenu_texte=user_prompt, envoye_par_utilisateur=True)

        try:
            response = model_gemini.generate_content(
                user_prompt,
                generation_config=genai.types.GenerationConfig(max_output_tokens=500, temperature=0.7)
            )
            reponse_ia = response.text
            message_bot = Message.objects.create(chatbot_associe=session, contenu_texte=reponse_ia,
                                                 envoye_par_utilisateur=False)
            return Response(MessageSerializer(message_bot).data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": "L'assistant est indisponible.", "details": str(e)}, status=500)


class AssistantHistoriqueView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        session, _ = Chatbot.objects.get_or_create(utilisateur=request.user)
        messages = Message.objects.filter(chatbot_associe=session).order_by('heure_message')
        return Response(MessageSerializer(messages, many=True).data)

