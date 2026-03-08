# ======================================================================================================================================================
# IMPORTATIONS
# ======================================================================================================================================================
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView


from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
import json

from django.utils.dateparse import parse_date
from django.utils import timezone
from datetime import datetime, timedelta
from django.db.models import Q  # Pour la recherche complexe

from .models import *
from .serializers import *
import fedapay
from django.shortcuts import get_object_or_404

# ======================================================================================================================================================
# AUTHENTIFICATION & PROFIL
# ======================================================================================================================================================

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
        if user.est_un_compte_patient:
            profile = Patient.objects.get(compte_utilisateur=user)
            return Response(PatientSerializer(profile).data)
        return Response({"success": True})


# ======================================================================================================================================================
# GESTION MÉDICALE (SOINS & ORDONNANCES)
# ======================================================================================================================================================

# --- Recherche de Médicaments ---
class RechercheMedicament(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '')  # On récupère le texte tapé
        if query:
            # Recherche par nom ou description
            medicaments = Medicament.objects.filter(
                Q(nom_commercial__icontains=query) | Q(description__icontains=query)
            )
        else:
            medicaments = Medicament.objects.all()[:20]  # Par défaut les 20 premiers

        serializer = MedicamentSerializer(medicaments, many=True)
        return Response(serializer.data)


# --- Créer une Consultation ---
class EnregistrerSoin(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Seul un médecin peut enregistrer des soins
        if not request.user.est_un_compte_medecin:
            return Response({"error": "Accès réservé aux médecins"}, status=403)

        serializer = ConsultationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ======================================================================================================================================================
# RENDEZ-VOUS
# ======================================================================================================================================================

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
        rdvs_existants = RendezVous.objects.filter(medecin_concerne_id=medecin_id, date_rdv=date_obj).values_list(
            'heure_rdv', flat=True)

        creneaux = []
        for plage in plages:
            debut = datetime.combine(plage.date, plage.heure_debut)
            fin = datetime.combine(plage.date, plage.heure_fin)
            pas = timedelta(minutes=plage.duree_consultation)
            t = debut
            while t + pas <= fin:
                h = t.time()
                pas_pris = h not in rdvs_existants
                est_futur = not (date_obj == maintenant.date() and h <= maintenant.time())
                if pas_pris and est_futur:
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
        return Response({"success": True, "message": "Rendez-vous annulé"})


# ======================================================================================================================================================
# SERVICES GEOLOCALISTAON, RECHERCHE DE PRODUIT, TRAITEMENTS, NOTIFICATIONS
# ======================================================================================================================================================

class ListeEtablissements(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        type_filtre = request.query_params.get('type')
        if type_filtre:
            etablissements = EtablissementSante.objects.filter(type_etablissement=type_filtre)
        else:
            etablissements = EtablissementSante.objects.all()
        return Response(EtablissementSanteSerializer(etablissements, many=True).data)


class ListeNotifications(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(destinataire=request.user).order_by('-heure_envoi')
        return Response(NotificationSerializer(notifications, many=True).data)


class ListeTraitementsPatient(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            traitements = Traitement.objects.filter(patient_concerne=patient)
            return Response(TraitementSerializer(traitements, many=True).data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)

# ======================================================================================================================================================
# COMMANDES ET PAIEMENTS
# ======================================================================================================================================================

class CreerCommandeEtPayer(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            medicament_id = request.data.get('medicament_id')
            quantite = int(request.data.get('quantite', 1))

            medicament = get_object_or_404(Medicament, id=medicament_id)

            # Création de la commande
            commande = Commande.objects.create(
                patient_acheteur=patient,
                statut_commande='en_attente',
                prix_total=medicament.prix_vente * quantite
            )

            # Configuration FedaPay avec ta clé sk_ de l'image
            fedapay.api_key = "sk_sandbox_-OZyOtHCUyKTfru8x0_xdeP8"
            fedapay.api_base = "https://sandbox-api.fedapay.com"

            transaction = fedapay.Transaction.create(
                amount=int(commande.prix_total),
                currency={'iso': 'XOF'},
                description=f"Achat de {medicament.nom_commercial}",
                # ON AJOUTE CECI :
                metadata={
                    'commande_id': commande.id
                },
                customer={
                    'firstname': request.user.first_name,
                    'lastname': request.user.last_name,
                    'email': request.user.email or "client@lamessin.tg",
                    'phone_number': {'number': request.user.numero_telephone, 'country': 'tg'}
                }
            )

            token = transaction.generate_token()
            return Response({
                'success': True,
                'payment_url': token.url,
                'commande_id': commande.id
            })

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

#------------------------------------------------fedapay------------------------------------------------------------
# Obligatoire : FedaPay ne peut pas deviner ton jeton CSRF
@csrf_exempt
def fedapay_webhook(request):
    if request.method == 'POST':
#Récupérer les données envoyées par FedaPay

        payload = request.body
        sig_header = request.META.get('HTTP_X_FEDAPAY_SIGNATURE')
        event = None

        try:
# On décode le JSON envoyé
            event = json.loads(payload)
        except Exception as e:
            return HttpResponse(status=400)

# Vérifier le type d'événement
# FedaPay envoie 'transaction.approved'  quand le paiement réussit

        if event['entity'] == 'transaction' and event['status'] == 'approved':
# On récupère l'ID caché dans les metadata
                commande_id = event.get('metadata', {}).get('commande_id')

                if commande_id:
                    commande = Commande.objects.filter(id=commande_id).first()
                    if commande:
                        commande.statut_commande = 'paye'
                        commande.save()
                        print(f"Confirmation précise : Commande {commande.id} payée !")


# Toujours répondre 200 à FedaPay
        return HttpResponse(status=200)

    return HttpResponse(status=405)

#----------------------------------------------------vue pour payer commande en retard----------------------
class GenererLienPaiement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        commande = get_object_or_404(Commande, id=commande_id, patient_acheteur__compte_utilisateur=request.user)

# On vérifie si elle n'est pas déjà payée
        if commande.statut_commande == 'paye':
            return Response({'error': 'Cette commande est déjà payée'}, status=400)

        try:
            fedapay.api_key = "sk_sandbox_-OZyOtHCUyKTfru8x0_xdeP8"
            fedapay.api_base = "https://sandbox-api.fedapay.com"

            transaction = fedapay.Transaction.create(
                amount=int(commande.prix_total),
                currency={'iso': 'XOF'},
                description=f"Paiement commande N°{commande.id}",
                metadata={'commande_id': commande.id},
                customer={
                    'firstname': request.user.first_name,
                    'lastname': request.user.last_name,
                    'email': request.user.email or "client@lamessin.tg",
                    'phone_number': {'number': request.user.numero_telephone, 'country': 'tg'}
                }
            )
            token = transaction.generate_token()
            return Response({'payment_url': token.url})
        except Exception as e:
            return Response({'error': str(e)}, status=400)