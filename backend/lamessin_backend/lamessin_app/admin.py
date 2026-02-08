from django.contrib import admin

# Register your models here.
from .models import Utilisateur, Patient, Medecin, Pharmacien

# On enregistre le modèle Utilisateur pour qu'il apparaisse dans l'admin
admin.site.register(Utilisateur)

# On enregistre les profils spécifiques
admin.site.register(Patient)
admin.site.register(Medecin)
admin.site.register(Pharmacien)