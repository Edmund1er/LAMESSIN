from django.urls import path
from . import views
from .views import EnregistrerFCMToken, CreerCommandeMultiple, AssistantHistoriqueView, MesCommandesView

urlpatterns = [
# --------------------------------------------------- AUTHENTIFICATION ------------------------------------------------
    path('login/', views.Login.as_view(), name='token_obtain_pair'),
    path('inscription/', views.inscription.as_view(), name='inscription'),
    path('profil/', views.UserProfil.as_view(), name='user_profil'),
    path('updateProfil/', views.UpdateProfilView.as_view(), name='modification_profil'),

# --------------------------------------------------- MÉDECINS ET DISPONIBILITÉS ---------------------------------------
    path('listeMedecins/', views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', views.CreneauxDispo.as_view(), name='creneaux_dispo'),

# --------------------------------------------------- GESTION DES RENDEZ-VOUS ------------------------------------------
    path('rendezvous/', views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
    path('rendezvous/creer/', views.CreezRendezVous.as_view(), name='creer_rendezvous'),
    path('rendezvous/<int:pk>/', views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

# --------------------------------------------------- SOINS ET CONSULTATIONS -------------------------------------------
    path('soins/enregistrer/', views.EnregistrerSoin.as_view(), name='enregistrer_soin'),

# --------------------------------------------------- MÉDICAMENTS & STOCKS ----------------------------------------------
    path('medicaments/recherche/', views.RechercheMedicament.as_view(), name='recherche_medicament'),

# --------------------------------------------------- GÉOLOCALISATION ---------------------------------------------------
    path('etablissements/', views.ListeEtablissements.as_view(), name='liste_etablissements'),

# --------------------------------------------------- NOTIFICATIONS & FCM ----------------------------------------------
    path('notifications/', views.ListeNotifications.as_view(), name='liste_notifications'),
    path('notifications/enregistrerToken/', EnregistrerFCMToken.as_view(), name='enregistrer_token'),

# --------------------------------------------------- TRAITEMENTS -------------------------------------------------------
    path('traitements/', views.ListeTraitementsPatient.as_view(), name='liste_traitements'),
# --------------------------------------------------- ORDONNANCES ---------------------------------------------------
    path('ordonnances/', views.ListeOrdonnancesPatient.as_view(), name='liste_ordonnances'),
# --------------------------------------------------- SUIVI TRAITEMENT ----------------------------------------------
    path('traitements/<int:pk>/', views.DetailTraitement.as_view(), name='detail_traitement'),
    path('traitements/valider-prise/<int:prise_id>/', views.ValiderPriseMedicament.as_view(), name='valider_prise'),


# ---------------------------------------------- COMMANDES ET PAIEMENTS (FEDAPAY) ---------------------------------------

#--------------------------------------------------Création commande multiple-----------------------------------------------------
    path('commandes/multiple/', CreerCommandeMultiple.as_view(), name='creer_commande_multiple'),

#-------------------------------------------Webhook pour la confirmation automatique (T-Money/Flooz)--------------------------------

    path('fedapay/webhook/', views.fedapay_webhook, name='fedapay_webhook'),

#-----------------------------------------------------Relance de paiement pour une commande existante-----------------------------------------------------

    path('commandes/<int:commande_id>/genererLien/', views.GenererLienPaiement.as_view(), name='generer_lien'),

# -----------------------------------------------------commande simple-----------------------------------------------------
    path('commandes/', MesCommandesView.as_view(), name='mes_commandes'),

    path('commandes/creerEtPayer/', views.CreerCommandeMultiple.as_view(), name='creer_paiement'),

# --------------------------------------------------- ASSISTANT GEMINI ----------------------------------------------
    path('assistant/chat/', views.ChatbotGeminiView.as_view(), name='assistant_gemini'),
    path('assistant/historique/', AssistantHistoriqueView.as_view(), name='assistant_historique'),
]
