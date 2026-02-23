# =========================
# IMPORTATIONS DJANGO REST FRAMEWORK (AUTHENTIFICATION)
# =========================

# pour créer des vues  Inscription, Profil
from rest_framework.views import APIView

#pour envoyer les données JSON vers Flutter
from rest_framework.response import Response

# les codes HTTP ex: 200 OK, 201 Created, 400 Bad Request
from rest_framework import status

# pour voir si l'utilisateur a un token valide
from rest_framework.permissions import IsAuthenticated

# autorise tout le monde pour le login et l'inscription
from rest_framework.permissions import AllowAny

#pour gérer la connexion
from rest_framework_simplejwt.views import TokenObtainPairView

# =========================
# IMPORTATION DE NOS MODÈLES ET SERIALIZERS
# =========================

from .models import *

from .serializers import *



#pour la connexion
class Login(TokenObtainPairView):

      pass

#creer les comptes
class inscription(APIView):

      permission_classes = [AllowAny]

      def post(self, request):
            serializer = InscriptionSerializer(data=request.data)

            if serializer.is_valid():
                  serializer.save()
                  return Response({"success": True, "message": "Compte créé avec succès"}, status=status.HTTP_201_CREATED)

            else :
                  return Response({"success": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)



#profil utilisateur apres la connexion

class UserProfil(APIView):
      permission_classes = [IsAuthenticated]

      def get(self, request):
            user = request.user
            data = {}

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