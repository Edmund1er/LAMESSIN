from django.urls import path
from . import views
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
# ====================================================================================================
# AUTHENTIFICATION & SESSION (SÉCURITÉ)
# ====================================================================================================
# Connexion initiale (Retourne Access + Refresh)


    path('login/', views.Login.as_view(), name='token_obtain_pair'),

# Rafraîchissement de session (Crucial pour le côté "Permanent" sur Flutter)
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

# Inscription avec connexion auto
    path('inscription/', views.InscriptionView.as_view(), name='inscription'),

# Déconnexion (Blacklist du refresh token)
    path('logout/', views.LogoutView.as_view(), name='logout'),

# ====================================================================================================
# PROFIL UTILISATEUR
# ====================================================================================================

    path('profil/', views.UserProfil.as_view(), name='user_profil'),
    path('updateProfil/', views.UpdateProfilView.as_view(), name='modification_profil'),

# ====================================================================================================
# MÉDECINS, DISPONIBILITÉS & RENDEZ-VOUS
# ====================================================================================================

    path('listeMedecins/', views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', views.CreneauxDispo.as_view(), name='creneaux_dispo'),

    path('rendezvous/', views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
    path('rendezvous/creer/', views.CreezRendezVous.as_view(), name='creer_rendezvous'),
    path('rendezvous/<int:pk>/', views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

# ====================================================================================================
# SOINS, MÉDICAMENTS & ÉTABLISSEMENTS
# ====================================================================================================

    path('soins/enregistrer/', views.EnregistrerSoin.as_view(), name='enregistrer_soin'),
    path('medicaments/recherche/', views.RechercheMedicament.as_view(), name='recherche_medicament'),
    path('etablissements/', views.ListeEtablissements.as_view(), name='liste_etablissements'),

# ====================================================================================================
# TRAITEMENTS, PRISES & ORDONNANCES (CÔTÉ PATIENT)
# ====================================================================================================

    path('traitements/', views.ListeTraitementsPatient.as_view(), name='liste_traitements'),
    path('traitements/<int:pk>/', views.DetailTraitement.as_view(), name='detail_traitement'),
    path('traitements/valider-prise/<int:prise_id>/', views.ValiderPriseMedicament.as_view(), name='valider_prise'),
    path('ordonnances/', views.ListeOrdonnancesPatient.as_view(), name='liste_ordonnances'),

# Upload de documents

    path('documents/upload/', views.UploadDocumentMedicalView.as_view(), name='upload_document'),

# ====================================================================================================
# COMMANDES & PAIEMENTS (FEDAPAY)
# ====================================================================================================
# Liste des commandes du patient

    path('commandes/', views.MesCommandesView.as_view(), name='mes_commandes'),

# Création de commande multiple + Génération automatique du lien FedaPay

   path('commandes/creerEtPayer/', views.CreerCommandeMultiple.as_view(), name='creer_paiement'),

# Relance de paiement pour une commande en attente

    path('commandes/<int:commande_id>/genererLien/', views.GenererLienPaiement.as_view(), name='generer_lien'),

# Webhook cinetpay

    path('cinetpay/webhook/', views.cinetpay_webhook, name='cinetpay_webhook'),

# ====================================================================================================
# NOTIFICATIONS & FCM (FIREBASE)
# ====================================================================================================

    path('notifications/', views.ListeNotifications.as_view(), name='liste_notifications'),
    path('notifications/enregistrerToken/', views.EnregistrerFCMToken.as_view(), name='enregistrer_token'),

# ====================================================================================================
# ASSISTANT VIRTUEL (IA GEMINI)
# ====================================================================================================

    path('assistant/chat/', views.ChatbotGeminiView.as_view(), name='assistant_gemini'),
    path('assistant/historique/', views.AssistantHistoriqueView.as_view(), name='assistant_historique'),
]