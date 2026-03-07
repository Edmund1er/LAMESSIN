# ======================================================================================================================================================
# IMPORTATIONS DJANGO REST FRAMEWORK (AUTHENTIFICATION)
# ======================================================================================================================================================

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


from django.utils.dateparse import parse_date

from datetime import datetime, timedelta

from rest_framework import generics

# ===============================================================================================================================================================================
# IMPORTATION DE NOS MODÈLES ET SERIALIZERS
# ===============================================================================================================================================================================

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
      
# ===============================================================================================================================================================================
# VUES POUR LES RENDEZ-VOUS
# ===============================================================================================================================================================================

#------------------------------------------------------------liste des medecins-----------------------------------------------------------
class LiteMedecins(APIView):
      permission_classes = [IsAuthenticated]

      def get(self, request):
            Medecins  = Medecin.objects.all()
            serializer = MedecinSerializer(Medecins, many=True)
            return Response(serializer.data, status= status.HTTP_200_OK)

#-------------------------------------------------creer render vous---------------------------------------------------------------------------
class CreezRendezVous(APIView):
      permission_classes = [IsAuthenticated]

      def post(self, request):
            utilisateur = request.user

#verifier que c'est un patient
            try:
                  patient = Patient.objects.get(compte_utilisateur=utilisateur)
            except Patient.DoesNotExist:
                  return Response({"error": "Seuls les patients peuvent prendre RDV"}, status=403)

# Préparation des données
            data = request.data.copy()
            data['patient_demandeur'] = patient.pk

            serializer = RendezVousCreateSerializer(data=data)

            if serializer.is_valid():
                  serializer.save()
                  return Response({
                        "success": True,
                        "message": "Rendez-vous enregistré avec succès"
                  }, status=status.HTTP_201_CREATED)

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#----------------------------------------------------plage d'horaire rendezvous-------------------------------------------------------------
class CreneauxDispo(APIView):
      permission_classes = [IsAuthenticated]

      def get(self, request):
            medecin_id = request.query_params.get('medecin')
            date_str = request.query_params.get('date')

            if not medecin_id or not date_str:
                  return Response({"error": "Paramètres requis."}, status=400)

            date_obj = parse_date(date_str)
            maintenant = timezone.localtime(timezone.now())  # Heure actuelle locale

            plages = PlageHoraire.objects.filter(medecin_id=medecin_id, date=date_obj)
            rdvs_existants = RendezVous.objects.filter(
                  medecin_concerne_id=medecin_id,
                  date_rdv=date_obj
            ).values_list('heure_rdv', flat=True)

            creneaux_virtuels = []

            for plage in plages:
                  debut = datetime.combine(plage.date, plage.heure_debut)
                  fin = datetime.combine(plage.date, plage.heure_fin)
                  pas = timedelta(minutes=plage.duree_consultation)

                  temps_actuel = debut
                  while temps_actuel + pas <= fin:
                        heure_test = temps_actuel.time()

#On vérifie si le créneau est déjà pris
                        pas_pris = heure_test not in rdvs_existants

#Si c'est pour AUJOURD'HUI, on vérifie si l'heure est passée
                        est_futur = True
                        if date_obj == maintenant.date():
                              if heure_test <= maintenant.time():
                                    est_futur = False

                        if pas_pris and est_futur:
                              heure_formatee = heure_test.strftime('%H:%M')
                              creneaux_virtuels.append({
                                    "id": heure_formatee,
                                    "heure": heure_formatee
                              })

                        temps_actuel += pas

            return Response(creneaux_virtuels)

#-------------------------------------------------la liste des rendez-vous----------------------------------------------------------------------
class ListeRendezVousPatient(generics.ListAPIView):
    serializer_class = RendezVousSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
# On récupère uniquement les RDV du patient connecté
        return RendezVous.objects.filter(patient_demandeur__compte_utilisateur=self.request.user).order_by('date_rdv', 'heure_rdv')


# ------------------------------------------------------ANNULER UN RENDEZ-VOUS --------------------------------------------------

class AnnulerRendezVous(generics.UpdateAPIView):

      queryset = RendezVous.objects.all()
      serializer_class = RendezVousSerializer
      permission_classes = [IsAuthenticated]

      def patch(self, request, *args, **kwargs):
            instance = self.get_object()

# On vérifie que le patient qui annule est bien celui du RDV
            if instance.patient_demandeur.compte_utilisateur != request.user:
                  return Response({"error": "Action non autorisée"}, status=status.HTTP_403_FORBIDDEN)

# On change le statut
            instance.statut_actuel_rdv = "annulé"
            instance.save()

            return Response({
                  "success": True,
                  "message": "Rendez-vous annulé avec succès"
            }, status=status.HTTP_200_OK)


# ------------------------------------------------------LISTE DES ETABLISSEMENTS : Hôpitaux & Pharmacies------------------------------------------------------
class ListeEtablissements(APIView):
      permission_classes = [IsAuthenticated]

      def get(self, request):
            # On peut filtrer par type (pharmacie ou hopital) si besoin
            type_filtre = request.query_params.get('type')
            if type_filtre:
                  etablissements = EtablissementSante.objects.filter(type_etablissement=type_filtre)
            else:
                  etablissements = EtablissementSante.objects.all()

            serializer = EtablissementSanteSerializer(etablissements, many=True)
            return Response(serializer.data)

#-------------------------------------------------RAPPELS TRAITEMENT-----------------------------------------------------------------------------------
class ListeNotifications(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # On récupère les notifications de l'utilisateur 'romaric' (ou celui connecté)
        notifications = Notification.objects.filter(destinataire=request.user).order_by('-heure_envoi')
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data)


# -------------------------------------------------les TRAITEMENT-----------------------------------------------------------------------------------

class ListeTraitementsPatient(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # On récupère le patient lié à l'utilisateur connecté
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            traitements = Traitement.objects.filter(patient_concerne=patient)
            serializer = TraitementSerializer(traitements, many=True)
            return Response(serializer.data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)