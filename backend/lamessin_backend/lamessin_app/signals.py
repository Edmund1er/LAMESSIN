from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Ordonnance, Commande, Notification, RendezVous
from firebase_admin import messaging


# --- FONCTION UTILITAIRE POUR L'ENVOI PUSH ---
def envoyer_push_notification(user, titre, message):
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
        except Exception as e:
            print(f"Erreur lors de l'envoi FCM : {e}")


# --- SIGNAUX POUR LES ORDONNANCES ---
@receiver(post_save, sender=Ordonnance)
def notification_nouvelle_ordonnance(sender, instance, created, **kwargs):
    if created:
        # Correction : On accède bien au last_name du compte_utilisateur du médecin
        msg = f"Nouvelle ordonnance disponible. Prescrite par Dr {instance.medecin_prescripteur.compte_utilisateur.last_name}."
        Notification.objects.create(
            destinataire=instance.patient_beneficiaire.compte_utilisateur,
            message=msg,
            type_notification="ORDONNANCE"
        )
        envoyer_push_notification(instance.patient_beneficiaire.compte_utilisateur, "Nouvelle Ordonnance", msg)


# --- SIGNAUX POUR LES RENDEZ-VOUS ---
@receiver(post_save, sender=RendezVous)
def notification_rendezvous(sender, instance, created, **kwargs):
    # Correction : Le modèle RendezVous utilise 'patient_demandeur'
    user = instance.patient_demandeur.compte_utilisateur
    if created:
        msg = f"Rendez-vous enregistré avec le Dr {instance.medecin_concerne.compte_utilisateur.last_name} pour le {instance.date_rdv}."
        Notification.objects.create(destinataire=user, message=msg, type_notification="RENDEZ_VOUS_CREE")
        envoyer_push_notification(user, "Rendez-vous enregistre", msg)
    else:
        msg = f"Le statut de votre rendez-vous du {instance.date_rdv} a ete mis a jour : {instance.statut_actuel_rdv}."
        Notification.objects.create(destinataire=user, message=msg, type_notification="RENDEZ_VOUS_MAJ")
        envoyer_push_notification(user, "Mise a jour Rendez-vous", msg)


# --- SIGNAUX POUR LES COMMANDES ---
@receiver(post_save, sender=Commande)
def notification_commande(sender, instance, created, **kwargs):
    # Correction : Le modèle Commande utilise 'patient'
    user = instance.patient.compte_utilisateur
    if created:
        # Correction : On utilise 'total' (nom exact dans ton modèle)
        msg = f"Votre commande numero {instance.id} a ete creee avec succes. Montant : {instance.total} XOF."
        Notification.objects.create(destinataire=user, message=msg, type_notification="COMMANDE_CREEE")
        envoyer_push_notification(user, "Commande creee", msg)
    else:
        # Correction : On utilise 'statut' (nom exact dans ton modèle)
        # Note : Les choix dans ton modèle sont en MAJUSCULES ('PAYE', 'ANNULE')
        if instance.statut == 'PAYE':
            msg = f"Le paiement de votre commande numero {instance.id} a ete confirme. Merci pour votre confiance."
            Notification.objects.create(destinataire=user, message=msg, type_notification="PAIEMENT_VALIDE")
            envoyer_push_notification(user, "Paiement confirme", msg)

        elif instance.statut == 'ANNULE':
            msg = f"Votre commande numero {instance.id} a ete annulee."
            Notification.objects.create(destinataire=user, message=msg, type_notification="COMMANDE_ANNULEE")
            envoyer_push_notification(user, "Commande annulee", msg)