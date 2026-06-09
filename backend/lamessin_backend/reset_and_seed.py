# reset_and_seed.py
import os
import django
from datetime import date, time, timedelta
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lamessin_backend.settings')
django.setup()

from django.db import connection
from django.contrib.auth import get_user_model
from lamessin_app.models import *

Utilisateur = get_user_model()

def reset_database():
    """Vider TOUTES les tables"""
    print("\n🔴 RESET COMPLET DE LA BASE DE DONNEES...")
    
    # Liste des modèles dans l'ordre (respect des clés étrangères)
    models_to_delete = [
        DetailOrdonnance, Ordonnance, Consultation, RendezVous,
        LigneCommande, Commande, PriseMedicament, Traitement,
        PlageHoraire, Stock, Chatbot, Message, Notification,
        Patient, Medecin, Pharmacien, Utilisateur
    ]
    
    # Supprimer dans l'ordre inverse
    for model in reversed(models_to_delete):
        try:
            count = model.objects.all().delete()[0]
            if count > 0:
                print(f"  ✓ Supprimé {count} {model.__name__}")
        except:
            pass
    
    print("\n✅ BASE DE DONNEES VIDEE\n")


def create_users():
    """Créer les utilisateurs de base"""
    print("\n👥 CREATION DES UTILISATEURS...")
    
    users_data = [
        # SUPERUSER ADMIN
        {
            "username": "admin",
            "telephone": "96000000",
            "email": "admin@lamessin.com",
            "password": "admin123",
            "first_name": "Admin",
            "last_name": "LAMESSIN",
            "is_superuser": True,
            "is_staff": True,
        },
        # PATIENT
        {
            "username": "patient_sessou",
            "telephone": "91770761",
            "email": "essodon@lamessin.tg",
            "password": "patient123",
            "first_name": "Essodon",
            "last_name": "SESSOU",
            "est_un_compte_patient": True,
        },
        # MEDECINS
        {
            "username": "dr_koffi",
            "telephone": "90000001",
            "email": "dr_koffi@lamessin.tg",
            "password": "medecin123",
            "first_name": "Mawuli",
            "last_name": "Koffi",
            "est_un_compte_medecin": True,
        },
        {
            "username": "dr_adjovi",
            "telephone": "90000002",
            "email": "dr_adjovi@lamessin.tg",
            "password": "medecin123",
            "first_name": "Komi",
            "last_name": "Adjovi",
            "est_un_compte_medecin": True,
        },
        {
            "username": "dr_mensa",
            "telephone": "90000003",
            "email": "dr_mensa@lamessin.tg",
            "password": "medecin123",
            "first_name": "Akossiwa",
            "last_name": "Mensa",
            "est_un_compte_medecin": True,
        },
        # PHARMACIEN
        {
            "username": "pharmacien_central",
            "telephone": "90123456",
            "email": "pharmacien@lamessin.tg",
            "password": "pharmacien123",
            "first_name": "Jean",
            "last_name": "DUPONT",
            "est_un_compte_pharmacien": True,
        },
    ]
    
    users = {}
    for data in users_data:
        user, created = Utilisateur.objects.get_or_create(
            numero_telephone=data["telephone"],
            defaults={
                "username": data["username"],
                "email": data["email"],
                "first_name": data["first_name"],
                "last_name": data["last_name"],
                "est_un_compte_patient": data.get("est_un_compte_patient", False),
                "est_un_compte_medecin": data.get("est_un_compte_medecin", False),
                "est_un_compte_pharmacien": data.get("est_un_compte_pharmacien", False),
                "is_superuser": data.get("is_superuser", False),
                "is_staff": data.get("is_staff", False),
            }
        )
        user.set_password(data["password"])
        user.save()
        users[data["username"]] = user
        print(f"  ✓ {data['first_name']} {data['last_name']} - {data['telephone']} / {data['password']}")
    
    return users


