from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

# ====================================================================================================
# IMPORTS MODULAIRES
# ====================================================================================================
from .views import patient_views,doctor_views, main_views

urlpatterns = [
# ====================================================================================================
# AUTHENTIFICATION & SESSION (SÉCURITÉ)
# ====================================================================================================
# Connexion initiale (Retourne Access + Refresh)

    path('login/', main_views.Login.as_view(), name='token_obtain_pair'),

# Rafraîchissement de session (Crucial pour le côté "Permanent" sur Flutter)
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

# Inscription avec connexion auto
    path('inscription/', main_views.InscriptionView.as_view(), name='inscription'),

# Déconnexion (Blacklist du refresh token)
    path('logout/', main_views.LogoutView.as_view(), name='logout'),

# ====================================================================================================
# PROFIL UTILISATEUR
# ====================================================================================================

    path('profil/', main_views.UserProfil.as_view(), name='user_profil'),
    path('updateProfil/', main_views.UpdateProfilView.as_view(), name='modification_profil'),

# ====================================================================================================
# MÉDECINS, DISPONIBILITÉS & RENDEZ-VOUS (PATIENT)
# ====================================================================================================

    path('listeMedecins/', patient_views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', patient_views.CreneauxDispo.as_view(), name='creneaux_dispo'),

    path('rendezvous/', patient_views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
    path('rendezvous/creer/', patient_views.CreezRendezVous.as_view(), name='creer_rendezvous'),
    path('rendezvous/<int:pk>/', patient_views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

# ====================================================================================================
# SOINS, MÉDICAMENTS & ÉTABLISSEMENTS
# ====================================================================================================

    # Action Médecin : déplacée vers doctor_views
    path('soins/enregistrer/', doctor_views.EnregistrerSoin.as_view(), name='enregistrer_soin'),

    # Actions Patient
    path('medicaments/recherche/', patient_views.RechercheMedicament.as_view(), name='recherche_medicament'),
    path('etablissements/', patient_views.ListeEtablissements.as_view(), name='liste_etablissements'),

# ====================================================================================================
# TRAITEMENTS, PRISES & ORDONNANCES (CÔTÉ PATIENT)
# ====================================================================================================

    path('traitements/', patient_views.ListeTraitementsPatient.as_view(), name='liste_traitements'),
    path('traitements/<int:pk>/', patient_views.DetailTraitement.as_view(), name='detail_traitement'),
    path('traitements/valider-prise/<int:prise_id>/', patient_views.ValiderPriseMedicament.as_view(), name='valider_prise'),
    path('ordonnances/', patient_views.ListeOrdonnancesPatient.as_view(), name='liste_ordonnances'),

# Upload de documents (Action Médecin)
    path('documents/upload/', doctor_views.UploadDocumentMedicalView.as_view(), name='upload_document'),

# ====================================================================================================
# COMMANDES & PAIEMENTS (PATIENT)
# ====================================================================================================
# Liste des commandes du patient

    path('commandes/', patient_views.MesCommandesView.as_view(), name='mes_commandes'),

# Création de commande multiple + Génération automatique du lien FedaPay

   path('commandes/creerEtPayer/', patient_views.CreerCommandeMultiple.as_view(), name='creer_paiement'),

# Relance de paiement pour une commande en attente

    path('commandes/<int:commande_id>/genererLien/', patient_views.GenererLienPaiement.as_view(), name='generer_lien'),

# Webhook cinetpay

    path('cinetpay/webhook/', patient_views.cinetpay_webhook, name='cinetpay_webhook'),

# ====================================================================================================
# NOTIFICATIONS & FCM (FIREBASE) (COMMUN)
# ====================================================================================================

    path('notifications/', main_views.ListeNotifications.as_view(), name='liste_notifications'),
    path('notifications/enregistrerToken/', main_views.EnregistrerFCMToken.as_view(), name='enregistrer_token'),

# ====================================================================================================
# ASSISTANT VIRTUEL (IA GEMINI) (PATIENT)
# ====================================================================================================

    path('assistant/chat/', patient_views.assistant, name='assistant_gemini'),
    path('assistant/historique/', patient_views.AssistantHistoriqueView.as_view(), name='assistant_historique'),
]