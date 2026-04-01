# ====================================================================================================
# IMPORTATIONS CONSOLIDÉES
# ====================================================================================================
import os
from datetime import datetime
from django.shortcuts import get_object_or_404
from django.utils import timezone
from dotenv import load_dotenv

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

from lamessin_app.models import Utilisateur, Patient, Medecin, Pharmacien, Notification
from lamessin_app.serializers import (
    CustomTokenObtainPairSerializer,
    InscriptionSerializer,
    UtilisateurSerializer,
    PatientSerializer,
    MedecinSerializer,
    PharmacienSerializer,
    NotificationSerializer
)

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
        if not token: return Response({"error": "Token requis"}, status=400)
        request.user.fcm_token = token
        request.user.save()
        return Response({"success": True})