from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
#utilisons le système d'utilisateur natif (AbstractUser). Cela nous évitera de devoir recoder toute la sécurité (hachage des mots de passe, jetons de connexion,)

from django.contrib.auth.models import AbstractUser

# ==========================================================
# MODULE : INTERFACE UTILISATEURS
# ==========================================================

# AbstractUser contient déjà : username, password, email, first_name, last_name

class Utilisateur(AbstractUser):
    email= models.EmailField(unique=True)
    numero_telephone = models.CharField(max_length=15, unique=True)
    est_un_compte_patient = models.BooleanField(default=False)
    est_un_compte_medecin = models.BooleanField(default=False)
    est_un_compte_pharmacien = models.BooleanField(default=False)

    USERNAME_FIELD = 'numero_telephone'
    REQUIRED_FIELDS = ['username', 'email', 'first_name', 'last_name']

    def __str__(self):
       return f"{self.last_name} - {self.numero_telephone}"

class Patient(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    date_naissance= models.DateField(null=True, blank=True)
    groupe_sanguin= models.CharField(max_length=5, null=True, blank=True)

    def __str__(self):
        return f"Patient: {self.compte_utilisateur.last_name}"

class Medecin(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    specialite_medicale = models.CharField(max_length=100)
    numero_licence = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return f"Dr {self.compte_utilisateur.last_name}"

class Pharmacien(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    numero_licence = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return f"Pharmacien: {self.compte_utilisateur.last_name}"

# ==========================================================
# MODULE : GEOLOCALISATION & ETABLISSEMENTS
# ==========================================================

class EtablissementSante(models.Model):
    nom = models.CharField(max_length=100)
    adresse = models.TextField()
    contact = models.CharField(max_length=20)
    coordonnee_latitude_gps = models.DecimalField(max_digits=9,decimal_places=6,validators=[MinValueValidator(-90),MaxValueValidator(90)])
    coordonnee_longitude_gps = models.DecimalField(max_digits=9,decimal_places=6,validators=[MinValueValidator(-180),MaxValueValidator(180)])
    plage_horaire_ouverture = models.CharField(max_length=100)

    def __str__(self):
        return self.nom

class Hopital(EtablissementSante):
    type_urgences= models.CharField(max_length=100)
    liste_services = models.TextField()

class Pharmacie(EtablissementSante):
    pharmacie_est_garde = models.BooleanField(default=False)

# ==========================================================
# MODULE : PRODUITS & STOCKS
# ==========================================================

class Medicament(models.Model):
    nom_commercial = models.CharField(max_length=100)
    description= models.TextField()
    posologie = models.TextField()
    prix_vente = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return self.nom_commercial

class Stock(models.Model):
    produit_concerne = models.ForeignKey(Medicament, on_delete=models.CASCADE)
    pharmacie_detentrice = models.ForeignKey(Pharmacie, on_delete=models.CASCADE)
    quantite_actuelle_en_stock = models.PositiveIntegerField()
    seuil_alerte= models.PositiveIntegerField()
    date_peremption = models.DateField()

    def __str__(self):
        return f"{self.produit_concerne.nom_commercial} ({self.quantite_actuelle_en_stock})"

class Ordonnance(models.Model):
    medecin_prescripteur = models.ForeignKey(Medecin, on_delete=models.CASCADE)
    patient_beneficiaire = models.ForeignKey(Patient, on_delete=models.CASCADE)
    date_prescription= models.DateField(auto_now_add=True)
    liste_medicaments_prescrits = models.ManyToManyField(Medicament)

    def __str__(self):
        return f"Ordonnance de {self.patient_beneficiaire.compte_utilisateur.last_name}"

# ==========================================================
# MODULE : GESTION DES RENDEZ-VOUS
# ==========================================================

class Agenda(models.Model):
    medecin_proprietaire = models.OneToOneField(Medecin, on_delete=models.CASCADE)

    def __str__(self):
        return f"Agenda du Dr {self.medecin_proprietaire.compte_utilisateur.last_name}"

class Creneau(models.Model):
    agenda = models.ForeignKey(Agenda, on_delete=models.CASCADE)
    date_debut_creneau = models.DateTimeField()
    date_fin_creneau = models.DateTimeField()
    est_libre = models.BooleanField(default=True)

    def __str__(self):
        return f"Creneau du {self.date_debut_creneau}"

class RendezVous(models.Model):
    patient_demandeur = models.ForeignKey(Patient, on_delete=models.CASCADE)
    medecin_concerne = models.ForeignKey(Medecin, on_delete=models.CASCADE)
    creneau_reserve = models.OneToOneField(Creneau, on_delete=models.CASCADE)
    motif_consultation = models.CharField(max_length=255)
    statut_actuel_rdv = models.CharField(max_length=50, default='en_attente')

    def __str__(self):
        return f"RDV: {self.patient_demandeur.compte_utilisateur.last_name}"

# ==========================================================
# MODULE : COMMANDES & PAIEMENTS
# ==========================================================

class Commande(models.Model):
    patient_acheteur = models.ForeignKey(Patient, on_delete=models.CASCADE)
    date = models.DateTimeField(auto_now_add=True)
    statut_commande = models.CharField(max_length=50)
    methode_retrait = models.CharField(max_length=50)

    def __str__(self):
        return f"Commande {self.id}"

class LigneCommande(models.Model):
    ma_commande = models.ForeignKey(Commande, on_delete=models.CASCADE, related_name="lignes")
    medicament_ajoute = models.ForeignKey(Medicament, on_delete=models.CASCADE)
    quantite_commandee = models.PositiveIntegerField()
    prix_unitaire = models.FloatField()

class Paiement(models.Model):
    commande_associee = models.OneToOneField(Commande, on_delete=models.CASCADE)
    montant_total = models.FloatField()
    moyen_de_paiement = models.CharField(max_length=50)


    identifiant_transaction_mobile = models.CharField(max_length=100, unique=True)



    confirmation_paiement = models.BooleanField(default=False)

    def __str__(self):
        return f"Paiement {self.identifiant_transaction_mobile}"

# ==========================================================
# MODULE : SUIVI DE SANTÉ
# ==========================================================

class Traitement(models.Model):
    patient_concerne = models.ForeignKey(Patient, on_delete=models.CASCADE)
    nom_du_traitement = models.CharField(max_length=100)
    date_debut_traitement = models.DateField()
    date_fin_traitement = models.DateField()

    def __str__(self):
        return f"Traitement: {self.nom_du_traitement}"

class PriseMedicament(models.Model):
    traitement= models.ForeignKey(Traitement, on_delete=models.CASCADE)
    heure_prise_prevue = models.TimeField()
    prise_effectuee = models.BooleanField(default=False)
    date_prise_reelle = models.DateField()

class Notification(models.Model):
    destinataire = models.ForeignKey(Utilisateur, on_delete=models.CASCADE)
    message = models.TextField()
    heure_envoi = models.DateTimeField(auto_now_add=True)
    type_notification = models.CharField(max_length=50)

# ==========================================================
# MODULE : ASSISTANCE VIRTUELLE
# ==========================================================

class Chatbot(models.Model):
    date_ouverture_session = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Session Chat {self.id}"

class Message(models.Model):
    chatbot_associe = models.ForeignKey(Chatbot, on_delete=models.CASCADE, related_name="messages")
    contenu_texte = models.TextField()
    envoye_par_utilisateur = models.BooleanField()
    heure_message = models.DateTimeField(auto_now_add=True)