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

    # 1. Nettoyage des donnees de test (pas les comptes utilisateurs)
    print("\nNettoyage des donnees de test...")
    RendezVous.objects.all().delete()
    PlageHoraire.objects.all().delete()
    Consultation.objects.all().delete()
    Commande.objects.all().delete()
    LigneCommande.objects.all().delete()
    Traitement.objects.all().delete()
    PriseMedicament.objects.all().delete()
    Ordonnance.objects.all().delete()
    DetailOrdonnance.objects.all().delete()
    Notification.objects.all().delete()
    print("Nettoyage termine")

    # 2. Patient existant (ne pas modifier)
    print("\nVerification du patient...")
    try:
        patient_user = Utilisateur.objects.get(numero_telephone="91770761")
        print(f"Patient existant: {patient_user.last_name}")
    except Utilisateur.DoesNotExist:
        patient_user = Utilisateur.objects.create_user(
            username="patient_sessou",
            numero_telephone="91770761",
            email="essodon@lamessin.tg",
            password="Romaric12345",
            first_name="Essodon",
            last_name="SESSOU",
            est_un_compte_patient=True
        )
        print(f"Patient cree: {patient_user.last_name}")

    patient, _ = Patient.objects.get_or_create(
        compte_utilisateur=patient_user,
        defaults={'groupe_sanguin': 'O+', 'date_naissance': date(1995, 5, 15)}
    )
    Chatbot.objects.get_or_create(utilisateur=patient_user)

    # 3. Medecins existants (ne pas modifier)
    print("\nVerification des medecins...")
    medecins_data = [
        {"tel": "90000001", "user": "dr_koffi", "nom": "Koffi", "prenom": "Mawuli", "specialite": "Cardiologie", "licence": "MED001"},
        {"tel": "90000002", "user": "dr_adjovi", "nom": "Adjovi", "prenom": "Komi", "specialite": "Generaliste", "licence": "MED002"},
        {"tel": "90000003", "user": "dr_mensa", "nom": "Mensa", "prenom": "Akossiwa", "specialite": "Pediatrie", "licence": "MED003"},
    ]

    medecins = []
    for data in medecins_data:
        try:
            user = Utilisateur.objects.get(numero_telephone=data["tel"])
            print(f"Medecin existant: Dr {user.last_name}")
        except Utilisateur.DoesNotExist:
            user = Utilisateur.objects.create_user(
                username=data["user"],
                numero_telephone=data["tel"],
                email=f"{data['user']}@lamessin.tg",
                password="doctor123",
                first_name=data["prenom"],
                last_name=data["nom"],
                est_un_compte_medecin=True
            )
            print(f"Medecin cree: Dr {user.last_name}")

        med, _ = Medecin.objects.get_or_create(
            compte_utilisateur=user,
            defaults={
                'specialite_medicale': data["specialite"],
                'numero_licence': data["licence"]
            }
        )
        medecins.append(med)

    # 4. Pharmacies existantes
    print("\nVerification des pharmacies...")
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
        print(f"Pharmacie: {pharm.nom}")

    # 5. Medicaments
    print("\nCreation des medicaments...")
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

    # 6. Plages horaires - Tous les 2 jours jusqu'au 30 juillet 2026
    print("\nCreation des plages horaires (tous les 2 jours jusqu'au 30/07/2026)...")

    aujourdhui = date.today()
    date_fin = date(2026, 7, 30)  # 30 juillet 2026

    dates_disponibles = []
    current_date = aujourdhui
    while current_date <= date_fin:
        dates_disponibles.append(current_date)
        current_date += timedelta(days=2)

    print(f"Plages horaires du {aujourdhui} au {date_fin} ({len(dates_disponibles)} jours)")

    plages_crees = 0
    for d in dates_disponibles:
        # Dr Koffi (Cardiologie) - Matin
        PlageHoraire.objects.get_or_create(
            medecin=medecins[0], date=d, heure_debut=time(8, 0), heure_fin=time(12, 0),
            defaults={'duree_consultation': 30}
        )
        plages_crees += 1

        # Dr Koffi (Cardiologie) - Apres-midi
        PlageHoraire.objects.get_or_create(
            medecin=medecins[0], date=d, heure_debut=time(14, 0), heure_fin=time(18, 0),
            defaults={'duree_consultation': 30}
        )
        plages_crees += 1

        # Dr Adjovi (Generaliste)
        PlageHoraire.objects.get_or_create(
            medecin=medecins[1], date=d, heure_debut=time(9, 0), heure_fin=time(13, 0),
            defaults={'duree_consultation': 20}
        )
        plages_crees += 1

        # Dr Mensa (Pediatrie)
        PlageHoraire.objects.get_or_create(
            medecin=medecins[2], date=d, heure_debut=time(10, 0), heure_fin=time(14, 0),
            defaults={'duree_consultation': 25}
        )
        plages_crees += 1

    print(f"{plages_crees} plages horaires creees")

    # 7. Rendez-vous de test
    print("\nCreation des rendez-vous de test...")

    # RDV futur (dans 2 jours)
    rdv_futur = RendezVous.objects.create(
        patient_demandeur=patient,
        medecin_concerne=medecins[0],
        date_rdv=aujourdhui + timedelta(days=2),
        heure_rdv=time(9, 30),
        motif_consultation="Douleur thoracique",
        statut_actuel_rdv="confirme"
    )

    # RDV passe (hier)
    rdv_passe = RendezVous.objects.create(
        patient_demandeur=patient,
        medecin_concerne=medecins[2],
        date_rdv=aujourdhui - timedelta(days=1),
        heure_rdv=time(10, 0),
        motif_consultation="Consultation pediatrique",
        statut_actuel_rdv="termine"
    )

    # RDV en attente (dans 3 jours)
    rdv_attente = RendezVous.objects.create(
        patient_demandeur=patient,
        medecin_concerne=medecins[1],
        date_rdv=aujourdhui + timedelta(days=3),
        heure_rdv=time(11, 0),
        motif_consultation="Consultation generale",
        statut_actuel_rdv="en_attente"
    )

    print("3 rendez-vous crees (passe, futur, en attente)")

    # 8. Consultation pour le RDV passe
    print("\nCreation de la consultation...")
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
    print("\nCreation des notifications...")
    Notification.objects.get_or_create(
        destinataire=patient_user,
        message="Votre rendez-vous de demain a 09h30 avec Dr Koffi est confirme.",
        defaults={'type_notification': 'RENDEZ_VOUS', 'lu': False}
    )
    print("Notifications creees")

    # 10. Creation du pharmacien (AJOUT)
    print("\nCreation du pharmacien...")
    try:
        pharmacien_user = Utilisateur.objects.get(numero_telephone="90123456")
        print(f"Pharmacien existant: {pharmacien_user.last_name}")
    except Utilisateur.DoesNotExist:
        pharmacien_user = Utilisateur.objects.create_user(
            username="pharmacien_central",
            numero_telephone="90123456",
            email="pharmacien@lamessin.tg",
            password="Pharmacien123",
            first_name="Jean",
            last_name="DUPONT",
            est_un_compte_pharmacien=True
        )
        print(f"Pharmacien cree: {pharmacien_user.last_name}")

    # Associer le pharmacien a une pharmacie
    premiere_pharmacie = pharmacies[0] if pharmacies else None
    pharmacien, _ = Pharmacien.objects.get_or_create(
        compte_utilisateur=pharmacien_user,
        defaults={
            'numero_licence': "PHARM-001",
            'pharmacie': premiere_pharmacie
        }
    )
    if pharmacien.pharmacie:
        print(f"Pharmacien associe a: {pharmacien.pharmacie.nom}")
    else:
        print("Attention: Aucune pharmacie associee au pharmacien!")

    # 11. Resume final
    print("\n" + "=" * 50)
    print("SEED TERMINE AVEC SUCCES !")
    print("=" * 50)
    print("\nCOMPTES DE TEST:")
    print("   PATIENT - Tel: 91770761 | Mdp: Romaric12345")
    print("   MEDECIN - Tel: 90000001 | Mdp: doctor123 (Cardiologie)")
    print("   MEDECIN - Tel: 90000002 | Mdp: doctor123 (Generaliste)")
    print("   MEDECIN - Tel: 90000003 | Mdp: doctor123 (Pediatrie)")
    print("   PHARMACIEN - Tel: 90123456 | Mdp: Pharmacien123")
    print("\nPHARMACIES:")
    for p in pharmacies:
        print(f"   - {p.nom} (Tel: {p.contact})")
    print("\nPLAGES HORAIRES:")
    print(f"   - Tous les 2 jours du {aujourdhui} au 2026-07-30")
    print("   - 4 creneaux par jour par medecin")
    print("=" * 50)


if __name__ == "__main__":
    run_seed()