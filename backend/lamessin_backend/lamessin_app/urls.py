from django.urls import path, include

from .import views

urlpatterns = [
# Route pour le Connexion
      path('login/', views.Login.as_view(), name='login'),

    path('inscription/', views.inscription.as_view(), name='inscription'),

# Route pour le Profil é
      path('profil/', views.UserProfil.as_view(), name='user_profil'),
]

