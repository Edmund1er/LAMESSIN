from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth.models import AbstractUser
from django.conf import settings

# ====================================================================================================================
# MODULE : INTERFACE UTILISATEURS
# ====================================================================================================================

class Utilisateur(AbstractUser):
    email = models.EmailField(unique=True, verbose_name="Adresse email")
    numero_telephone = models.CharField(max_length=15, unique=True, verbose_name="Numéro de téléphone")
    est_un_compte_patient = models.BooleanField(default=False, verbose_name="Compte patient")
    est_un_compte_medecin = models.BooleanField(default=False, verbose_name="Compte médecin")
    est_un_compte_pharmacien = models.BooleanField(default=False, verbose_name="Compte pharmacien")
    fcm_token = models.TextField(null=True, blank=True, verbose_name="Token FCM")

    USERNAME_FIELD = 'numero_telephone'
    REQUIRED_FIELDS = ['username', 'email', 'first_name', 'last_name']

    class Meta:
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"
        ordering = ['last_name', 'first_name']

    def __str__(self):
        return f"{self.last_name} {self.first_name} ({self.numero_telephone})"


class Patient(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True, verbose_name="Compte utilisateur")
    date_naissance = models.DateField(null=True, blank=True, verbose_name="Date de naissance")
    groupe_sanguin = models.CharField(max_length=5, null=True, blank=True, verbose_name="Groupe sanguin")
    photo_profil = models.ImageField(upload_to='profiles/patients/', null=True, blank=True, verbose_name="Photo de profil")

    class Meta:
        verbose_name = "Patient"
        verbose_name_plural = "Patients"
        ordering = ['compte_utilisateur__last_name']

    def __str__(self):
        return f"{self.compte_utilisateur.last_name} {self.compte_utilisateur.first_name}"


class Medecin(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True, verbose_name="Compte utilisateur")
    specialite_medicale = models.CharField(max_length=100, verbose_name="Spécialité médicale")
    numero_licence = models.CharField(max_length=50, unique=True, verbose_name="Numéro de licence")
    photo_profil = models.ImageField(upload_to='profiles/medecins/', null=True, blank=True, verbose_name="Photo de profil")

    class Meta:
        verbose_name = "Médecin"
        verbose_name_plural = "Médecins"
        ordering = ['compte_utilisateur__last_name']

    def __str__(self):
        return f"Dr {self.compte_utilisateur.last_name} {self.compte_utilisateur.first_name}"


# ====================================================================================================================
# MODULE : GEOLOCALISATION & ETABLISSEMENTS
# ====================================================================================================================

class EtablissementSante(models.Model):
    nom = models.CharField(max_length=100, verbose_name="Nom")
    adresse = models.TextField(verbose_name="Adresse")
    contact = models.CharField(max_length=20, verbose_name="Contact")
    coordonnee_latitude_gps = models.DecimalField(
        max_digits=9, decimal_places=6,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
        verbose_name="Latitude GPS"
    )
    coordonnee_longitude_gps = models.DecimalField(
        max_digits=9, decimal_places=6,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
        verbose_name="Longitude GPS"
    )
    plage_horaire_ouverture = models.CharField(max_length=100, verbose_name="Plage horaire")
    image_etablissement = models.ImageField(upload_to='etablissements/', null=True, blank=True, verbose_name="Image")

    class Meta:
        verbose_name = "Établissement de santé"
        verbose_name_plural = "Établissements de santé"
        abstract = True


class Hopital(EtablissementSante):
    type_urgences = models.CharField(max_length=100, verbose_name="Type d'urgences")
    liste_services = models.TextField(verbose_name="Liste des services")

    class Meta:
        verbose_name = "Hôpital"
        verbose_name_plural = "Hôpitaux"
        ordering = ['nom']

    def __str__(self):
        return f"Hôpital {self.nom}"


class Pharmacie(EtablissementSante):
    pharmacie_est_garde = models.BooleanField(default=False, verbose_name="Pharmacie de garde")
    numero_paiement = models.CharField(max_length=15, verbose_name="Numéro de paiement",
                                       help_text="Numéro T-Money ou Flooz de la pharmacie")
    reseau_paiement = models.CharField(
        max_length=10,
        choices=[('tmoney', 'T-Money'), ('flooz', 'Flooz')],
        default='tmoney',
        verbose_name="Réseau de paiement"
    )

    class Meta:
        verbose_name = "Pharmacie"
        verbose_name_plural = "Pharmacies"
        ordering = ['nom']

    def __str__(self):
        return f"Pharmacie {self.nom}"


