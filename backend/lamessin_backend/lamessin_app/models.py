from django.db import models

class Utilisateur(models.Model):
    nom = models.CharField(max_length=50)
    prenom = models.CharField(max_length=50)
    email = models.EmailField()
    motDePasse = models.CharField(max_length=100)

class Patient(Utilisateur):  # Héritage ← MCD
    pass  # Champs spécifiques si besoin

class Pharmacien(Utilisateur):
    adresse = models.CharField(max_length=200)

class Medecin(Utilisateur):
    specialite = models.CharField(max_length=50)
    adresse = models.CharField(max_length=200)


class Medicament(models.Model):
    idMedicament = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100)
    description = models.TextField()
    prixUnitaire = models.FloatField()

    def __str__(self):
        return self.nom

class RendezVous(models.Model):
    idRendezVous = models.AutoField(primary_key=True)
    date = models.DateTimeField()
    statut = models.CharField(max_length=20)
    lieu = models.CharField(max_length=100)
    idPatient = models.ForeignKey(Patient, on_delete=models.CASCADE)

class Commande(models.Model):
    idCommande = models.AutoField(primary_key=True)
    statut = models.CharField(max_length=20)
    montantTotal = models.FloatField()
    idPatient = models.ForeignKey(Patient, on_delete=models.CASCADE)

class Stock(models.Model):
    idStock = models.AutoField(primary_key=True)
    quantiteActuelle = models.IntegerField()
    seuilAlerte = models.IntegerField()
    idPharmacien = models.ForeignKey(Pharmacien, on_delete=models.CASCADE)
    idMedicament = models.ForeignKey(Medicament, on_delete=models.CASCADE)

class Ordonnance(models.Model):
    idOrdonnance = models.AutoField(primary_key=True)
    destination = models.CharField(max_length=100)
    contenu = models.TextField()
    idMedecin = models.ForeignKey(Medecin, on_delete=models.CASCADE)

class Paiement(models.Model):
    refPaiement = models.AutoField(primary_key=True)
    statut = models.CharField(max_length=20)
    montant = models.FloatField()
    datePaiement = models.DateTimeField()
    idCommande = models.ForeignKey(Commande, on_delete=models.CASCADE)

class Notification(models.Model):
    idNotification = models.AutoField(primary_key=True)
    destination = models.CharField(max_length=100)
    message = models.TextField()
    idPatient = models.ForeignKey(Patient, on_delete=models.CASCADE)
