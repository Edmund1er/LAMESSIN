import os
import django
import random
from datetime import date, time, timedelta
from django.utils import timezone

# 1. Configuration Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lamessin_backend.settings')
django.setup()

from lamessin_app.models import (
    Utilisateur, Patient, Medecin, Pharmacien, Pharmacie, Hopital,
    Medicament, Stock, PlageHoraire, Notification, Chatbot,
    Traitement, Commande, LigneCommande, RendezVous, Consultation, Ordonnance, DetailOrdonnance, PriseMedicament
)


def run_seed():
    print("--- Début du Seed Complet LAMESSIN ---")

    # --- 1. NETTOYAGE (Optionnel : Décommente pour tout effacer avant de commencer) ---
    RendezVous.objects.all().delete()
    PlageHoraire.objects.all().delete()
    Consultation.objects.all().delete()
    Commande.objects.all().delete()
    Traitement.objects.all().delete()
    Ordonnance.objects.all().delete()
    print("Nettoyage des anciennes données de test (si activé)...")

    # --- 2. UTILISATEURS & PROFILS ---
    print("Création des utilisateurs (Patients, Médecins, Pharmaciens)...")

    # A. Patient Essodon (Utilisateur principal)
    essodon_user, _ = Utilisateur.objects.get_or_create(
        numero_telephone="91770761",
        defaults={
            'username': 'essodon',
            'email': 'essodon@lamessin.tg',
            'first_name': 'Essodon',
            'last_name': 'SESSOU',
            'est_un_compte_patient': True,
            'password': 'romaric12345'  # Note: set_password est mieux fait après
        }
    )
    essodon_user.set_password("Romaric12345")
    essodon_user.save()
    patient_essodon, _ = Patient.objects.get_or_create(
        compte_utilisateur=essodon_user,
        defaults={'groupe_sanguin': 'O+', 'date_naissance': date(1995, 5, 15)}
    )
    Chatbot.objects.get_or_create(utilisateur=essodon_user)

    # B. Création de 3 Médecins (Pour tester les filtres et RDV)
    medecins_data = [
        ("Koffi", "Mawuli", "Cardiologie", "LIC-001"),
        ("Adjovi", "Komi", "Généraliste", "LIC-002"),
        ("Mensa", "Akossiwa", "Pédiatrie", "LIC-003"),
    ]
    medecins_obj = []
    for nom, prenom, specialite, licence in medecins_data:
        user, _ = Utilisateur.objects.get_or_create(
            username=f"dr_{nom.lower()}",
            defaults={
                'email': f"dr.{nom.lower()}@lamessin.tg",
                'numero_telephone': f"9900{random.randint(10000, 99999)}",
                'first_name': prenom,
                'last_name': nom,
                'est_un_compte_medecin': True
            }
        )
        user.set_password("doctor123")
        user.save()

        med, _ = Medecin.objects.get_or_create(
            compte_utilisateur=user,
            defaults={'specialite_medicale': specialite, 'numero_licence': licence}
        )
        medecins_obj.append(med)

    # C. Pharmaciens (Liés aux pharmacies)
    pharmaciens_obj = []
    # On va créer les pharmaciens dans la section Pharmacie pour lier les objets

    # --- 3. ÉTABLISSEMENTS (Hôpitaux & Pharmacies) ---
    print("Création des établissements...")

    hopitaux_data = [
        ("CHR Lomé-Commune", "Lomé, Togo", "22210001", 6.13, 1.22),
        ("CHU Sylvanus Olympio", "Lomé, Tokoin", "22213451", 6.14, 1.23),
    ]
    for nom, adr, tel, lat, lon in hopitaux_data:
        Hopital.objects.get_or_create(
            nom=nom, defaults={
                'adresse': adr, 'contact': tel,
                'coordonnee_latitude_gps': lat, 'coordonnee_longitude_gps': lon,
                'plage_horaire_ouverture': "24h/24", 'type_urgences': "Générales",
                'liste_services': "Scanner, Radio, Chirurgie"
            }
        )

    pharmacies_data = [
        ("Pharmacie de la Paix", "Lomé, Deckon", "90112233", 6.131, 1.222),
        ("Pharmacie de l'Amitié", "Lomé, Assivito", "90445566", 6.132, 1.223),
    ]
    pharmacies_obj = []
    for nom, adr, tel, lat, lon in pharmacies_data:
        p, _ = Pharmacie.objects.get_or_create(
            nom=nom, defaults={
                'adresse': adr, 'contact': tel,
                'coordonnee_latitude_gps': lat, 'coordonnee_longitude_gps': lon,
                'plage_horaire_ouverture': "08h-22h", 'numero_paiement': tel, 'reseau_paiement': 'tmoney'
            }
        )
        pharmacies_obj.append(p)

        # Création d'un compte pharmacien pour cette pharmacie
        user_pharma, _ = Utilisateur.objects.get_or_create(
            username=f"pharma_{nom.split()[1].lower()}",
            defaults={
                'email': f"contact.{nom.split()[1].lower()}@pharma.tg",
                'numero_telephone': tel,
                'first_name': "Pharmacien",
                'last_name': nom.split()[1],
                'est_un_compte_pharmacien': True
            }
        )
        Pharmacien.objects.get_or_create(compte_utilisateur=user_pharma,
                                         defaults={'numero_licence': f"PH-{random.randint(100, 999)}"})

    # --- 4. MÉDICAMENTS & STOCKS ---
    print("Génération des médicaments et stocks...")
    meds_data = [
        ("Paracétamol 500mg", "Douleurs et fièvre", "1 comprimé 3 fois/jour", 150.00),
        ("Amoxicilline 1g", "Antibiotique large spectre", "1 gélule matin et soir", 3500.00),
        ("Artemether/Lumefantrine", "Traitement paludisme simple", "6 doses à 12h d'intervalle", 4500.00),
        ("Sirop Toux Enfant", "Toux grasse", "1 cuillère matin/midi/soir", 2800.00),
        ("Vitamines C 1000mg", "Fatigue", "1 comprimé le matin", 1200.00),
    ]
    medicaments_obj = []
    for nom, desc, poso, prix in meds_data:
        m, _ = Medicament.objects.get_or_create(
            nom_commercial=nom, defaults={'description': desc, 'posologie_standard': poso, 'prix_vente': prix}
        )
        medicaments_obj.append(m)

        # Ajouter du stock dans chaque pharmacie
        for phar in pharmacies_obj:
            Stock.objects.get_or_create(
                produit_concerne=m, pharmacie_detentrice=phar,
                defaults={'quantite_actuelle_en_stock': random.randint(20, 100), 'seuil_alerte': 10,
                          'date_peremption': date(2027, 12, 31)}
            )

    # --- 5. PLAGES HORAIRES (CRITIQUE POUR LA PRISE DE RDV) ---
    print("Création des plages horaires (Disponibilités)...")
    demain = date.today() + timedelta(days=1)
    apres_demain = date.today() + timedelta(days=2)

    # Plages pour Dr Koffi (Cardiologie)
    PlageHoraire.objects.get_or_create(
        medecin=medecins_obj[0], date=demain, heure_debut=time(8, 0), heure_fin=time(12, 0),
        defaults={'duree_consultation': 30}
    )
    PlageHoraire.objects.get_or_create(
        medecin=medecins_obj[0], date=apres_demain, heure_debut=time(14, 0), heure_fin=time(18, 0),
        defaults={'duree_consultation': 30}
    )

    # Plages pour Dr Adjovi (Généraliste)
    PlageHoraire.objects.get_or_create(
        medecin=medecins_obj[1], date=demain, heure_debut=time(9, 0), heure_fin=time(13, 0),
        defaults={'duree_consultation': 15}
    )

    # --- 6. RENDEZ-VOUS (Passé & Futur) ---
    print("Création de rendez-vous (Historique et Futur)...")

    # RDV Futur (Demain avec Dr Koffi)
    rdv_futur, _ = RendezVous.objects.get_or_create(
        patient_demandeur=patient_essodon,
        medecin_concerne=medecins_obj[0],
        date_rdv=demain,
        heure_rdv=time(9, 30),  # Doit être dans la plage 08:00-12:00
        defaults={'motif_consultation': "Douleur thoracique", 'statut_actuel_rdv': "en_attente"}
    )

    # RDV Passé (Hier avec Dr Mensah)
    hier = date.today() - timedelta(days=1)
    rdv_passe, _ = RendezVous.objects.get_or_create(
        patient_demandeur=patient_essodon,
        medecin_concerne=medecins_obj[2],
        date_rdv=hier,
        heure_rdv=time(10, 0),
        defaults={'motif_consultation': "Bilan annuel", 'statut_actuel_rdv': "termine"}
    )

    # --- 7. CONSULTATION & ORDONNANCE (Lier au RDV Passé) ---
    print("Création d'ordonnances et consultations...")
    consultation, _ = Consultation.objects.get_or_create(
        rdv=rdv_passe,
        defaults={
            'diagnostic': "Etat de santé général satisfaisant, légère fatigue.",
            'actes_effectues': "Auscultation, Prise de tension",
            'notes_medecin': "Revoir dans 6 mois."
        }
    )

    ordonnance, _ = Ordonnance.objects.get_or_create(
        consultation=consultation,
        medecin_prescripteur=medecins_obj[2],
        patient_beneficiaire=patient_essodon,
        defaults={'code_securite': 'ORD-2026-X7'}
    )

    # Ajouter des médicaments à l'ordonnance
    DetailOrdonnance.objects.get_or_create(
        ordonnance=ordonnance,
        medicament=medicaments_obj[3],  # Sirop Toux
        defaults={
            'quantite_boites': 1, 'posologie_specifique': "1 cuillère le soir si toux", 'duree_traitement_jours': 5
        }
    )
    DetailOrdonnance.objects.get_or_create(
        ordonnance=ordonnance,
        medicament=medicaments_obj[4],  # Vitamines
        defaults={
            'quantite_boites': 2, 'posologie_specifique': "1 le matin", 'duree_traitement_jours': 30
        }
    )

    # --- 8. TRAITEMENTS ---
    print("Création de traitements en cours...")
    # Traitement lié à l'ordonnance
    t1, _ = Traitement.objects.get_or_create(
        patient_concerne=patient_essodon,
        nom_du_traitement="Cure Vitamine C",
        defaults={
            'ordonnance_origine': ordonnance,
            'date_debut_traitement': date.today(),
            'date_fin_traitement': date.today() + timedelta(days=30)
        }
    )
    # Créer des prises pour ce traitement
    PriseMedicament.objects.get_or_create(
        traitement=t1, heure_prise_prevue=time(8, 0),
        defaults={'prise_effectuee': True, 'date_prise_reelle': date.today()}
    )
    PriseMedicament.objects.get_or_create(
        traitement=t1, heure_prise_prevue=time(8, 0),
        # Pour le lendemain, pas encore pris
        defaults={'prise_effectuee': False, 'date_prise_reelle': None}
    )

    # Traitement sans ordonnance directe
    Traitement.objects.get_or_create(
        patient_concerne=patient_essodon,
        nom_du_traitement="Surveillance tension",
        defaults={
            'date_debut_traitement': date.today() - timedelta(days=10),
            'date_fin_traitement': date.today() + timedelta(days=20)
        }
    )

    # --- 9. COMMANDES ---
    print("Création de commandes...")
    cmd_payee, created = Commande.objects.get_or_create(
        patient=patient_essodon,
        statut='PAYE',
        defaults={
            'total': 5150.00,
            'methode_retrait': 'RETRAIT',
            'transaction_id': 'CINET-PAY-8877',
            'date_creation': timezone.now() - timedelta(days=2)
        }
    )
    if created:
        LigneCommande.objects.create(
            commande=cmd_payee, produit=medicaments_obj[0],
            pharmacie=pharmacies_obj[0], quantite=1, prix_unitaire=150.00
        )
        LigneCommande.objects.create(
            commande=cmd_payee, produit=medicaments_obj[1],
            pharmacie=pharmacies_obj[0], quantite=1, prix_unitaire=5000.00
        )

    # Commande en attente
    cmd_attente, _ = Commande.objects.get_or_create(
        patient=patient_essodon,
        statut='EN_ATTENTE',
        defaults={
            'total': 2800.00,
            'methode_retrait': 'LIVRAISON',
            'transaction_id': None
        }
    )
    if created:
        LigneCommande.objects.create(
            commande=cmd_attente, produit=medicaments_obj[3],
            pharmacie=pharmacies_obj[1], quantite=1, prix_unitaire=2800.00
        )

    # --- 10. NOTIFICATIONS ---
    print("Création de notifications...")
    Notification.objects.get_or_create(
        destinataire=essodon_user,
        message="Votre rendez-vous de demain à 09h30 est confirmé.",
        defaults={'type_notification': 'RENDEZ_VOUS', 'lu': False}
    )
    Notification.objects.get_or_create(
        destinataire=essodon_user,
        message="Votre commande #CINET-PAY-8877 a été livrée.",
        defaults={'type_notification': 'COMMANDE', 'lu': True}
    )

    print("--- Seed Terminé avec Succès ! ---")
    print(f"Connecte-toi avec : 91770761 / Romaric12345")
    print(f"Tu devrais voir {medecins_obj.count} médecins et des créneaux disponibles pour {demain}.")


if __name__ == "__main__":
    run_seed()