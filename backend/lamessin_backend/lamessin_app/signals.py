from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Ordonnance, Commande, Notification, RendezVous, Consultation, Stock
from firebase_admin import messaging


# ====================================================================================================
# FONCTION UTILITAIRE POUR L'ENVOI PUSH NOTIFICATION
# ====================================================================================================

def envoyer_push_notification(user, titre, message):
    """
    Envoie une notification push FCM à un utilisateur
    """
    if user and hasattr(user, 'fcm_token') and user.fcm_token:
        try:
            message_fcm = messaging.Message(
                notification=messaging.Notification(
                    title=titre,
                    body=message,
                ),
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        default_vibrate_timings=True,
                    ),
                ),
                token=user.fcm_token,
            )
            messaging.send(message_fcm)
            print(f" Push envoyé à {user.username}: {titre}")
        except Exception as e:
            print(f" Erreur FCM: {e}")


# ====================================================================================================
# SIGNAL : ORDONNANCE (Patient uniquement)
# ====================================================================================================

@receiver(post_save, sender=Ordonnance)
def notification_nouvelle_ordonnance(sender, instance, created, **kwargs):
    if created:
        medecin_nom = instance.medecin_prescripteur.compte_utilisateur.last_name
        msg = f"Nouvelle ordonnance disponible. Prescrite par Dr {medecin_nom}."

        Notification.objects.create(
            destinataire=instance.patient_beneficiaire.compte_utilisateur,
            message=msg,
            type_notification="ORDONNANCE"
        )

        envoyer_push_notification(
            instance.patient_beneficiaire.compte_utilisateur,
            " Nouvelle Ordonnance",
            msg
        )


# ====================================================================================================
# SIGNAL : RENDEZ-VOUS (Patient uniquement)
# ====================================================================================================

@receiver(post_save, sender=RendezVous)
def notification_rendezvous(sender, instance, created, **kwargs):
    user = instance.patient_demandeur.compte_utilisateur
    medecin_nom = instance.medecin_concerne.compte_utilisateur.last_name

    if created:
        msg = f"Rendez-vous enregistré avec le Dr {medecin_nom} pour le {instance.date_rdv} à {instance.heure_rdv}."

        Notification.objects.create(
            destinataire=user,
            message=msg,
            type_notification="RENDEZ_VOUS_CREE"
        )

        envoyer_push_notification(user, " Rendez-vous enregistré", msg)

    else:
        msg = f"Le statut de votre rendez-vous du {instance.date_rdv} a été mis à jour : {instance.statut_actuel_rdv}."

        Notification.objects.create(
            destinataire=user,
            message=msg,
            type_notification="RENDEZ_VOUS_MAJ"
        )

        envoyer_push_notification(user, " Mise à jour Rendez-vous", msg)


# ====================================================================================================
# SIGNAL : COMMANDE (Patient uniquement)
# ====================================================================================================

@receiver(post_save, sender=Commande)
def notification_commande(sender, instance, created, **kwargs):
    user = instance.patient.compte_utilisateur

    if created:
        msg = f"Votre commande n°{instance.id} a été créée avec succès. Montant : {instance.total} FCFA."

        Notification.objects.create(
            destinataire=user,
            message=msg,
            type_notification="COMMANDE_CREEE"
        )

        envoyer_push_notification(user, "🛒 Commande créée", msg)

    else:
        if instance.statut == 'PAYE':
            msg = f"Le paiement de votre commande n°{instance.id} a été confirmé. Merci pour votre confiance."

            Notification.objects.create(
                destinataire=user,
                message=msg,
                type_notification="PAIEMENT_VALIDE"
            )

            envoyer_push_notification(user, " Paiement confirmé", msg)

        elif instance.statut == 'ANNULE':
            msg = f"Votre commande n°{instance.id} a été annulée."

            Notification.objects.create(
                destinataire=user,
                message=msg,
                type_notification="COMMANDE_ANNULEE"
            )

            envoyer_push_notification(user, " Commande annulée", msg)

        elif instance.statut == 'LIVRE':
            msg = f"Votre commande n°{instance.id} est prête. Vous pouvez venir la retirer."

            Notification.objects.create(
                destinataire=user,
                message=msg,
                type_notification="COMMANDE_LIVREE"
            )

            envoyer_push_notification(user, " Commande prête", msg)


# ====================================================================================================
# SIGNAL : CONSULTATION (Patient + Médecin)
# ====================================================================================================

