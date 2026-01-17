from django.db import models
from django.core.validators import MinValueValidator

# Hopitaux (doit être avant Medecin)
class Hopitaux(models.Model):
    Nom = models.CharField(max_length=50)
    Addresse = models.CharField(max_length=100)
    Telephone = models.CharField(max_length=20)
    Est_de_garde = models.BooleanField(default=False)
    Services_disponibles = models.CharField(max_length=200)

# Utilisateur de base
class Utilisateurs(models.Model):
    Nom = models.CharField(max_length=50)
    Prenom = models.CharField(max_length=50)
    Email = models.EmailField(unique=True)
    Mot_de_passe = models.CharField(max_length=128)

# Medecin
class Medecin(Utilisateurs):
    Addresse = models.CharField(max_length=100)
    Specialite = models.CharField(max_length=50)
    Hopitaux = models.ForeignKey(Hopitaux, on_delete=models.CASCADE)

# Patient
class Patient(Utilisateurs):
    pass

# Ordonnance (doit venir avant Medicament)
class Ordonnance(models.Model):
    Destinataire = models.CharField(max_length=30)
    Contenu = models.CharField(max_length=150)
    Prix = models.IntegerField(validators=[MinValueValidator(1)])
    Medecin = models.ForeignKey(Medecin, on_delete=models.CASCADE)

# Medicament
class Medicament(models.Model):
    Nom = models.CharField(max_length=50)
    Description = models.TextField()
    Prix_unitaire = models.FloatField()
    Ordonnance = models.ForeignKey(Ordonnance, on_delete=models.CASCADE)

# Pharmacie
class Pharmacie(models.Model):
    Nom = models.CharField(max_length=50)
    Addresse = models.CharField(max_length=100)
    Telephone = models.CharField(max_length=20)
    Est_de_garde = models.BooleanField(default=False)

# Pharmacien
class Pharmacien(Utilisateurs):
    Addresse = models.CharField(max_length=100)
    Pharmacie = models.ForeignKey(Pharmacie, on_delete=models.CASCADE)

# Stock
class Stock(models.Model):
    Quantite_actuelle = models.IntegerField()
    Seuille_alerte = models.IntegerField()
    Pharmacien = models.ForeignKey(Pharmacien, on_delete=models.CASCADE)

# Paiement
class Paiement(models.Model):
    Reference = models.CharField(max_length=50)
    Statut = models.CharField(max_length=20)
    Montant = models.FloatField()
    Date_paiement = models.DateField()

# Commande
class Commande(models.Model):
    Statut = models.CharField(max_length=15)
    Montant_total = models.FloatField()
    Paiement = models.ForeignKey(Paiement, on_delete=models.CASCADE)

# Assistant IA
class Assistant_ia(models.Model):
    Nom_chatbot = models.CharField(max_length=50)
    Version = models.CharField(max_length=20)
    Patient = models.ForeignKey(Patient, on_delete=models.CASCADE)

# Notification
class Notification(models.Model):
    Destination = models.CharField(max_length=50)
    Message = models.CharField(max_length=200)
    Patient = models.ForeignKey(Patient, on_delete=models.CASCADE)

# Geolocalisation
class Geolocalisation(models.Model):
    Latitude = models.CharField(max_length=20)
    Longitude = models.CharField(max_length=20)

# Rendez-vous
class Rendez_vous(models.Model):
    Date = models.DateField()
    Statut = models.CharField(max_length=20)
    Lieu = models.CharField(max_length=100)
    Geolocalisation = models.ForeignKey(Geolocalisation, on_delete=models.CASCADE)
    Patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
