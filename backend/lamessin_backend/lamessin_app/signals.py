from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Ordonnance, Commande, Notification,RendezVous

# Signal pour les nouvelles Ordonnances
@receiver(post_save, sender=Ordonnance)
def notification_nouvelle_ordonnance(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            destinataire=instance.patient_beneficiaire.compte_utilisateur,
            message=f"Nouvelle ordonnance disponible. Prescrite par Dr {instance.medecin_prescripteur.compte_utilisateur.last_name}.",
            type_notification="ORDONNANCE"
        )

# Signal pour les nouvelles Commandes
@receiver(post_save, sender=Commande)
def notification_nouvelle_commande(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            destinataire=instance.patient_acheteur.compte_utilisateur,
            message=f"Votre commande N°{instance.id} a été enregistrée. Statut : {instance.statut_commande}.",
            type_notification="COMMANDE"
        )
# Signal pour les Rendez-vous
@receiver(post_save, sender=RendezVous)
def notification_rendezvous(sender, instance, created, **kwargs):
    if created:
        # Notification à la création
        Notification.objects.create(
            destinataire=instance.patient_demandeur.compte_utilisateur,
            message=f"Votre rendez-vous avec le Dr {instance.medecin_concerne.compte_utilisateur.last_name} est enregistré pour le {instance.date_rdv} à {instance.heure_rdv}.",
            type_notification="RENDEZ_VOUS_CREE"
        )
    else:
        # Notification si le statut change (ex: de 'en_attente' à 'confirme')
        Notification.objects.create(
            destinataire=instance.patient_demandeur.compte_utilisateur,
            message=f"Le statut de votre rendez-vous du {instance.date_rdv} a été mis à jour : {instance.statut_actuel_rdv}.",
            type_notification="RENDEZ_VOUS_MAJ"
        )

# Signal pour les mises à jour de paiement (Confirmation)
@receiver(post_save, sender=Commande)
def notification_paiement_confirme(sender, instance, created, **kwargs):
    # On ne fait rien à la création, seulement à la modification
    if not created and instance.statut_commande.lower() == 'paye':
        Notification.objects.create(
            destinataire=instance.patient_acheteur.compte_utilisateur,
            message=f"Paiement confirmé pour la commande N°{instance.id}. Votre traitement est prêt !",
            type_notification="PAIEMENT_REUSSI"
        )