def create_patient(users):
    """Créer le profil patient"""
    print("\n🏥 CREATION DU PATIENT...")
    patient, _ = Patient.objects.get_or_create(
        compte_utilisateur=users["patient_sessou"],
        defaults={
            'groupe_sanguin': 'O+',
            'date_naissance': date(1995, 5, 15)
        }
    )
    print(f"  ✓ Patient: {patient.compte_utilisateur.last_name}")
    return patient


def create_medecins(users):
    """Créer les profils médecins"""
    print("\n👨‍⚕️ CREATION DES MEDECINS...")
    
    medecins_data = [
        {"user": "dr_koffi", "specialite": "Cardiologie", "licence": "MED001"},
        {"user": "dr_adjovi", "specialite": "Generaliste", "licence": "MED002"},
        {"user": "dr_mensa", "specialite": "Pediatrie", "licence": "MED003"},
    ]
    
    medecins = []
    for data in medecins_data:
        med, _ = Medecin.objects.get_or_create(
            compte_utilisateur=users[data["user"]],
            defaults={
                'specialite_medicale': data["specialite"],
                'numero_licence': data["licence"]
            }
        )
        medecins.append(med)
        print(f"  ✓ Dr {med.compte_utilisateur.last_name} - {med.specialite_medicale}")
    
    return medecins


def create_pharmacies():
    """Créer les pharmacies"""
    print("\n🏪 CREATION DES PHARMACIES...")
    
    pharmacies_data = [
        {"nom": "Pharmacie Centrale", "tel": "90000101", "adresse": "Lome, Be", "lat": 6.131, "lon": 1.222, "garde": True},
        {"nom": "Pharmacie de la Paix", "tel": "90000102", "adresse": "Lome, Deckon", "lat": 6.132, "lon": 1.223, "garde": False},
    ]
    
    pharmacies = []
    for data in pharmacies_data:
        pharm, _ = Pharmacie.objects.get_or_create(
            nom=data["nom"],
            defaults={
                'adresse': data["adresse"],
                'contact': data["tel"],
                'coordonnee_latitude_gps': data["lat"],
                'coordonnee_longitude_gps': data["lon"],
                'plage_horaire_ouverture': "08h-22h",
                'pharmacie_est_garde': data["garde"],
                'numero_paiement': data["tel"],
                'reseau_paiement': 'tmoney'
            }
        )
        pharmacies.append(pharm)
        print(f"  ✓ {pharm.nom}")
    
    return pharmacies


def create_pharmacien(users, pharmacies):
    """Créer le profil pharmacien"""
    print("\n💊 CREATION DU PHARMACIEN...")
    pharmacien, _ = Pharmacien.objects.get_or_create(
        compte_utilisateur=users["pharmacien_central"],
        defaults={
            'numero_licence': "PHARM-001",
            'pharmacie': pharmacies[0]
        }
    )
    print(f"  ✓ {pharmacien.compte_utilisateur.last_name} - {pharmacien.pharmacie.nom if pharmacien.pharmacie else 'Aucune pharmacie'}")


def create_medicaments(pharmacies):
    """Créer les médicaments et stocks"""
    print("\n💊 CREATION DES MEDICAMENTS...")
    
    medicaments_data = [
        {"nom": "Paracetamol 500mg", "prix": 150, "desc": "Douleurs et fievre", "stock": 50},
        {"nom": "Amoxicilline 1g", "prix": 3500, "desc": "Antibiotique", "stock": 30},
        {"nom": "Vitamine C 1000mg", "prix": 1200, "desc": "Immunite", "stock": 100},
        {"nom": "Ibuprofene 400mg", "prix": 800, "desc": "Anti-inflammatoire", "stock": 45},
        {"nom": "Aspirine 500mg", "prix": 250, "desc": "Anti-coagulant", "stock": 60},
    ]
    
    medicaments = []
    for data in medicaments_data:
        m, _ = Medicament.objects.get_or_create(
            nom_commercial=data["nom"],
            defaults={
                'description': data["desc"],
                'posologie_standard': "Selon prescription médicale",
                'prix_vente': data["prix"]
            }
        )
        medicaments.append(m)
        
        for pharm in pharmacies:
            Stock.objects.get_or_create(
                produit_concerne=m,
                pharmacie_detentrice=pharm,
                defaults={
                    'quantite_actuelle_en_stock': data["stock"],
                    'seuil_alerte': 10,
                    'date_peremption': date(2027, 12, 31)
                }
            )
        print(f"  ✓ {m.nom_commercial} - {data['prix']} FCFA")
    
    return medicaments