@receiver(post_save, sender=Consultation)
def notification_consultation(sender, instance, created, **kwargs):
    if created:
        patient_nom = instance.rdv.patient_demandeur.compte_utilisateur.last_name
        medecin_nom = instance.rdv.medecin_concerne.compte_utilisateur.last_name

        msg_patient = f"Votre consultation avec le Dr {medecin_nom} a été enregistrée. Vous pouvez consulter votre compte-rendu."

        Notification.objects.create(
            destinataire=instance.rdv.patient_demandeur.compte_utilisateur,
            message=msg_patient,
            type_notification="CONSULTATION_CREEE"
        )

        envoyer_push_notification(
            instance.rdv.patient_demandeur.compte_utilisateur,
            " Consultation enregistrée",
            msg_patient
        )

        msg_medecin = f"Consultation avec {patient_nom} enregistrée avec succès."

        Notification.objects.create(
            destinataire=instance.rdv.medecin_concerne.compte_utilisateur,
            message=msg_medecin,
            type_notification="CONSULTATION_CREEE"
        )

        envoyer_push_notification(
            instance.rdv.medecin_concerne.compte_utilisateur,
            " Consultation enregistrée",
            msg_medecin
        )


# ====================================================================================================
# SIGNAL : ALERTE STOCK (Pharmacien uniquement)
# ====================================================================================================

@receiver(post_save, sender=Stock)
def notification_alerte_stock(sender, instance, created, **kwargs):
    """
    Notification au pharmacien quand un stock est bas ou en rupture
    Déclenché à chaque création OU mise à jour du stock
    """
    print(f"SIGNAL STOCK - Produit: {instance.produit_concerne.nom_commercial}, Quantite: {instance.quantite_actuelle_en_stock}, Seuil: {instance.seuil_alerte}")

    if instance.quantite_actuelle_en_stock <= instance.seuil_alerte:
        print(f" ALERTE STOCK DETECTEE!")

        try:
            pharmacien = instance.pharmacie_detentrice.pharmacien_set.first()
            if pharmacien:
                if instance.quantite_actuelle_en_stock == 0:
                    niveau = "RUPTURE DE STOCK"
                else:
                    niveau = "STOCK FAIBLE"

                msg = f"{niveau} : {instance.produit_concerne.nom_commercial} - Stock actuel: {instance.quantite_actuelle_en_stock} (Seuil: {instance.seuil_alerte})"

                Notification.objects.create(
                    destinataire=pharmacien.compte_utilisateur,
                    message=msg,
                    type_notification="ALERTE_STOCK"
                )

                envoyer_push_notification(
                    pharmacien.compte_utilisateur,
                    f" {niveau}",
                    msg
                )
                print(f" Notification stock créée")
            else:
                print(f"Aucun pharmacien trouvé")
        except Exception as e:
            print(f" Erreur: {e}")


# ====================================================================================================
# SIGNAL : NOUVELLE COMMANDE POUR PHARMACIEN
# ====================================================================================================

@receiver(post_save, sender=Commande)
def notification_nouvelle_commande_pharmacien(sender, instance, created, **kwargs):
    if created:
        print(f" NOUVELLE COMMANDE - ID: {instance.id}")

        pharmacies = set()
        for ligne in instance.lignes.all():
            pharmacies.add(ligne.pharmacie)

        for pharmacie in pharmacies:
            try:
                pharmacien = pharmacie.pharmacien_set.first()
                if pharmacien:
                    msg = f"Nouvelle commande n°{instance.id} - Patient: {instance.patient.compte_utilisateur.last_name} - Montant: {instance.total} FCFA"

                    Notification.objects.create(
                        destinataire=pharmacien.compte_utilisateur,
                        message=msg,
                        type_notification="NOUVELLE_COMMANDE"
                    )

                    envoyer_push_notification(
                        pharmacien.compte_utilisateur,
                        " Nouvelle commande",
                        msg
                    )
            except Exception as e:
                print(f" Erreur: {e}")


# ====================================================================================================
# SIGNAL : RENDEZ-VOUS POUR MÉDECIN
# ====================================================================================================

@receiver(post_save, sender=RendezVous)
def notification_nouveau_rdv_medecin(sender, instance, created, **kwargs):
    if created:
        patient_nom = instance.patient_demandeur.compte_utilisateur.last_name
        msg = f"Nouveau rendez-vous avec {patient_nom} le {instance.date_rdv} à {instance.heure_rdv}"

        Notification.objects.create(
            destinataire=instance.medecin_concerne.compte_utilisateur,
            message=msg,
            type_notification="NOUVEAU_RDV"
        )

        envoyer_push_notification(
            instance.medecin_concerne.compte_utilisateur,
            " Nouveau rendez-vous",
            msg
        )