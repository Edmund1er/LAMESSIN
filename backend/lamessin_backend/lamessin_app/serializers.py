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
            
# Serializer utilisé uniquement pour l'envoi de données depuis Flutter
class RendezVousCreateSerializer(serializers.ModelSerializer):
    # On accepte ces champs depuis Flutter
    date_selectionnee = serializers.DateField(write_only=True)
    heure_selectionnee = serializers.CharField(write_only=True) # Format "HH:MM"

    class Meta:
        model = RendezVous
        fields = [
            'patient_demandeur', 'medecin_concerne', 
            'date_selectionnee', 'heure_selectionnee', 
            'motif_consultation', 'statut_actuel_rdv'
        ]

    def create(self, validated_data):
        # 1. Récupérer les données
        date_jour = validated_data.pop('date_selectionnee')
        heure_str = validated_data.pop('heure_selectionnee')
        medecin = validated_data['medecin_concerne']
        
        # 2. Convertir l'heure string en objet time
        try:
            heure, minute = map(int, heure_str.split(':'))
            heure_obj = time(heure, minute)
        except:
            raise serializers.ValidationError("Format de l'heure invalide (attendu HH:MM).")

        # 3. Créer les objets DateTime complets pour le créneau
        debut_creneau = datetime.combine(date_jour, heure_obj)
        fin_creneau = debut_creneau + timedelta(minutes=30) # Supposons créneau de 30min

        # 4. Gérer l'Agenda et le Créneau
        # Récupérer ou créer l'agenda du médecin
        agenda, _ = Agenda.objects.get_or_create(medecin_proprietaire=medecin)

        # Vérifier si le créneau existe déjà ou en créer un nouveau
        # Note: Dans une vraie app, il faut vérifier si 'est_libre' est True
        creneau, created = Creneau.objects.get_or_create(
            agenda=agenda,
            date_debut_creneau=debut_creneau,
            defaults={
                'date_fin_creneau': fin_creneau,
                'est_libre': True
            }
        )

        if not creneau.est_libre:
             raise serializers.ValidationError("Ce créneau horaire est déjà pris.")

        # 5. Créer le Rendez-vous en liant le créneau trouvé/créé
        validated_data['creneau_reserve'] = creneau
        
        return super().create(validated_data)
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