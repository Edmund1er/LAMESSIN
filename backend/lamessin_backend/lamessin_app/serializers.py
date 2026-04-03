# lamessin_app/serializers.py

from rest_framework import serializers
from .models import *
from django.utils import timezone
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


# ====================================================================================================
# SERIALIZERS UTILISATEURS
# ====================================================================================================

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ('id', 'username', 'email', 'numero_telephone', 'first_name', 'last_name',
                  'est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien')


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['numero_telephone'] = serializers.CharField()
        self.fields.pop('username', None)

    def validate(self, attrs):
        attrs['username'] = attrs.get('numero_telephone')
        data = super().validate(attrs)

        user = self.user
        if user.est_un_compte_patient:
            data['role'] = 'PATIENT'
        elif user.est_un_compte_medecin:
            data['role'] = 'MEDECIN'
        elif user.est_un_compte_pharmacien:
            data['role'] = 'PHARMACIEN'
        else:
            data['role'] = 'INCONNU'

        return data


class PatientSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Patient
        fields = ('compte_utilisateur', 'date_naissance', 'groupe_sanguin', 'photo_profil')


class MedecinSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Medecin
        fields = ('compte_utilisateur', 'specialite_medicale', 'numero_licence', 'photo_profil')


class PharmacienSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Pharmacien
        fields = ('compte_utilisateur', 'numero_licence')


class InscriptionSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    type_compte = serializers.ChoiceField(choices=['patient', 'medecin', 'pharmacien'], write_only=True)

    specialite_medicale = serializers.CharField(required=False, write_only=True)
    numero_licence = serializers.CharField(required=False, write_only=True)
    date_naissance = serializers.DateField(required=False, write_only=True)
    groupe_sanguin = serializers.CharField(required=False, write_only=True)
    photo_profil = serializers.ImageField(required=False, write_only=True)

    class Meta:
        model = Utilisateur
        fields = ('username', 'numero_telephone', 'email', 'password', 'first_name', 'last_name',
                  'type_compte', 'specialite_medicale', 'numero_licence', 'date_naissance', 'groupe_sanguin',
                  'photo_profil')

    def validate(self, data):
        type_compte = data.get('type_compte', '').lower()
        errors = {}

        if type_compte == 'medecin':
            if not data.get('specialite_medicale'):
                errors['specialite_medicale'] = "Requis pour médecin."
            if not data.get('numero_licence'):
                errors['numero_licence'] = "Requis pour médecin."
        elif type_compte == 'pharmacien' and not data.get('numero_licence'):
            errors['numero_licence'] = "Requis pour pharmacien."
        elif type_compte == 'patient' and not data.get('date_naissance'):
            errors['date_naissance'] = "Date de naissance requise."

        if errors:
            raise serializers.ValidationError(errors)
        return data

    def create(self, validated_data):
        type_compte = validated_data.pop('type_compte').lower()
        spec = validated_data.pop('specialite_medicale', None)
        licence = validated_data.pop('numero_licence', None)
        naissance = validated_data.pop('date_naissance', None)
        sang = validated_data.pop('groupe_sanguin', None)
        photo = validated_data.pop('photo_profil', None)

        user = Utilisateur.objects.create_user(**validated_data)

        if type_compte == 'patient':
            user.est_un_compte_patient = True
            Patient.objects.create(
                compte_utilisateur=user,
                date_naissance=naissance,
                groupe_sanguin=sang,
                photo_profil=photo
            )
        elif type_compte == 'medecin':
            user.est_un_compte_medecin = True
            Medecin.objects.create(
                compte_utilisateur=user,
                specialite_medicale=spec,
                numero_licence=licence,
                photo_profil=photo
            )
        elif type_compte == 'pharmacien':
            user.est_un_compte_pharmacien = True
            Pharmacien.objects.create(
                compte_utilisateur=user,
                numero_licence=licence
            )

        user.save()
        return user


# ====================================================================================================
# SERIALIZERS MÉDECIN (PLAGES HORAIRES)
# ====================================================================================================

class PlageHoraireSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlageHoraire
        fields = ('id', 'medecin', 'date', 'heure_debut', 'heure_fin', 'duree_consultation')


# ====================================================================================================
# SERIALIZERS SOINS, CONSULTATIONS & ORDONNANCES
# ====================================================================================================

class DetailOrdonnanceSerializer(serializers.ModelSerializer):
    nom_medicament = serializers.ReadOnlyField(source='medicament.nom_commercial')

    class Meta:
        model = DetailOrdonnance
        fields = ('id', 'medicament', 'nom_medicament', 'quantite_boites', 'posologie_specifique',
                  'duree_traitement_jours')


class OrdonnanceSerializer(serializers.ModelSerializer):
    lignes = DetailOrdonnanceSerializer(many=True, read_only=True)
    medecin_nom = serializers.ReadOnlyField(source='medecin_prescripteur.compte_utilisateur.last_name')

    class Meta:
        model = Ordonnance
        fields = ('id', 'date_prescription', 'medecin_nom', 'code_securite', 'lignes', 'fichier_ordonnance')


class ConsultationSerializer(serializers.ModelSerializer):
    ordonnances = OrdonnanceSerializer(many=True, read_only=True)

    class Meta:
        model = Consultation
        fields = ('id', 'rdv', 'diagnostic', 'actes_effectues', 'notes_medecin', 'date_consultation',
                  'ordonnances', 'document_joint')


# ====================================================================================================
# SERIALIZERS RENDEZ-VOUS
# ====================================================================================================