def create_plages_horaires(medecins):
    """Créer les plages horaires"""
    print("\n📅 CREATION DES PLAGES HORAIRES...")
    
    aujourdhui = date.today()
    date_fin = date(2026, 7, 30)
    
    # Jours du lundi au vendredi
    jours = []
    current = aujourdhui
    while current <= date_fin:
        if current.weekday() < 5:  # Lundi à Vendredi
            jours.append(current)
        current += timedelta(days=1)
    
    plages_data = [
        (medecins[0], 8, 12, 30),   # Cardiologie - Matin
        (medecins[0], 14, 18, 30),  # Cardiologie - Après-midi
        (medecins[1], 9, 13, 20),   # Généraliste
        (medecins[2], 10, 14, 25),  # Pédiatrie
    ]
    
    count = 0
    for jour in jours:
        for med, h_debut, h_fin, duree in plages_data:
            PlageHoraire.objects.get_or_create(
                medecin=med,
                date=jour,
                heure_debut=time(h_debut, 0),
                heure_fin=time(h_fin, 0),
                defaults={'duree_consultation': duree}
            )
            count += 1
    
    print(f"  ✓ {count} plages horaires créées")


def create_rendezvous(patient, medecins):
    """Créer des rendez-vous de démonstration"""
    print("\n📋 CREATION DES RENDEZ-VOUS...")
    
    aujourdhui = date.today()
    
    rendezvous = [
        {
            "patient": patient,
            "medecin": medecins[0],
            "date": aujourdhui + timedelta(days=1),
            "heure": time(9, 30),
            "motif": "Douleur thoracique",
            "statut": "confirme"
        },
        {
            "patient": patient,
            "medecin": medecins[2],
            "date": aujourdhui - timedelta(days=2),
            "heure": time(10, 0),
            "motif": "Consultation pediatrique",
            "statut": "termine"
        },
        {
            "patient": patient,
            "medecin": medecins[1],
            "date": aujourdhui + timedelta(days=3),
            "heure": time(11, 0),
            "motif": "Consultation generale",
            "statut": "en_attente"
        },
    ]
    
    created_rdv = []
    for rdv_data in rendezvous:
        rdv, _ = RendezVous.objects.get_or_create(
            patient_demandeur=rdv_data["patient"],
            medecin_concerne=rdv_data["medecin"],
            date_rdv=rdv_data["date"],
            heure_rdv=rdv_data["heure"],
            defaults={
                'motif_consultation': rdv_data["motif"],
                'statut_actuel_rdv': rdv_data["statut"]
            }
        )
        created_rdv.append(rdv)
        print(f"  ✓ {rdv.motif_consultation} - {rdv.date_rdv} {rdv.heure_rdv}")
    
    return created_rdv


def create_consultation(rendezvous_list):
    """Créer une consultation pour un rendez-vous passé"""
    print("\n🩺 CREATION DES CONSULTATIONS...")
    
    for rdv in rendezvous_list:
        if rdv.statut_actuel_rdv == "termine":
            Consultation.objects.get_or_create(
                rdv=rdv,
                defaults={
                    'diagnostic': "Examen medical complet. Patient en bonne sante.",
                    'actes_effectues': "Auscultation, prise de tension, examen general",
                    'notes_medecin': "Aucune anomalie detectee. Retour si symptomes."
                }
            )
            print(f"  ✓ Consultation pour RDV du {rdv.date_rdv}")
            break


