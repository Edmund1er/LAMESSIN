from django.shortcuts import render

from rest_framework import viewsets
from .models import *
from .serializers import UtilisateurSerializer

from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['GET'])
def test_connexion(request):
    return Response({"message": "Bravo Romaric, l'API Django fonctionne !"})