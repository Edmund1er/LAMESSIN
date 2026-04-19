from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth.models import AbstractUser
from django.conf import settings

# ====================================================================================================================
# MODULE : INTERFACE UTILISATEURS
# ====================================================================================================================

class Utilisateur(AbstractUser):
    email = models.EmailField(unique=True)
    numero_telephone = models.CharField(max_length=15, unique=True)
    est_un_compte_patient = models.BooleanField(default=False)
    est_un_compte_medecin = models.BooleanField(default=False)
    est_un_compte_pharmacien = models.BooleanField(default=False)
    fcm_token = models.TextField(null=True, blank=True)

    USERNAME_FIELD = 'numero_telephone'
    REQUIRED_FIELDS = ['username', 'email', 'first_name', 'last_name']

    def __str__(self):
        return f"{self.last_name} - {self.numero_telephone}"

class Patient(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    date_naissance = models.DateField(null=True, blank=True)
    groupe_sanguin = models.CharField(max_length=5, null=True, blank=True)

    photo_profil = models.ImageField(upload_to='profiles/patients/', null=True, blank=True)

    def __str__(self):
        return f"Patient: {self.compte_utilisateur.last_name}"

class Medecin(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    specialite_medicale = models.CharField(max_length=100)
    numero_licence = models.CharField(max_length=50, unique=True)
    photo_profil = models.ImageField(upload_to='profiles/medecins/', null=True, blank=True)

    def __str__(self):
        return f"Dr {self.compte_utilisateur.last_name}"

# ====================================================================================================================
# MODULE : GEOLOCALISATION & ETABLISSEMENTS
# ====================================================================================================================

class EtablissementSante(models.Model):
    nom = models.CharField(max_length=100)
    adresse = models.TextField()
    contact = models.CharField(max_length=20)
    coordonnee_latitude_gps = models.DecimalField(max_digits=9, decimal_places=6, validators=[MinValueValidator(-90), MaxValueValidator(90)])
    coordonnee_longitude_gps = models.DecimalField(max_digits=9, decimal_places=6, validators=[MinValueValidator(-180), MaxValueValidator(180)])
    plage_horaire_ouverture = models.CharField(max_length=100)
    # AJOUT : Image de l'établissement
    image_etablissement = models.ImageField(upload_to='etablissements/', null=True, blank=True)

    def __str__(self):
        return self.nom

class Hopital(EtablissementSante):
    type_urgences = models.CharField(max_length=100)
    liste_services = models.TextField()

class Pharmacie(EtablissementSante):
    pharmacie_est_garde = models.BooleanField(default=False)
    numero_paiement = models.CharField(max_length=15, help_text="Numéro T-Money ou Flooz de la pharmacie")
    reseau_paiement = models.CharField(max_length=10, choices=[('tmoney', 'T-Money'), ('flooz', 'Flooz')], default='tmoney')

class Pharmacien(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True)
    numero_licence = models.CharField(max_length=50, unique=True)
    pharmacie = models.OneToOneField(Pharmacie, on_delete=models.CASCADE, null=True, blank=True)
    def __str__(self):
        return f"Pharmacien: {self.compte_utilisateur.last_name}"

# ====================================================================================================================
# MODULE : PRODUITS & STOCKS
# ====================================================================================================================

class Medicament(models.Model):
    nom_commercial = models.CharField(max_length=100, db_index=True)
    description = models.TextField()
    posologie_standard = models.TextField()
    prix_vente = models.DecimalField(max_digits=10, decimal_places=2)
    # AJOUT : Image du produit
    image_produit = models.ImageField(upload_to='medicaments/', null=True, blank=True)

    class Meta:
        verbose_name = "Médicament"
        ordering = ['nom_commercial']

    def __str__(self):
        return self.nom_commercial

class Stock(models.Model):
    produit_concerne = models.ForeignKey(Medicament, on_delete=models.CASCADE)
    pharmacie_detentrice = models.ForeignKey(Pharmacie, on_delete=models.CASCADE)
    quantite_actuelle_en_stock = models.PositiveIntegerField()
    seuil_alerte = models.PositiveIntegerField()
    date_peremption = models.DateField()

    def __str__(self):
        return f"{self.produit_concerne.nom_commercial} ({self.quantite_actuelle_en_stock}) chez {self.pharmacie_detentrice.nom}"

# ====================================================================================================================
# MODULE : RENDEZ-VOUS & CONSULTATIONS (GESTION DOCUMENTS)
# ====================================================================================================================

class PlageHoraire(models.Model):
    medecin = models.ForeignKey(Medecin, on_delete=models.CASCADE, related_name="plages")
    date = models.DateField()
    heure_debut = models.TimeField()
    heure_fin = models.TimeField()
    duree_consultation = models.PositiveIntegerField(default=60)

class RendezVous(models.Model):
    patient_demandeur = models.ForeignKey(Patient, on_delete=models.CASCADE)
    medecin_concerne = models.ForeignKey(Medecin, on_delete=models.CASCADE)
    date_rdv = models.DateField()
    heure_rdv = models.TimeField()
    motif_consultation = models.CharField(max_length=255)
    statut_actuel_rdv = models.CharField(max_length=50, default='en_attente')

    class Meta:
        unique_together = ('medecin_concerne', 'date_rdv', 'heure_rdv')
        ordering = ['-date_rdv', '-heure_rdv']

class Consultation(models.Model):
    rdv = models.OneToOneField(RendezVous, on_delete=models.CASCADE, related_name="consultation")
    diagnostic = models.TextField()
    actes_effectues = models.TextField()
    notes_medecin = models.TextField(blank=True, null=True)
    date_consultation = models.DateTimeField(auto_now_add=True)
    # AJOUT : Document médical attaché (Analyse, compte-rendu PDF, etc.)
    document_joint = models.FileField(upload_to='consultations/documents/', null=True, blank=True)

class Ordonnance(models.Model):
    consultation = models.ForeignKey(Consultation, on_delete=models.SET_NULL, null=True, blank=True)
    medecin_prescripteur = models.ForeignKey(Medecin, on_delete=models.CASCADE)
    patient_beneficiaire = models.ForeignKey(Patient, on_delete=models.CASCADE)
    date_prescription = models.DateField(auto_now_add=True)
    code_securite = models.CharField(max_length=15, unique=True, null=True)
    # AJOUT : Version PDF ou scan de l'ordonnance
    fichier_ordonnance = models.FileField(upload_to='ordonnances/pdf/', null=True, blank=True)

class DetailOrdonnance(models.Model):
    ordonnance = models.ForeignKey(Ordonnance, on_delete=models.CASCADE, related_name="lignes")
    medicament = models.ForeignKey(Medicament, on_delete=models.CASCADE)
    quantite_boites = models.PositiveIntegerField(default=1)
    posologie_specifique = models.TextField()
    duree_traitement_jours = models.PositiveIntegerField()

# ====================================================================================================================
# MODULE : TRAITEMENTS, COMMANDES & NOTIFS
# ====================================================================================================================

class Traitement(models.Model):
    patient_concerne = models.ForeignKey(Patient, on_delete=models.CASCADE)
    nom_du_traitement = models.CharField(max_length=100)
    date_debut_traitement = models.DateField()
    date_fin_traitement = models.DateField()
    ordonnance_origine = models.ForeignKey(Ordonnance, on_delete=models.SET_NULL, null=True, blank=True)

class PriseMedicament(models.Model):
    traitement = models.ForeignKey(Traitement, on_delete=models.CASCADE)
    heure_prise_prevue = models.TimeField()
    prise_effectuee = models.BooleanField(default=False)
    date_prise_reelle = models.DateField()


class Commande(models.Model):
    STATUTS = [
        ('EN_ATTENTE', 'En attente'),
        ('PAYE', 'Payé'),
        ('ANNULE', 'Annulé'),
        ('LIVRE', 'Livré'),
    ]
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name="mes_commandes")
    date_creation = models.DateTimeField(auto_now_add=True)
    statut = models.CharField(max_length=20, choices=STATUTS, default='EN_ATTENTE')
    methode_retrait = models.CharField(max_length=50, default="RETRAIT") # Retrait ou Livraison
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    transaction_id = models.CharField(max_length=100, blank=True, null=True) # ID FedaPay

    def __str__(self):
        return f"Commande {self.id} - {self.patient.compte_utilisateur.last_name}"

class LigneCommande(models.Model):
    commande = models.ForeignKey(Commande, related_name='lignes', on_delete=models.CASCADE)
    produit = models.ForeignKey(Medicament, on_delete=models.CASCADE)
    pharmacie = models.ForeignKey(Pharmacie, on_delete=models.CASCADE)
    quantite = models.PositiveIntegerField()
    prix_unitaire = models.DecimalField(max_digits=10, decimal_places=2)

    def save(self, *args, **kwargs):
        # On récupère le prix actuel du médicament si non précisé
        if not self.prix_unitaire:
            self.prix_unitaire = self.produit.prix_vente
        super().save(*args, **kwargs)


class Paiement(models.Model):
    commande_associee = models.OneToOneField(Commande, on_delete=models.CASCADE)
    montant_total = models.FloatField()
    moyen_de_paiement = models.CharField(max_length=50)
    identifiant_transaction_mobile = models.CharField(max_length=100, unique=True)
    confirmation_paiement = models.BooleanField(default=False)

class Notification(models.Model):
    destinataire = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name="mes_notifications")
    message = models.TextField()
    heure_envoi = models.DateTimeField(auto_now_add=True)
    type_notification = models.CharField(max_length=50)
    lu = models.BooleanField(default=False)

    class Meta:
        ordering = ['-heure_envoi']

class Chatbot(models.Model):
    utilisateur = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="session_assistant", null=True)
    date_ouverture_session = models.DateTimeField(auto_now_add=True)

class Message(models.Model):
    chatbot_associe = models.ForeignKey(Chatbot, on_delete=models.CASCADE, related_name="messages")
    contenu_texte = models.TextField()
    envoye_par_utilisateur = models.BooleanField()
    heure_message = models.DateTimeField(auto_now_add=True)