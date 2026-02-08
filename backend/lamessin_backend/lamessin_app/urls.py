from django.urls import path, include

from .import views

urlpatterns = [
# Route pour le Connexion
      path('login/', views.Login.as_view(), name='token_obtain_pair'),

# Route pour l'Inscription
      path('register/', views.Inscription.as_view(), name='register'),

# Route pour le Profil é
      path('profile/', views.UserProfil.as_view(), name='user_profile'),
]

