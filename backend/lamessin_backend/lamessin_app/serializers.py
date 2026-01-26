from rest_framework import serializers
from .models import Utilisateur

class UtilisateurSerializer(serializers.ModelSerializer): # Correct
    class Meta:
        model = Utilisateur
        fields = '__all__'