def create_ordonnance(medecins, patient, medicaments):
    """Créer une ordonnance"""
    print("\n📄 CREATION DES ORDONNANCES...")
    
    import random
    code = ''.join(random.choices('0123456789', k=10))
    
    ordonnance, _ = Ordonnance.objects.get_or_create(
        medecin_prescripteur=medecins[0],
        patient_beneficiaire=patient,
        defaults={'code_securite': code}
    )
    
    for medicament in medicaments[:3]:
        DetailOrdonnance.objects.get_or_create(
            ordonnance=ordonnance,
            medicament=medicament,
            defaults={
                'quantite_boites': 2,
                'posologie_specifique': "1 comprime matin et soir",
                'duree_traitement_jours': 7
            }
        )
    
    print(f"  ✓ Ordonnance #{ordonnance.id} avec {ordonnance.lignes.count()} medicaments")
    return ordonnance


def create_notifications(users):
    """Créer des notifications"""
    print("\n🔔 CREATION DES NOTIFICATIONS...")
    
    Notification.objects.create(
        destinataire=users["patient_sessou"],
        message="Bienvenue sur LAMESSIN ! Votre compte patient a ete cree avec succes.",
        type_notification="BIENVENUE"
    )
    Notification.objects.create(
        destinataire=users["patient_sessou"],
        message="Pensez a consulter votre dossier medical en ligne.",
        type_notification="RAPPEL"
    )
    print("  ✓ 2 notifications creees")


def main():
    print("=" * 60)
    print("   LAMESSIN - RESET ET REMPLISSAGE DE LA BASE")
    print("=" * 60)
    
    # 1. Vider la base
    reset_database()
    
    # 2. Créer les utilisateurs
    users = create_users()
    
    # 3. Créer les profils
    patient = create_patient(users)
    medecins = create_medecins(users)
    pharmacies = create_pharmacies()
    create_pharmacien(users, pharmacies)
    
    # 4. Créer les médicaments
    medicaments = create_medicaments(pharmacies)
    
    # 5. Créer les plages horaires
    create_plages_horaires(medecins)
    
    # 6. Créer les rendez-vous
    rendezvous_list = create_rendezvous(patient, medecins)
    
    # 7. Créer consultation
    create_consultation(rendezvous_list)
    
    # 8. Créer ordonnance
    create_ordonnance(medecins, patient, medicaments)
    
    # 9. Créer notifications
    create_notifications(users)
    
    # 10. Résumé final
    print("\n" + "=" * 60)
    print("✅ BASE DE DONNEES PRETE !")
    print("=" * 60)
    print("\n🔐 COMPTES DE CONNEXION :")
    print("   👑 SUPER ADMIN   | Tel: 96000000  | Mdp: admin123")
    print("   👤 PATIENT       | Tel: 91770761  | Mdp: patient123")
    print("   👨‍⚕️ MEDECIN       | Tel: 90000001  | Mdp: medecin123")
    print("   👨‍⚕️ MEDECIN       | Tel: 90000002  | Mdp: medecin123")
    print("   👨‍⚕️ MEDECIN       | Tel: 90000003  | Mdp: medecin123")
    print("   💊 PHARMACIEN    | Tel: 90123456  | Mdp: pharmacien123")
    print("\n📊 STATISTIQUES :")
    print(f"   - {Utilisateur.objects.count()} utilisateurs")
    print(f"   - {Medicament.objects.count()} medicaments")
    print(f"   - {Pharmacie.objects.count()} pharmacies")
    print(f"   - {RendezVous.objects.count()} rendez-vous")
    print(f"   - {PlageHoraire.objects.count()} plages horaires")
    print("=" * 60)


if __name__ == "__main__":
    main()