from rest_framework import serializers
from .models import *


# =========================
# SERIALIZERS UTILISATEURS
# =========================

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
# Champ mot de passe
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

#Selection du type de compte
    type_compte = serializers.ChoiceField(choices=['patient', 'medecin', 'pharmacien'], write_only=True)

# Champs specifiques selon le profil
    specialite_medicale = serializers.CharField(required=False, write_only=True)
    numero_licence = serializers.CharField(required=False, write_only=True)
    date_naissance = serializers.DateField(required=False, write_only=True)
    groupe_sanguin = serializers.CharField(required=False, write_only=True)

    class Meta:
        model = Utilisateur
        fields = (
            'username', 'numero_telephone', 'email', 'password', 'first_name', 'last_name',
            'type_compte', 'specialite_medicale', 'numero_licence', 'date_naissance', 'groupe_sanguin'
        )

# fonction de validation pour s'assurer que les champs requis selon le rôle sont remplis


    def validate(self, data):
        type_compte = data.get('type_compte')
        errors = {}

        if type_compte == 'medecin':
            if not data.get('specialite_medicale'):
                errors['specialite_medicale'] = "Ce champ est requis pour un médecin."
            if not data.get('numero_licence'):
                errors['numero_licence'] = "Ce champ est requis pour un médecin."

        elif type_compte == 'pharmacien':
            if not data.get('numero_licence'):
                errors['numero_licence'] = "Ce champ est requis pour un pharmacien."

        elif type_compte == 'patient':
            if not data.get('date_naissance'):
                errors['date_naissance'] = "La date de naissance est requise."

        if errors:
            raise serializers.ValidationError(errors)

        return data

    def create(self, validated_data):
#On extrait les données qui ne font pas parti de Utilisateur
        type_compte = validated_data.pop('type_compte')

        spec = validated_data.pop('specialite_medicale', None)
        licence = validated_data.pop('numero_licence', None)
        naissance = validated_data.pop('date_naissance', None)
        sang = validated_data.pop('groupe_sanguin', None)

#Création de l'utilisateur avec le mot de passe qui est haché automatiquement par create_user
        user = Utilisateur.objects.create_user(
            username=validated_data['username'],
            numero_telephone=validated_data['numero_telephone'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
        )

#Création du profil spécifique selon le type
        if type_compte == 'patient':
            user.est_un_compte_patient = True
            Patient.objects.create(
                compte_utilisateur=user,
                date_naissance=naissance,
                groupe_sanguin=sang
            )

        elif type_compte == 'medecin':
            user.est_un_compte_medecin = True
            Medecin.objects.create(
                compte_utilisateur=user,
                specialite_medicale=spec,
                numero_licence=licence
            )

        elif type_compte == 'pharmacien':
            user.est_un_compte_pharmacien = True
            Pharmacien.objects.create(
                compte_utilisateur=user,
                numero_licence=licence
            )

        user.save()
        return user


# =========================
# SERIALIZERS MÉDICAMENTS & STOCK
# =========================

class MedicamentSerializer(serializers.ModelSerializer):
      class Meta:
            model = Medicament
            fields = ('id', 'nom_commercial', 'description', 'posologie', 'prix_vente')


class StockSerializer(serializers.ModelSerializer):
      produit_concerne = MedicamentSerializer(read_only=True)
      pharmacie_detentrice = PharmacienSerializer(read_only=True)

      class Meta:
            model = Stock
            fields = ('id', 'produit_concerne', 'pharmacie_detentrice', 'quantite_actuelle_en_stock', 'seuil_alerte',
                      'date_peremption')


# =========================
# SERIALIZERS RENDEZ-VOUS
# =========================

class CreneauSerializer(serializers.ModelSerializer):
      class Meta:
            model = Creneau
            fields = ('id', 'date_debut_creneau', 'date_fin_creneau', 'est_libre')


class RendezVousSerializer(serializers.ModelSerializer):
      patient_demandeur = PatientSerializer(read_only=True)
      medecin_concerne = MedecinSerializer(read_only=True)
      creneau_reserve = CreneauSerializer(read_only=True)

      class Meta:
            model = RendezVous
            fields = ('id', 'patient_demandeur', 'medecin_concerne', 'creneau_reserve', 'motif_consultation',
                      'statut_actuel_rdv')


# =========================
# SERIALIZERS COMMANDES
# =========================

class LigneCommandeSerializer(serializers.ModelSerializer):
      class Meta:
            model = LigneCommande
            fields = ('id', 'medicament_ajoute', 'quantite_commandee', 'prix_unitaire')


class CommandeSerializer(serializers.ModelSerializer):
      lignes = LigneCommandeSerializer(many=True, read_only=True)

      class Meta:
            model = Commande
            fields = ('id', 'patient_acheteur', 'date', 'statut_commande', 'methode_retrait', 'lignes')


# =========================
# SERIALIZERS SUIVI & CHAT
# =========================

class TraitementSerializer(serializers.ModelSerializer):
      class Meta:
            model = Traitement
            fields = '__all__'


class MessageSerializer(serializers.ModelSerializer):
      class Meta:
            model = Message
            fields = ('id', 'contenu_texte', 'envoye_par_utilisateur', 'heure_message')