from django.db import models

from django.contrib.auth.models import AbstractUser
#utilisons le système d'utilisateur natif (AbstractUser). Cela nous évitera de devoir recoder toute la sécurité (hachage des mots de passe, jetons de connexion,)

class Utilisateur(AbstractUser):
# AbstractUser contient déjà : username, password, email, first_name, last_name
    telephone = models.CharField(max_length=15, unique=True)
    est_patient = models.BooleanField(default=False)
    est_medecin = models.BooleanField(default=False)
    est_pharmacien = models.BooleanField(default=False)

# On utilise le téléphone pour se connecter au lieu du nom d'utilisateur
    USERNAME_FIELD = 'telephone'
    REQUIRED_FIELDS = ['username', 'email']

class Patient(models.Model):
    user = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    date_naissance = models.DateField(null=True)
    genre = models.CharField(max_length=10, null=True) # Pour la Page 6 de ta maquette

class Medecin(models.Model):
    user = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    specialite = models.CharField(max_length=50)
    adresse = models.CharField(max_length=200)



class Pharmacien(Utilisateur):
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