class Pharmacien(models.Model):
    compte_utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE, primary_key=True, verbose_name="Compte utilisateur")
    numero_licence = models.CharField(max_length=50, unique=True, verbose_name="Numéro de licence")
    pharmacie = models.ForeignKey(Pharmacie, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Pharmacie")

    class Meta:
        verbose_name = "Pharmacien"
        verbose_name_plural = "Pharmaciens"
        ordering = ['compte_utilisateur__last_name']

    def __str__(self):
        return f"Pharmacien {self.compte_utilisateur.last_name}"


# ====================================================================================================================
# MODULE : PRODUITS & STOCKS
# ====================================================================================================================

class Medicament(models.Model):
    nom_commercial = models.CharField(max_length=100, db_index=True, verbose_name="Nom commercial")
    description = models.TextField(verbose_name="Description")
    posologie_standard = models.TextField(verbose_name="Posologie standard")
    prix_vente = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix de vente")
    image_produit = models.ImageField(upload_to='medicaments/', null=True, blank=True, verbose_name="Image du produit")

    class Meta:
        verbose_name = "Médicament"
        verbose_name_plural = "Médicaments"
        ordering = ['nom_commercial']

    def __str__(self):
        return f"{self.nom_commercial} - {self.prix_vente} CFA"


class Stock(models.Model):
    produit_concerne = models.ForeignKey(Medicament, on_delete=models.CASCADE, verbose_name="Produit")
    pharmacie_detentrice = models.ForeignKey(Pharmacie, on_delete=models.CASCADE, verbose_name="Pharmacie")
    quantite_actuelle_en_stock = models.PositiveIntegerField(verbose_name="Quantité en stock")
    seuil_alerte = models.PositiveIntegerField(default=10, verbose_name="Seuil d'alerte")
    date_peremption = models.DateField(verbose_name="Date de péremption")

    class Meta:
        verbose_name = "Stock"
        verbose_name_plural = "Stocks"
        ordering = ['-date_peremption']

    def __str__(self):
        return f"{self.produit_concerne.nom_commercial} : {self.quantite_actuelle_en_stock} unités"


# ====================================================================================================================
# MODULE : RENDEZ-VOUS & CONSULTATIONS (GESTION DOCUMENTS)
# ====================================================================================================================

class PlageHoraire(models.Model):
    medecin = models.ForeignKey(Medecin, on_delete=models.CASCADE, related_name="plages", verbose_name="Médecin")
    date = models.DateField(verbose_name="Date")
    heure_debut = models.TimeField(verbose_name="Heure début")
    heure_fin = models.TimeField(verbose_name="Heure fin")
    duree_consultation = models.PositiveIntegerField(default=60, verbose_name="Durée consultation (min)")

    class Meta:
        verbose_name = "Plage horaire"
        verbose_name_plural = "Plages horaires"
        ordering = ['-date', 'heure_debut']

    def __str__(self):
        return f"{self.medecin} - {self.date} ({self.heure_debut} à {self.heure_fin})"


class RendezVous(models.Model):
    STATUTS_RDV = [
        ('en_attente', 'En attente'),
        ('confirme', 'Confirmé'),
        ('annule', 'Annulé'),
        ('termine', 'Terminé'),
        ('expire', 'Expiré'),
    ]

    patient_demandeur = models.ForeignKey(Patient, on_delete=models.CASCADE, verbose_name="Patient")
    medecin_concerne = models.ForeignKey(Medecin, on_delete=models.CASCADE, verbose_name="Médecin")
    date_rdv = models.DateField(verbose_name="Date du rendez-vous")
    heure_rdv = models.TimeField(verbose_name="Heure du rendez-vous")
    motif_consultation = models.CharField(max_length=255, verbose_name="Motif")
    statut_actuel_rdv = models.CharField(max_length=50, choices=STATUTS_RDV, default='en_attente', verbose_name="Statut")

    class Meta:
        verbose_name = "Rendez-vous"
        verbose_name_plural = "Rendez-vous"
        unique_together = ('medecin_concerne', 'date_rdv', 'heure_rdv')
        ordering = ['-date_rdv', '-heure_rdv']

    def __str__(self):
        return f"RDV {self.patient_demandeur} - Dr {self.medecin_concerne} ({self.date_rdv})"


class Consultation(models.Model):
    rdv = models.OneToOneField(RendezVous, on_delete=models.CASCADE, related_name="consultation", verbose_name="Rendez-vous")
    diagnostic = models.TextField(verbose_name="Diagnostic")
    actes_effectues = models.TextField(verbose_name="Actes effectués")
    notes_medecin = models.TextField(blank=True, null=True, verbose_name="Notes du médecin")
    date_consultation = models.DateTimeField(auto_now_add=True, verbose_name="Date consultation")
    document_joint = models.FileField(upload_to='consultations/documents/', null=True, blank=True, verbose_name="Document joint")

    class Meta:
        verbose_name = "Consultation"
        verbose_name_plural = "Consultations"
        ordering = ['-date_consultation']

    def __str__(self):
        return f"Consultation du {self.date_consultation} - {self.rdv.patient_demandeur}"


class Ordonnance(models.Model):
    consultation = models.ForeignKey(Consultation, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Consultation")
    medecin_prescripteur = models.ForeignKey(Medecin, on_delete=models.CASCADE, verbose_name="Médecin prescripteur")
    patient_beneficiaire = models.ForeignKey(Patient, on_delete=models.CASCADE, verbose_name="Patient")
    date_prescription = models.DateField(auto_now_add=True, verbose_name="Date de prescription")
    code_securite = models.CharField(max_length=15, unique=True, null=True, verbose_name="Code de sécurité")
    fichier_ordonnance = models.FileField(upload_to='ordonnances/pdf/', null=True, blank=True, verbose_name="Fichier PDF")

    class Meta:
        verbose_name = "Ordonnance"
        verbose_name_plural = "Ordonnances"
        ordering = ['-date_prescription']

    def __str__(self):
        return f"Ordonnance #{self.id} - {self.patient_beneficiaire}"


class DetailOrdonnance(models.Model):
    ordonnance = models.ForeignKey(Ordonnance, on_delete=models.CASCADE, related_name="lignes", verbose_name="Ordonnance")
    medicament = models.ForeignKey(Medicament, on_delete=models.CASCADE, verbose_name="Médicament")
    quantite_boites = models.PositiveIntegerField(default=1, verbose_name="Nombre de boîtes")
    posologie_specifique = models.TextField(verbose_name="Posologie spécifique")
    duree_traitement_jours = models.PositiveIntegerField(verbose_name="Durée (jours)")

    class Meta:
        verbose_name = "Détail ordonnance"
        verbose_name_plural = "Détails ordonnances"

    def __str__(self):
        return f"{self.medicament.nom_commercial} x{self.quantite_boites}"


# ====================================================================================================================
# MODULE : TRAITEMENTS, COMMANDES & NOTIFS
# ====================================================================================================================

class Traitement(models.Model):
    patient_concerne = models.ForeignKey(Patient, on_delete=models.CASCADE, verbose_name="Patient")
    nom_du_traitement = models.CharField(max_length=100, verbose_name="Nom du traitement")
    date_debut_traitement = models.DateField(verbose_name="Date début")
    date_fin_traitement = models.DateField(verbose_name="Date fin")
    ordonnance_origine = models.ForeignKey(Ordonnance, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Ordonnance d'origine")

    class Meta:
        verbose_name = "Traitement"
        verbose_name_plural = "Traitements"
        ordering = ['-date_debut_traitement']

    def __str__(self):
        return f"{self.nom_du_traitement} - {self.patient_concerne}"


class PriseMedicament(models.Model):
    traitement = models.ForeignKey(Traitement, on_delete=models.CASCADE, verbose_name="Traitement")
    heure_prise_prevue = models.TimeField(verbose_name="Heure prévue")
    prise_effectuee = models.BooleanField(default=False, verbose_name="Prise effectuée")
    date_prise_reelle = models.DateField(verbose_name="Date réelle")

    class Meta:
        verbose_name = "Prise de médicament"
        verbose_name_plural = "Prises de médicaments"

    def __str__(self):
        return f"Prise {self.heure_prise_prevue} - {self.traitement.nom_du_traitement}"


class Commande(models.Model):
    STATUTS = [
        ('EN_ATTENTE', 'En attente'),
        ('PAYE', 'Payé'),
        ('ANNULE', 'Annulé'),
        ('LIVRE', 'Livré'),
    ]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name="mes_commandes", verbose_name="Patient")
    date_creation = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")
    statut = models.CharField(max_length=20, choices=STATUTS, default='EN_ATTENTE', verbose_name="Statut")
    methode_retrait = models.CharField(max_length=50, default="RETRAIT", verbose_name="Méthode de retrait")
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Total")
    transaction_id = models.CharField(max_length=100, blank=True, null=True, verbose_name="ID transaction")

    class Meta:
        verbose_name = "Commande"
        verbose_name_plural = "Commandes"
        ordering = ['-date_creation']

    def __str__(self):
        return f"Commande #{self.id} - {self.patient} - {self.get_statut_display()}"


class LigneCommande(models.Model):
    commande = models.ForeignKey(Commande, related_name='lignes', on_delete=models.CASCADE, verbose_name="Commande")
    produit = models.ForeignKey(Medicament, on_delete=models.CASCADE, verbose_name="Produit")
    pharmacie = models.ForeignKey(Pharmacie, on_delete=models.CASCADE, verbose_name="Pharmacie")
    quantite = models.PositiveIntegerField(verbose_name="Quantité")
    prix_unitaire = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Prix unitaire")

    class Meta:
        verbose_name = "Ligne de commande"
        verbose_name_plural = "Lignes de commande"

    def save(self, *args, **kwargs):
        if not self.prix_unitaire:
            self.prix_unitaire = self.produit.prix_vente
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.produit.nom_commercial} x{self.quantite}"


class Paiement(models.Model):
    commande_associee = models.OneToOneField(Commande, on_delete=models.CASCADE, verbose_name="Commande")
    montant_total = models.FloatField(verbose_name="Montant total")
    moyen_de_paiement = models.CharField(max_length=50, verbose_name="Moyen de paiement")
    identifiant_transaction_mobile = models.CharField(max_length=100, unique=True, verbose_name="ID transaction mobile")
    confirmation_paiement = models.BooleanField(default=False, verbose_name="Confirmation")

    class Meta:
        verbose_name = "Paiement"
        verbose_name_plural = "Paiements"
        ordering = ['-commande_associee__date_creation']

    def __str__(self):
        return f"Paiement #{self.id} - {self.montant_total} CFA"


class Notification(models.Model):
    destinataire = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name="mes_notifications", verbose_name="Destinataire")
    message = models.TextField(verbose_name="Message")
    heure_envoi = models.DateTimeField(auto_now_add=True, verbose_name="Heure d'envoi")
    type_notification = models.CharField(max_length=50, verbose_name="Type")
    lu = models.BooleanField(default=False, verbose_name="Lu")

    class Meta:
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"
        ordering = ['-heure_envoi']

    def __str__(self):
        return f"Notification pour {self.destinataire} - {self.type_notification}"


class Chatbot(models.Model):
    utilisateur = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="session_assistant", null=True, verbose_name="Utilisateur")
    date_ouverture_session = models.DateTimeField(auto_now_add=True, verbose_name="Date d'ouverture")

    class Meta:
        verbose_name = "Session chatbot"
        verbose_name_plural = "Sessions chatbot"

    def __str__(self):
        return f"Session {self.id} - {self.utilisateur}"


class Message(models.Model):
    chatbot_associe = models.ForeignKey(Chatbot, on_delete=models.CASCADE, related_name="messages", verbose_name="Chatbot")
    contenu_texte = models.TextField(verbose_name="Message")
    envoye_par_utilisateur = models.BooleanField(verbose_name="Envoyé par l'utilisateur")
    heure_message = models.DateTimeField(auto_now_add=True, verbose_name="Heure du message")

    class Meta:
        verbose_name = "Message"
        verbose_name_plural = "Messages"
        ordering = ['heure_message']

    def __str__(self):
        origine = "Moi" if self.envoye_par_utilisateur else "Assistant"
        return f"{origine}: {self.contenu_texte[:50]}"