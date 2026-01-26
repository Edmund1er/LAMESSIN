from django.urls import path, include

from .views import *

from django.urls import path

urlpatterns = [
      path('test/', test_connexion, name='test-api'),
]

