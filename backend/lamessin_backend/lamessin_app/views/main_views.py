# ====================================================================================================
# IMPORTATIONS CONSOLIDÉES
# ====================================================================================================
import os
from datetime import datetime
from django.shortcuts import get_object_or_404
from django.utils import timezone
from dotenv import load_dotenv
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.admin.views.decorators import staff_member_required
from django.http import JsonResponse

from lamessin_app.models import *
from lamessin_app.serializers import *

# ====================================================================================================
# CONFIGURATION GLOBALE & ENVIRONNEMENT
# ====================================================================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(BASE_DIR, 'api.env'))

# ====================================================================================================
# AUTHENTIFICATION & SESSION PERMANENTE (LOGIQUE MODERNE)
# ====================================================================================================

class Login(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
    pass


class LogoutView(APIView):
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
# PROFIL & UTILISATEUR (COMMUN)
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
# NOTIFICATIONS (COMMUN)
# ====================================================================================================

class ListeNotifications(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(destinataire=request.user).order_by('-heure_envoi')
        return Response(NotificationSerializer(notifications, many=True).data)


class EnregistrerFCMToken(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        if not token:
            return Response({"error": "Token requis"}, status=400)
        request.user.fcm_token = token
        request.user.save()
        return Response({"success": True})


# ====================================================================================================
# API POUR LES STATISTIQUES ADMIN (UTILISEE DANS FLUTTER)
# ====================================================================================================

@csrf_exempt
@staff_member_required
def admin_stats_api(request):
    """API pour récupérer les statistiques pour l'admin Flutter"""
    from lamessin_app.models import Utilisateur, Medicament, Commande, RendezVous, Consultation, Ordonnance

    stats = {
        'total_users': Utilisateur.objects.count(),
        'total_patients': Utilisateur.objects.filter(est_un_compte_patient=True).count(),
        'total_medecins': Utilisateur.objects.filter(est_un_compte_medecin=True).count(),
        'total_pharmaciens': Utilisateur.objects.filter(est_un_compte_pharmacien=True).count(),
        'total_medicaments': Medicament.objects.count(),
        'total_commandes': Commande.objects.count(),
        'total_rendezvous': RendezVous.objects.count(),
        'total_consultations': Consultation.objects.count(),
        'total_ordonnances': Ordonnance.objects.count(),
        'recent_users': list(Utilisateur.objects.order_by('-date_joined')[:10].values(
            'id', 'username', 'first_name', 'last_name', 'date_joined',
            'est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien'
        )),
    }

    # Ajouter les commandes par statut
    for statut, label in Commande.STATUTS:
        stats[f'commandes_{statut.lower()}'] = Commande.objects.filter(statut=statut).count()

    # Ajouter les RDV par statut
    stats['rdv_en_attente'] = RendezVous.objects.filter(statut_actuel_rdv='en_attente').count()
    stats['rdv_confirme'] = RendezVous.objects.filter(statut_actuel_rdv='confirme').count()
    stats['rdv_termine'] = RendezVous.objects.filter(statut_actuel_rdv='termine').count()
    stats['rdv_annule'] = RendezVous.objects.filter(statut_actuel_rdv='annule').count()
    stats['rdv_expire'] = RendezVous.objects.filter(statut_actuel_rdv='expire').count()

    return JsonResponse(stats)
