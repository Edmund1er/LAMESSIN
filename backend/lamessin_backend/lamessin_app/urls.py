from django.urls import path, include

from .import views

urlpatterns = [
# Route pour la Connexion
    path('login/', views.Login.as_view(), name='login'),

    path('inscription/', views.inscription.as_view(), name='inscription'),

# Route pour le Profil
    path('profil/', views.UserProfil.as_view(), name='user_profil'),

# Routes pour les rdv
    path('listeMedecins/',views.LiteMedecins.as_view(),name='liste_medecins'),
    path('rendezvous/',views.CreezRendezVous.as_view(),name='creer_rendezvous'),
    path('creneauxDisponible/',views.CreneauxDispo.as_view(),name='creneaux_dispo'),

]
