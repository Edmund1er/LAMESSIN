
from django.contrib import admin
from .models import (
    Utilisateur, Patient, Medecin, Pharmacien,
    EtablissementSante, Hopital, Pharmacie,
    Medicament, Stock, PlageHoraire, RendezVous,
    Consultation, Ordonnance, DetailOrdonnance,
    Commande, LigneCommande, Paiement, Notification, Traitement
)

# Enregistrement simple de tous les modèles
admin.site.register(Utilisateur)
admin.site.register(Patient)
admin.site.register(Medecin)
admin.site.register(Pharmacien)
admin.site.register(Hopital)
admin.site.register(Pharmacie)
admin.site.register(Medicament)
admin.site.register(Stock)
admin.site.register(PlageHoraire)
admin.site.register(RendezVous)
admin.site.register(Consultation)
admin.site.register(Ordonnance)
admin.site.register(DetailOrdonnance)
admin.site.register(Commande)
admin.site.register(LigneCommande)
admin.site.register(Paiement)
admin.site.register(Notification)
admin.site.register(Traitement)