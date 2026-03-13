from rest_framework import serializers
from .models import *
from django.utils import timezone


# ====================================================================================================
# SERIALIZERS UTILISATEURS
# ====================================================================================================

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ('id', 'username', 'email', 'numero_telephone', 'first_name', 'last_name',
                  'est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien')


class PatientSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Patient
        fields = ('compte_utilisateur', 'date_naissance', 'groupe_sanguin')


class MedecinSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Medecin
        fields = ('compte_utilisateur', 'specialite_medicale', 'numero_licence')


class PharmacienSerializer(serializers.ModelSerializer):
    compte_utilisateur = UtilisateurSerializer(read_only=True)

    class Meta:
        model = Pharmacien
        fields = ('compte_utilisateur', 'numero_licence')


class InscriptionSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    type_compte = serializers.ChoiceField(choices=['patient', 'medecin', 'pharmacien'], write_only=True)

    # Champs optionnels selon le profil
    specialite_medicale = serializers.CharField(required=False, write_only=True)
    numero_licence = serializers.CharField(required=False, write_only=True)
    date_naissance = serializers.DateField(required=False, write_only=True)
    groupe_sanguin = serializers.CharField(required=False, write_only=True)

    class Meta:
        model = Utilisateur
        fields = ('username', 'numero_telephone', 'email', 'password', 'first_name', 'last_name',
                  'type_compte', 'specialite_medicale', 'numero_licence', 'date_naissance', 'groupe_sanguin')

    def validate(self, data):
        type_compte = data.get('type_compte')
        errors = {}
        if type_compte == 'medecin':
            if not data.get('specialite_medicale'): errors['specialite_medicale'] = "Requis pour médecin."
            if not data.get('numero_licence'): errors['numero_licence'] = "Requis pour médecin."
        elif type_compte == 'pharmacien' and not data.get('numero_licence'):
            errors['numero_licence'] = "Requis pour pharmacien."
        elif type_compte == 'patient' and not data.get('date_naissance'):
            errors['date_naissance'] = "Date de naissance requise."

        if errors: raise serializers.ValidationError(errors)
        return data

    def create(self, validated_data):
        type_compte = validated_data.pop('type_compte')
        spec = validated_data.pop('specialite_medicale', None)
        licence = validated_data.pop('numero_licence', None)
        naissance = validated_data.pop('date_naissance', None)
        sang = validated_data.pop('groupe_sanguin', None)

        user = Utilisateur.objects.create_user(**validated_data)

        if type_compte == 'patient':
            user.est_un_compte_patient = True
            Patient.objects.create(compte_utilisateur=user, date_naissance=naissance, groupe_sanguin=sang)
        elif type_compte == 'medecin':
            user.est_un_compte_medecin = True
            Medecin.objects.create(compte_utilisateur=user, specialite_medicale=spec, numero_licence=licence)
        elif type_compte == 'pharmacien':
            user.est_un_compte_pharmacien = True
            Pharmacien.objects.create(compte_utilisateur=user, numero_licence=licence)

        user.save()
        return user

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
        fields = ('id', 'date_prescription', 'medecin_nom', 'code_securite', 'lignes')


class ConsultationSerializer(serializers.ModelSerializer):
    ordonnances = OrdonnanceSerializer(many=True, read_only=True)

    class Meta:
        model = Consultation
        fields = ('id', 'rdv', 'diagnostic', 'actes_effectues', 'notes_medecin', 'date_consultation', 'ordonnances')


# ====================================================================================================
# SERIALIZERS RENDEZ-VOUS
# ====================================================================================================

class RendezVousSerializer(serializers.ModelSerializer):
    patient_demandeur = PatientSerializer(read_only=True)
    medecin_concerne = MedecinSerializer(read_only=True)
# On affiche si une consultation a déjà eu lieu pour ce RDV
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
    nom_medicament = serializers.ReadOnlyField(source='medicament_ajoute.nom_commercial')
    pharmacie_nom = serializers.ReadOnlyField(source='pharmacie_vendeuse.nom')

    class Meta:
        model = LigneCommande
        # Utilise exactement les noms de ton modèle
        fields = ('id', 'medicament_ajoute', 'nom_medicament', 'quantite_commandee', 'prix_unitaire', 'pharmacie_nom')

class CommandeSerializer(serializers.ModelSerializer):
    # Utilise source='lignecommande_set' si tu n'as pas mis de related_name='lignes' dans ton modèle
    lignes = LigneCommandeSerializer(source='lignecommande_set', many=True, read_only=True)
    prix_total = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Commande
        fields = ('id', 'patient_acheteur', 'date_commande', 'statut_commande', 'methode_retrait', 'lignes', 'prix_total')
    def get_prix_total(self, obj):
        total = sum(ligne.quantite_commandee * ligne.prix_unitaire for ligne in obj.lignes.all())
        return total

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
        fields = ['id', 'message', 'heure_envoi', 'type_notification']


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
                  'plage_horaire_ouverture', 'type_etablissement', 'pharmacie_est_garde')

    def get_type_etablissement(self, obj):

        if hasattr(obj, 'pharmacie'):
            return "pharmacie"
        if hasattr(obj, 'hopital'):
            return "hopital"
        return "general"

    def get_pharmacie_est_garde(self, obj):
        return obj.pharmacie.pharmacie_est_garde if hasattr(obj, 'pharmacie') else False

# ====================================================================================================
# SERIALIZERS MÉDICAMENTS & STOCK
# ====================================================================================================

class MedicamentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicament
        fields = ('id', 'nom_commercial', 'description', 'posologie_standard', 'prix_vente')


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
        fields = ('id', 'nom_commercial', 'description', 'posologie_standard', 'prix_vente', 'stocks_disponibles')

    def get_stocks_disponibles(self, obj):
        stocks = Stock.objects.filter(produit_concerne=obj, quantite_actuelle_en_stock__gt=0)
        return StockPharmacieSerializer(stocks, many=True).data

#--------------------------------------------------------------------------------------------------------------------