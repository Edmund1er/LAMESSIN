from django.urls import path
from . import views

urlpatterns = [
# ---------------------------------------------------AUTHENTIFICATION------------------------------------------------

    path('login/', views.Login.as_view(), name='login'),
    path('inscription/', views.inscription.as_view(), name='inscription'),
    path('profil/', views.UserProfil.as_view(), name='user_profil'),

# ---------------------------------------------------MÉDECINS ET DISPONIBILITÉS---------------------------------------------------

    path('listeMedecins/', views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', views.CreneauxDispo.as_view(), name='creneaux_dispo'),

# ---------------------------------------------------GESTION DES RENDEZ-VOUS---------------------------------------------------
# la liste des RDV du patient
    path('rendezvous/', views.ListeRendezVousPatient.as_view(), name='liste_rdv'),

# la création d'un RDV
# On ajoute 'creer/' pour éviter le conflit avec la liste
    path('rendezvous/creer/', views.CreezRendezVous.as_view(), name='creer_rendezvous'),

#annulation ou modification d'un RDV spécifique
# l'id est passé dans l'URL pour savoir quel RDV annuler
    path('rendezvous/<int:pk>/', views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

# ---------------------------------------------------GEOLOCALISATION---------------------------------------------------
    path('etablissements/', views.ListeEtablissements.as_view(), name='liste_etablissements'),

# ---------------------------------------------------RAPPEL TRAIEMENT---------------------------------------------------
    path('notifications/', views.ListeNotifications.as_view(),name='liste_notifications'),

# ---------------------------------------------------Listes TRAIEMENT---------------------------------------------------
    path('traitements/', views.ListeTraitementsPatient.as_view(),name='liste_traitements'),
]