from django.urls import path
from . import views

urlpatterns = [
# ---------------------------------------------------AUTHENTIFICATION------------------------------------------------
    path('login/', views.Login.as_view(), name='login'),
    path('inscription/', views.inscription.as_view(), name='inscription'),
    path('profil/', views.UserProfil.as_view(), name='user_profil'),

# ---------------------------------------------------MODIFICATION DU PROFIL-------------------------------------------
    path('updateProfil/', views.UpdateProfilView.as_view(), name='modification_profil'),

# ---------------------------------------------------MÉDECINS ET DISPONIBILITÉS---------------------------------------
    path('listeMedecins/', views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', views.CreneauxDispo.as_view(), name='creneaux_dispo'),

# ---------------------------------------------------GESTION DES RENDEZ-VOUS------------------------------------------
# la liste des RDV du patient
    path('rendezvous/', views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
# la création d'un RDV
    path('rendezvous/creer/', views.CreezRendezVous.as_view(), name='creer_rendezvous'),
# annulation d'un RDV spécAAAAifique
    path('rendezvous/<int:pk>/', views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

# ---------------------------------------------------SOINS ET CONSULTATIONS-------------------------------------------
# Enregistrer un soin
    path('soins/enregistrer/', views.EnregistrerSoin.as_view(), name='enregistrer_soin'),

# ---------------------------------------------------MÉDICAMENTS------------------------------------------------------
# Recherche de médicaments par nom ou description
    path('medicaments/recherche/', views.RechercheMedicament.as_view(), name='recherche_medicament'),

# ---------------------------------------------------GEOLOCALISATION---------------------------------------------------
    path('etablissements/', views.ListeEtablissements.as_view(), name='liste_etablissements'),

# ---------------------------------------------------NOTIFICATIONS & RAPPELS------------------------------------------
    path('notifications/', views.ListeNotifications.as_view(), name='liste_notifications'),

# ---------------------------------------------------LISTE TRAITEMENTS------------------------------------------------
    path('traitements/', views.ListeTraitementsPatient.as_view(), name='liste_traitements'),

# ----------------------------------------------Gestion des commandes et paiements-----------------------------------------------------------
    path('commandes/creerEtPayer/', views.CreerCommandeEtPayer.as_view(), name='creer_paiement'),
    path('fedapay/webhook/', views.fedapay_webhook, name='fedapay_webhook'),
    path('commandes/<int:commande_id>/genererLien/', views.GenererLienPaiement.as_view(), name='generer_lien'),
]