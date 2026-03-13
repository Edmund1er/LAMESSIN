import os
import django
import random
from datetime import date, time, timedelta

# 1. Configuration Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lamessin_backend.settings')
django.setup()

from lamessin_app.models import (
    Utilisateur, Patient, Medecin, Pharmacien, Pharmacie, Hopital,
    Medicament, Stock, PlageHoraire, Notification, Chatbot
)


def run_seed():
    print("--- Début du Seed Massif ---")

    specialites = [
        "Cardiologue", "Pédiatre", "Dentiste",
        "Gynécologue", "Dermatologue", "Généraliste"
    ]

    noms_famille = ["ADJO", "TCHAKONDO", "GNAZO", "LAWSON", "AZIABLE", "KOFFI", "MENSAH", "SOSSOU"]
    prenoms = ["Marc", "Sophie", "Jean", "Afi", "Koffi", "Amé", "Yao", "Pouwèdéou"]

    # --- 1. CRÉATION DES MÉDECINS (24 au total) ---
    compteur = 1
    for spec in specialites:
        for i in range(4):  # 4 médecins par spécialité
            nom = random.choice(noms_famille)
            prenom = random.choice(prenoms)
            tel = f"9900{compteur:04d}"
            username = f"doc_{compteur}"

            user, _ = Utilisateur.objects.get_or_create(
                numero_telephone=tel,
                defaults={
                    'username': username,
                    'email': f"{username}@lamessin.tg",
                    'first_name': prenom,
                    'last_name': nom,
                    'est_un_compte_medecin': True
                }
            )
            user.set_password("Romaric12345")
            user.save()

            med, _ = Medecin.objects.get_or_create(
                compte_utilisateur=user,
                defaults={'specialite_medicale': spec, 'numero_licence': f"LIC-{tel}"}
            )

            # --- 2. GÉNÉRATION DES CRÉNEAUX (Chaque 2 jours jusqu'en Juillet) ---
            aujourdhui = date.today()
            fin_juillet = date(2026, 7, 31)
            delta_jours = (fin_juillet - aujourdhui).days

            for j in range(0, delta_jours, 2):  # Boucle tous les 2 jours
                date_creneau = aujourdhui + timedelta(days=j)
                # On crée 3 créneaux par jour de travail
                for h in [9, 11, 15]:
                    PlageHoraire.objects.get_or_create(
                        medecin=med,
                        date=date_creneau,
                        heure_debut=time(h, 0),
                        heure_fin=time(h + 1, 0),
                        defaults={'duree_consultation': 60}
                    )
            compteur += 1
            print(f"Médecin {nom} ({spec}) et ses créneaux créés.")

    # --- 3. CRÉATION DES PATIENTS & CHATBOTS ---
    # On s'assure qu'Essodon existe et a son Chatbot
    essodon_user, _ = Utilisateur.objects.get_or_create(
        numero_telephone="91770761",
        defaults={'username': 'essodon', 'first_name': 'Essodon', 'last_name': 'SESSOU', 'est_un_compte_patient': True}
    )
    essodon_user.set_password("Romaric12345")
    essodon_user.save()

    Patient.objects.get_or_create(compte_utilisateur=essodon_user, defaults={'groupe_sanguin': 'O+'})

    # CRUCIAL : Création automatique du Chatbot pour éviter l'erreur 500
    Chatbot.objects.get_or_create(utilisateur=essodon_user)

    print("--- Seed terminé avec succès ! ---")


if __name__ == "__main__":
    run_seed()