class RendezVousSerializer(serializers.ModelSerializer):
    patient_demandeur = PatientSerializer(read_only=True)
    medecin_concerne = MedecinSerializer(read_only=True)
    a_ete_consulte = serializers.SerializerMethodField()

    class Meta:
        model = RendezVous
        fields = ('id', 'patient_demandeur', 'medecin_concerne', 'date_rdv', 'heure_rdv', 'motif_consultation',
                  'statut_actuel_rdv', 'a_ete_consulte')

    def get_a_ete_consulte(self, obj):
        return hasattr(obj, 'consultation')


class RendezVousCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RendezVous
        fields = ['patient_demandeur', 'medecin_concerne', 'date_rdv', 'heure_rdv', 'motif_consultation',
                  'statut_actuel_rdv']


# ====================================================================================================
# SERIALIZERS COMMANDES & PAIEMENTS
# ====================================================================================================

class LigneCommandeSerializer(serializers.ModelSerializer):
    nom_medicament = serializers.ReadOnlyField(source='produit.nom_commercial')
    pharmacie_nom = serializers.ReadOnlyField(source='pharmacie.nom')
    image_produit = serializers.ImageField(source='produit.image_produit', read_only=True)

    class Meta:
        model = LigneCommande
        fields = ('id', 'produit', 'nom_medicament', 'quantite', 'prix_unitaire', 'pharmacie_nom', 'image_produit')


class CommandeSerializer(serializers.ModelSerializer):
    lignes = LigneCommandeSerializer(many=True, read_only=True)
    patient_nom = serializers.ReadOnlyField(source='patient.compte_utilisateur.last_name')
    estimation_retrait = serializers.SerializerMethodField()

    class Meta:
        model = Commande
        fields = ('id', 'patient_nom', 'date_creation', 'statut', 'methode_retrait', 'lignes', 'total',
                  'estimation_retrait', 'transaction_id')

    def get_estimation_retrait(self, obj):
        if obj.methode_retrait == "LIVRAISON":
            return "Estimation : 1h à 2h"
        return "Prêt pour retrait dans 30 min"


# ====================================================================================================
# SERIALIZERS SUIVI, NOTIFICATIONS & CHAT
# ====================================================================================================

class PriseMedicamentSerializer(serializers.ModelSerializer):
    class Meta:
        model = PriseMedicament
        fields = '__all__'


class TraitementSerializer(serializers.ModelSerializer):
    prises = PriseMedicamentSerializer(many=True, read_only=True)

    class Meta:
        model = Traitement
        fields = ('id', 'nom_du_traitement', 'date_debut_traitement', 'date_fin_traitement', 'prises')


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'message', 'heure_envoi', 'type_notification', 'lu']


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ('id', 'contenu_texte', 'envoye_par_utilisateur', 'heure_message')


# ====================================================================================================
# SERIALIZERS ÉTABLISSEMENTS
# ====================================================================================================

class EtablissementSanteSerializer(serializers.ModelSerializer):
    type_etablissement = serializers.SerializerMethodField()
    pharmacie_est_garde = serializers.SerializerMethodField()

    class Meta:
        model = EtablissementSante
        fields = ('id', 'nom', 'adresse', 'contact', 'coordonnee_latitude_gps', 'coordonnee_longitude_gps',
                  'plage_horaire_ouverture', 'type_etablissement', 'pharmacie_est_garde', 'image_etablissement')

    def get_type_etablissement(self, obj):
        if hasattr(obj, 'pharmacie'):
            return "pharmacie"
        if hasattr(obj, 'hopital'):
            return "hopital"
        return "general"

    def get_pharmacie_est_garde(self, obj):
        if hasattr(obj, 'pharmacie') and obj.pharmacie:
            return obj.pharmacie.pharmacie_est_garde
        return False


# ====================================================================================================
# SERIALIZERS MÉDICAMENTS & STOCK
# ====================================================================================================

class MedicamentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicament
        fields = ('id', 'nom_commercial', 'description', 'posologie_standard', 'prix_vente', 'image_produit')


class StockSerializer(serializers.ModelSerializer):
    produit_concerne = MedicamentSerializer(read_only=True)

    class Meta:
        model = Stock
        fields = ('id', 'produit_concerne', 'quantite_actuelle_en_stock', 'seuil_alerte', 'date_peremption')


class StockPharmacieSerializer(serializers.ModelSerializer):
    id_pharmacie = serializers.ReadOnlyField(source='pharmacie_detentrice.id')
    nom_pharmacie = serializers.ReadOnlyField(source='pharmacie_detentrice.nom')
    adresse_pharmacie = serializers.ReadOnlyField(source='pharmacie_detentrice.adresse')
    latitude = serializers.ReadOnlyField(source='pharmacie_detentrice.coordonnee_latitude_gps')
    longitude = serializers.ReadOnlyField(source='pharmacie_detentrice.coordonnee_longitude_gps')

    class Meta:
        model = Stock
        fields = ('id_pharmacie', 'nom_pharmacie', 'adresse_pharmacie',
                  'quantite_actuelle_en_stock', 'date_peremption', 'latitude', 'longitude')


class MedicamentsSerializer(serializers.ModelSerializer):
    stocks_disponibles = serializers.SerializerMethodField()

    class Meta:
        model = Medicament
        fields = ('id', 'nom_commercial', 'description', 'posologie_standard', 'prix_vente', 'image_produit',
                  'stocks_disponibles')

    def get_stocks_disponibles(self, obj):
        stocks = Stock.objects.filter(produit_concerne=obj, quantite_actuelle_en_stock__gt=0)
        return StockPharmacieSerializer(stocks, many=True).data