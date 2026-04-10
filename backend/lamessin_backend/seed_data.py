# seed_data.py

import os
import django
import random
from datetime import date, time, timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lamessin_backend.settings')
django.setup()

from lamessin_app.models import (
    Utilisateur, Patient, Medecin, Pharmacien, Pharmacie, Hopital,
    Medicament, Stock, PlageHoraire, Notification, Chatbot,
    Traitement, Commande, LigneCommande, RendezVous, Consultation, 
    Ordonnance, DetailOrdonnance, PriseMedicament
)


def run_seed():
    print("=" * 50)
    print("SEED LAMESSIN")
    print("=" * 50)

    # 1. Nettoyage
    print("\nNettoyage...")
    RendezVous.objects.all().delete()
    PlageHoraire.objects.all().delete()
    Consultation.objects.all().delete()
    Commande.objects.all().delete()
    LigneCommande.objects.all().delete()
    Traitement.objects.all().delete()
    PriseMedicament.objects.all().delete()
    Ordonnance.objects.all().delete()
    DetailOrdonnance.objects.all().delete()  # CORRECTION ICI
    Notification.objects.all().delete()
    print("OK")

    # 2. Patient
    print("\nCreation patient...")
    patient_user, _ = Utilisateur.objects.get_or_create(
        numero_telephone="91770761",
        defaults={
            'username': 'patient_sessou',
            'email': 'essodon@lamessin.tg',
            'first_name': 'Essodon',
            'last_name': 'SESSOU',
            'est_un_compte_patient': True
        }
    )
    patient_user.set_password("Romaric12345")
    patient_user.save()
    
    patient, _ = Patient.objects.get_or_create(
        compte_utilisateur=patient_user,
        defaults={'groupe_sanguin': 'O+', 'date_naissance': date(1995, 5, 15)}
    )
    Chatbot.objects.get_or_create(utilisateur=patient_user)
    print(f"Patient: {patient_user.last_name} - Tel: {patient_user.numero_telephone} - Mdp: Romaric12345")

    # 3. Medecins
    print("\nCreation medecins...")
    medecins_data = [
        {"tel": "90000001", "user": "dr_koffi", "nom": "Koffi", "prenom": "Mawuli", "specialite": "Cardiologie", "licence": "MED001"},
        {"tel": "90000002", "user": "dr_adjovi", "nom": "Adjovi", "prenom": "Komi", "specialite": "Generaliste", "licence": "MED002"},
        {"tel": "90000003", "user": "dr_mensa", "nom": "Mensa", "prenom": "Akossiwa", "specialite": "Pediatrie", "licence": "MED003"},
    ]
    
    medecins = []
    for data in medecins_data:
        user, _ = Utilisateur.objects.get_or_create(
            numero_telephone=data["tel"],
            defaults={
                'username': data["user"],
                'email': f"{data['user']}@lamessin.tg",
                'first_name': data["prenom"],
                'last_name': data["nom"],
                'est_un_compte_medecin': True
            }
        )
        user.set_password("doctor123")
        user.save()
        
        med, _ = Medecin.objects.get_or_create(
            compte_utilisateur=user,
            defaults={
                'specialite_medicale': data["specialite"],
                'numero_licence': data["licence"]
            }
        )
        medecins.append(med)
        print(f"Dr {user.last_name} - Tel: {user.numero_telephone} - Mdp: doctor123")

    # 4. Pharmacies
    print("\nCreation pharmacies...")
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
        print(f"{pharm.nom}")

    # 5. Medicaments
    print("\nCreation medicaments...")
    medicaments_data = [
        {"nom": "Paracetamol 500mg", "prix": 150, "desc": "Douleurs et fievre"},
        {"nom": "Amoxicilline 1g", "prix": 3500, "desc": "Antibiotique"},
        {"nom": "Vitamine C 1000mg", "prix": 1200, "desc": "Immunite"},
        {"nom": "Ibuprofene 400mg", "prix": 800, "desc": "Anti-inflammatoire"},
    ]
    
    medicaments = []
    for data in medicaments_data:
        m, _ = Medicament.objects.get_or_create(
            nom_commercial=data["nom"],
            defaults={
                'description': data["desc"],
                'posologie_standard': "Selon prescription",
                'prix_vente': data["prix"]
            }
        )
        medicaments.append(m)
        
        for pharm in pharmacies:
            Stock.objects.get_or_create(
                produit_concerne=m,
                pharmacie_detentrice=pharm,
                defaults={
                    'quantite_actuelle_en_stock': random.randint(20, 100),
                    'seuil_alerte': 10,
                    'date_peremption': date(2027, 12, 31)
                }
            )
        print(f"{m.nom_commercial} - {data['prix']} FCFA")

    # 6. Plages horaires
    print("\nCreation plages horaires...")
    aujourdhui = date.today()
    demain = aujourdhui + timedelta(days=1)
    apres_demain = aujourdhui + timedelta(days=2)

    plages_config = [
        (medecins[0], demain, time(8, 0), time(12, 0), 30),
        (medecins[0], apres_demain, time(14, 0), time(18, 0), 30),
        (medecins[1], demain, time(9, 0), time(13, 0), 20),
        (medecins[2], demain, time(10, 0), time(14, 0), 25),
    ]
    
    for med, d, debut, fin, duree in plages_config:
        PlageHoraire.objects.get_or_create(
            medecin=med, date=d, heure_debut=debut, heure_fin=fin,
            defaults={'duree_consultation': duree}
        )
    print(f"{len(plages_config)} plages horaires creees")

    # 7. Rendez-vous
    print("\nCreation rendez-vous...")
    
    rdv_futur, _ = RendezVous.objects.get_or_create(
        patient_demandeur=patient,
        medecin_concerne=medecins[0],
        date_rdv=demain,
        heure_rdv=time(9, 30),
        defaults={'motif_consultation': "Douleur thoracique", 'statut_actuel_rdv': "confirme"}
    )
    
    hier = aujourdhui - timedelta(days=1)
    rdv_passe, _ = RendezVous.objects.get_or_create(
        patient_demandeur=patient,
        medecin_concerne=medecins[2],
        date_rdv=hier,
        heure_rdv=time(10, 0),
        defaults={'motif_consultation': "Consultation pediatrique", 'statut_actuel_rdv': "termine"}
    )
    
    print("3 rendez-vous crees")

    # 8. Consultation
    print("\nCreation consultation...")
    consultation, _ = Consultation.objects.get_or_create(
        rdv=rdv_passe,
        defaults={
            'diagnostic': "Examen pediatrique de routine. Enfant en bonne sante.",
            'actes_effectues': "Auscultation, pesee, mesure taille",
            'notes_medecin': "Aucune anomalie detectee."
        }
    )
    print("Consultation creee")

    # 9. Notifications
    print("\nCreation notifications...")
    Notification.objects.get_or_create(
        destinataire=patient_user,
        message="Votre rendez-vous de demain a 09h30 avec Dr Koffi est confirme.",
        defaults={'type_notification': 'RENDEZ_VOUS', 'lu': False}
    )
    print("Notifications creees")

    # 10. Resume
    print("\n" + "=" * 50)
    print("SEED TERMINE AVEC SUCCES !")
    print("=" * 50)
    print("\nCOMPTES DE TEST:")
    print("   PATIENT - Tel: 91770761 | Mdp: Romaric12345")
    print("   MEDECIN - Tel: 90000001 | Mdp: doctor123 (Cardiologie)")
    print("   MEDECIN - Tel: 90000002 | Mdp: doctor123 (Generaliste)")
    print("   MEDECIN - Tel: 90000003 | Mdp: doctor123 (Pediatrie)")
    print("=" * 50)


if __name__ == "__main__":
    run_seed()