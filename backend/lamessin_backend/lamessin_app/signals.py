from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Ordonnance, Commande, Notification, RendezVous
from firebase_admin import messaging

# --- FONCTION UTILITAIRE POUR L'ENVOI PUSH ---
def envoyer_push_notification(user, titre, message):
    if user.fcm_token:
        try:
            # Construction du message pour Android
            message_fcm = messaging.Message(
                notification=messaging.Notification(
                    title=titre,
                    body=message,
                ),
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        default_vibrate_timings=True, # Active la vibration par défaut
                    ),
                ),
                token=user.fcm_token,
            )
            messaging.send(message_fcm)
        except Exception as e:
            print(f"Erreur lors de l'envoi FCM : {e}")
# --- TES SIGNAUX MIS À JOUR ---

@receiver(post_save, sender=Ordonnance)
def notification_nouvelle_ordonnance(sender, instance, created, **kwargs):
    if created:
        msg = f"Nouvelle ordonnance disponible. Prescrite par Dr {instance.medecin_prescripteur.compte_utilisateur.last_name}."
        Notification.objects.create(
            destinataire=instance.patient_beneficiaire.compte_utilisateur,
            message=msg,
            type_notification="ORDONNANCE"
        )
        # ENVOI PUSH
        envoyer_push_notification(instance.patient_beneficiaire.compte_utilisateur, "💊 Nouvelle Ordonnance", msg)

@receiver(post_save, sender=RendezVous)
def notification_rendezvous(sender, instance, created, **kwargs):
    user = instance.patient_demandeur.compte_utilisateur
    if created:
        msg = f"RDV enregistré avec le Dr {instance.medecin_concerne.compte_utilisateur.last_name} pour le {instance.date_rdv}."
        Notification.objects.create(destinataire=user, message=msg, type_notification="RENDEZ_VOUS_CREE")
        envoyer_push_notification(user, "📅 Rendez-vous enregistré", msg)
    else:
        msg = f"Statut de votre RDV du {instance.date_rdv} : {instance.statut_actuel_rdv}."
        Notification.objects.create(destinataire=user, message=msg, type_notification="RENDEZ_VOUS_MAJ")
        envoyer_push_notification(user, "📅 Mise à jour Rendez-vous", msg)

# Fais la même chose pour Commande et Paiement...