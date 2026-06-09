from django.contrib import admin
from django.utils.html import format_html
from django.db import models
from django.db.models import Count, Sum, Q
from django.db.models.functions import TruncMonth
from .models import *
from django.utils import timezone
from datetime import timedelta, date
from django.template.response import TemplateResponse
from django.urls import path
from django.contrib.admin.views.main import ChangeList


PERIODES = {
    '7j': ('7 derniers jours', 7),
    '30j': ('30 derniers jours', 30),
    '90j': ('90 derniers jours', 90),
    'all': ("Tout l'historique", None),
}


class LamessinAdminSite(admin.AdminSite):
    site_header = "LAMESSIN"
    site_title = "Administration LAMESSIN"
    index_title = "Tableau de bord"

    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path('rendezvous-calendrier/', self.admin_view(self.rendezvous_calendar_view), name='rendezvous_calendar'),
            path('statistiques/', self.admin_view(self.stats_full_view), name='stats_full'),
        ]
        return my_urls + urls

    def rendezvous_calendar_view(self, request):
        context = {
            **self.each_context(request),
            'title': 'Calendrier des rendez-vous',
            'cl': ChangeList(
                request, RendezVous,
                RendezVousAdmin.list_display,
                RendezVousAdmin.list_display_links,
                RendezVousAdmin.list_filter,
                RendezVousAdmin.date_hierarchy,
                RendezVousAdmin.search_fields,
                RendezVousAdmin.list_select_related,
                RendezVousAdmin.list_per_page,
                RendezVousAdmin.list_max_show_all,
                RendezVousAdmin.list_editable,
                RendezVousAdmin
            )
        }
        return TemplateResponse(request, 'admin/rendezvous_calendar.html', context)

    def stats_full_view(self, request):
        aujourdhui = timezone.now().date()
        periode_key = request.GET.get('periode', '30j')
        if periode_key not in PERIODES:
            periode_key = '30j'
        periode_label, periode_jours = PERIODES[periode_key]
        date_debut = aujourdhui - timedelta(days=periode_jours) if periode_jours else None

        n_points = min(periode_jours or 30, 30)
        evolution_labels, evolution_data = [], []
        for i in range(n_points - 1, -1, -1):
            d = aujourdhui - timedelta(days=i)
            evolution_labels.append(d.strftime('%d/%m'))
            evolution_data.append(RendezVous.objects.filter(date_rdv=d).count())

        date_il_y_a_un_an = aujourdhui - timedelta(days=365)
        ordo_par_mois = list(
            Ordonnance.objects
            .filter(date_prescription__gte=date_il_y_a_un_an)
            .annotate(mois=TruncMonth('date_prescription'))
            .values('mois')
            .annotate(total=Count('id'))
            .order_by('mois')
        )
        ordo_labels = [item['mois'].strftime('%b %Y') for item in ordo_par_mois]
        ordo_data = [item['total'] for item in ordo_par_mois]

        top_medicaments = list(
            DetailOrdonnance.objects
            .values('medicament__nom_commercial')
            .annotate(total=Count('id'))
            .order_by('-total')[:10]
        )
        top_medicaments_labels = [item['medicament__nom_commercial'] for item in top_medicaments]
        top_medicaments_data = [item['total'] for item in top_medicaments]

        cmd_qs = Commande.objects.all()
        ordo_qs = Ordonnance.objects.all()
        if date_debut:
            cmd_qs = cmd_qs.filter(date_creation__date__gte=date_debut)
            ordo_qs = ordo_qs.filter(date_prescription__gte=date_debut)

        revenus = cmd_qs.filter(statut='PAYE').aggregate(t=Sum('total'))['t'] or 0

        stats = {
            'periode_active': periode_key,
            'periode_label': periode_label,
            'periode_options': [(k, v[0]) for k, v in PERIODES.items()],
            'total_rdv': RendezVous.objects.count(),
            'total_patients': Utilisateur.objects.filter(est_un_compte_patient=True, is_active=True).count(),
            'total_medecins': Utilisateur.objects.filter(est_un_compte_medecin=True, is_active=True).count(),
            'commandes_total': cmd_qs.count(),
            'rdv_aujourdhui': RendezVous.objects.filter(date_rdv=aujourdhui).count(),
            'rdv_en_attente': RendezVous.objects.filter(statut_actuel_rdv='en_attente').count(),
            'rdv_confirme': RendezVous.objects.filter(statut_actuel_rdv='confirme').count(),
            'rdv_termine': RendezVous.objects.filter(statut_actuel_rdv='termine').count(),
            'rdv_annule': RendezVous.objects.filter(statut_actuel_rdv='annule').count(),
            'evolution_labels': evolution_labels,
            'evolution_data': evolution_data,
            'commandes_attente': cmd_qs.filter(statut='EN_ATTENTE').count(),
            'commandes_payees': cmd_qs.filter(statut='PAYE').count(),
            'commandes_livrees': cmd_qs.filter(statut='LIVRE').count(),
            'commandes_annulees': cmd_qs.filter(statut='ANNULE').count(),
            'revenus_periode': revenus,
            'total_pharmacies': Pharmacie.objects.count(),
            'pharmacies_garde': Pharmacie.objects.filter(pharmacie_est_garde=True).count(),
            'total_hopitaux': Hopital.objects.count(),
            'total_pharmaciens': Utilisateur.objects.filter(est_un_compte_pharmacien=True, is_active=True).count(),
            'total_consultations': Consultation.objects.count(),
            'total_ordonnances': ordo_qs.count(),
            'total_medicaments': Medicament.objects.count(),
            'stocks_alerte': Stock.objects.filter(quantite_actuelle_en_stock__lte=models.F('seuil_alerte')).count(),
            'ordo_labels': ordo_labels,
            'ordo_data': ordo_data,
            'top_medicaments_labels': top_medicaments_labels,
            'top_medicaments_data': top_medicaments_data,
        }

        context = {
            **self.each_context(request),
            'title': 'Tableau de bord - Statistiques',
            **stats,
        }
        return TemplateResponse(request, 'admin/stats_full.html', context)

    def index(self, request, extra_context=None):
        aujourdhui = timezone.now().date()
        periode_key = request.GET.get('periode', '30j')
        if periode_key not in PERIODES:
            periode_key = '30j'
        periode_label, periode_jours = PERIODES[periode_key]
        date_debut = aujourdhui - timedelta(days=periode_jours) if periode_jours else None

        n_points = min(periode_jours or 30, 30)
        evolution_labels, evolution_data = [], []
        for i in range(n_points - 1, -1, -1):
            d = aujourdhui - timedelta(days=i)
            evolution_labels.append(d.strftime('%d/%m'))
            evolution_data.append(RendezVous.objects.filter(date_rdv=d).count())

        date_il_y_a_un_an = aujourdhui - timedelta(days=365)
        ordo_par_mois = list(
            Ordonnance.objects
            .filter(date_prescription__gte=date_il_y_a_un_an)
            .annotate(mois=TruncMonth('date_prescription'))
            .values('mois')
            .annotate(total=Count('id'))
            .order_by('mois')
        )
        ordo_labels = [item['mois'].strftime('%b %Y') for item in ordo_par_mois]
        ordo_data = [item['total'] for item in ordo_par_mois]

        top_medicaments = list(
            DetailOrdonnance.objects
            .values('medicament__nom_commercial')
            .annotate(total=Count('id'))
            .order_by('-total')[:10]
        )

        cmd_qs = Commande.objects.all()
        ordo_qs = Ordonnance.objects.all()
        if date_debut:
            cmd_qs = cmd_qs.filter(date_creation__date__gte=date_debut)
            ordo_qs = ordo_qs.filter(date_prescription__gte=date_debut)

        revenus = cmd_qs.filter(statut='PAYE').aggregate(t=Sum('total'))['t'] or 0

        stats = {
            'periode_active': periode_key,
            'periode_label': periode_label,
            'periode_options': [(k, v[0]) for k, v in PERIODES.items()],
            'total_rdv': RendezVous.objects.count(),
            'total_patients': Utilisateur.objects.filter(est_un_compte_patient=True, is_active=True).count(),
            'total_medecins': Utilisateur.objects.filter(est_un_compte_medecin=True, is_active=True).count(),
            'commandes_total': cmd_qs.count(),
            'rdv_aujourdhui': RendezVous.objects.filter(date_rdv=aujourdhui).count(),
            'rdv_en_attente': RendezVous.objects.filter(statut_actuel_rdv='en_attente').count(),
            'rdv_confirme': RendezVous.objects.filter(statut_actuel_rdv='confirme').count(),
            'rdv_termine': RendezVous.objects.filter(statut_actuel_rdv='termine').count(),
            'rdv_annule': RendezVous.objects.filter(statut_actuel_rdv='annule').count(),
            'evolution_labels': evolution_labels,
            'evolution_data': evolution_data,
            'commandes_attente': cmd_qs.filter(statut='EN_ATTENTE').count(),
            'commandes_payees': cmd_qs.filter(statut='PAYE').count(),
            'commandes_livrees': cmd_qs.filter(statut='LIVRE').count(),
            'commandes_annulees': cmd_qs.filter(statut='ANNULE').count(),
            'revenus_periode': revenus,
            'total_pharmacies': Pharmacie.objects.count(),
            'pharmacies_garde': Pharmacie.objects.filter(pharmacie_est_garde=True).count(),
            'total_hopitaux': Hopital.objects.count(),
            'total_pharmaciens': Utilisateur.objects.filter(est_un_compte_pharmacien=True, is_active=True).count(),
            'total_consultations': Consultation.objects.count(),
            'total_ordonnances': ordo_qs.count(),
            'total_medicaments': Medicament.objects.count(),
            'stocks_alerte': Stock.objects.filter(quantite_actuelle_en_stock__lte=models.F('seuil_alerte')).count(),
            'ordo_labels': ordo_labels,
            'ordo_data': ordo_data,
            'top_medicaments': top_medicaments,
        }
        extra_context = {**stats, **(extra_context or {})}
        return super().index(request, extra_context=extra_context)


admin_site = LamessinAdminSite(name='lamessin_admin')


# ====================================================================================================
# UTILISATEURS
# ====================================================================================================

@admin.register(Utilisateur, site=admin_site)
class UtilisateurAdmin(admin.ModelAdmin):
    list_display = ('id', 'username', 'telephone', 'email', 'nom_complet', 'role')
    list_filter = ('est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien', 'is_active')
    search_fields = ('username', 'numero_telephone', 'email', 'first_name', 'last_name')
    list_per_page = 25

    fieldsets = (
        ('Informations personnelles', {
            'fields': ('username', 'first_name', 'last_name', 'email', 'numero_telephone')
        }),
        ('Type de compte', {
            'fields': ('est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien')
        }),
        ('Statut', {
            'fields': ('is_active', 'is_staff', 'is_superuser')
        }),
    )

    def telephone(self, obj):
        return obj.numero_telephone
    telephone.short_description = "Téléphone"
    telephone.admin_order_field = 'numero_telephone'

    def nom_complet(self, obj):
        return f"{obj.last_name} {obj.first_name}"
    nom_complet.short_description = "Nom complet"
    nom_complet.admin_order_field = 'last_name'

    def role(self, obj):
        if obj.est_un_compte_patient:
            return "Patient"
        if obj.est_un_compte_medecin:
            return "Médecin"
        if obj.est_un_compte_pharmacien:
            return "Pharmacien"
        return "Admin"
    role.short_description = "Rôle"


# ====================================================================================================
# PATIENTS
# ====================================================================================================

@admin.register(Patient, site=admin_site)
class PatientAdmin(admin.ModelAdmin):
    list_display = ('telephone', 'nom_complet', 'groupe_sanguin', 'date_naissance')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'compte_utilisateur__numero_telephone')
    raw_id_fields = ('compte_utilisateur',)
    list_per_page = 25

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations médicales', {
            'fields': ('date_naissance', 'groupe_sanguin', 'photo_profil')
        }),
    )

    def telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    telephone.short_description = "Téléphone"
    telephone.admin_order_field = 'compte_utilisateur__numero_telephone'

    def nom_complet(self, obj):
        return f"{obj.compte_utilisateur.last_name} {obj.compte_utilisateur.first_name}"
    nom_complet.short_description = "Nom complet"
    nom_complet.admin_order_field = 'compte_utilisateur__last_name'


# ====================================================================================================
# MÉDECINS
# ====================================================================================================

@admin.register(Medecin, site=admin_site)
class MedecinAdmin(admin.ModelAdmin):
    list_display = ('telephone', 'nom_complet', 'specialite_medicale', 'numero_licence')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'specialite_medicale', 'numero_licence')
    list_filter = ('specialite_medicale',)
    raw_id_fields = ('compte_utilisateur',)
    list_per_page = 25

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations professionnelles', {
            'fields': ('specialite_medicale', 'numero_licence', 'photo_profil')
        }),
    )

    def telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    telephone.short_description = "Téléphone"
    telephone.admin_order_field = 'compte_utilisateur__numero_telephone'

    def nom_complet(self, obj):
        return f"Dr {obj.compte_utilisateur.last_name} {obj.compte_utilisateur.first_name}"
    nom_complet.short_description = "Nom complet"
    nom_complet.admin_order_field = 'compte_utilisateur__last_name'


# ====================================================================================================
# PHARMACIENS
# ====================================================================================================

@admin.register(Pharmacien, site=admin_site)
class PharmacienAdmin(admin.ModelAdmin):
    list_display = ('telephone', 'nom_complet', 'pharmacie', 'numero_licence')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'pharmacie__nom')
    list_filter = ('pharmacie',)
    raw_id_fields = ('compte_utilisateur',)
    list_per_page = 25

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations professionnelles', {
            'fields': ('pharmacie', 'numero_licence')
        }),
    )

    def telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    telephone.short_description = "Téléphone"
    telephone.admin_order_field = 'compte_utilisateur__numero_telephone'

    def nom_complet(self, obj):
        return f"{obj.compte_utilisateur.last_name} {obj.compte_utilisateur.first_name}"
    nom_complet.short_description = "Nom complet"
    nom_complet.admin_order_field = 'compte_utilisateur__last_name'


# ====================================================================================================
# MÉDICAMENTS
# ====================================================================================================

@admin.register(Medicament, site=admin_site)
class MedicamentAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom_commercial', 'prix_vente')
    search_fields = ('nom_commercial',)
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('nom_commercial', 'description', 'posologie_standard', 'prix_vente', 'image_produit')
        }),
    )


# ====================================================================================================
# STOCKS
# ====================================================================================================

@admin.register(Stock, site=admin_site)
class StockAdmin(admin.ModelAdmin):
    list_display = ('medicament', 'pharmacie', 'quantite', 'statut', 'date_peremption')
    list_filter = ('pharmacie_detentrice',)
    raw_id_fields = ('produit_concerne',)
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('produit_concerne', 'pharmacie_detentrice', 'quantite_actuelle_en_stock', 'seuil_alerte', 'date_peremption')
        }),
    )

    def medicament(self, obj):
        return obj.produit_concerne.nom_commercial
    medicament.short_description = "Médicament"
    medicament.admin_order_field = 'produit_concerne__nom_commercial'

    def pharmacie(self, obj):
        return obj.pharmacie_detentrice.nom
    pharmacie.short_description = "Pharmacie"
    pharmacie.admin_order_field = 'pharmacie_detentrice__nom'

    def quantite(self, obj):
        return f"{obj.quantite_actuelle_en_stock} unités"
    quantite.short_description = "Quantité"

    def statut(self, obj):
        if obj.quantite_actuelle_en_stock == 0:
            return "Rupture"
        if obj.quantite_actuelle_en_stock <= obj.seuil_alerte:
            return "Alerte"
        return "OK"
    statut.short_description = "Statut"


# ====================================================================================================
# RENDEZ-VOUS
# ====================================================================================================

@admin.register(RendezVous, site=admin_site)
class RendezVousAdmin(admin.ModelAdmin):
    list_display = ('patient', 'medecin', 'date_rdv', 'heure_rdv', 'motif', 'statut')
    list_filter = ('statut_actuel_rdv', 'date_rdv', 'medecin_concerne')
    date_hierarchy = 'date_rdv'
    raw_id_fields = ('patient_demandeur', 'medecin_concerne')
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('patient_demandeur', 'medecin_concerne', 'date_rdv', 'heure_rdv', 'motif_consultation', 'statut_actuel_rdv')
        }),
    )

    def patient(self, obj):
        return f"{obj.patient_demandeur.compte_utilisateur.last_name} {obj.patient_demandeur.compte_utilisateur.first_name}"
    patient.short_description = "Patient"
    patient.admin_order_field = 'patient_demandeur__compte_utilisateur__last_name'

    def medecin(self, obj):
        return f"Dr {obj.medecin_concerne.compte_utilisateur.last_name}"
    medecin.short_description = "Médecin"
    medecin.admin_order_field = 'medecin_concerne__compte_utilisateur__last_name'

    def motif(self, obj):
        return obj.motif_consultation[:50] + "..." if len(obj.motif_consultation) > 50 else obj.motif_consultation
    motif.short_description = "Motif"

    def statut(self, obj):
        statuts = {
            'en_attente': 'En attente',
            'confirme': 'Confirmé',
            'annule': 'Annulé',
            'termine': 'Terminé',
            'expire': 'Expiré'
        }
        return statuts.get(obj.statut_actuel_rdv, obj.statut_actuel_rdv)
    statut.short_description = "Statut"


# ====================================================================================================
# CONSULTATIONS
# ====================================================================================================

@admin.register(Consultation, site=admin_site)
class ConsultationAdmin(admin.ModelAdmin):
    list_display = ('patient', 'medecin', 'date_consultation')
    raw_id_fields = ('rdv',)
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('rdv', 'diagnostic', 'actes_effectues', 'notes_medecin', 'document_joint')
        }),
    )

    def patient(self, obj):
        return f"{obj.rdv.patient_demandeur.compte_utilisateur.last_name} {obj.rdv.patient_demandeur.compte_utilisateur.first_name}"
    patient.short_description = "Patient"

    def medecin(self, obj):
        return f"Dr {obj.rdv.medecin_concerne.compte_utilisateur.last_name}"
    medecin.short_description = "Médecin"


# ====================================================================================================
# ORDONNANCES
# ====================================================================================================

class DetailOrdonnanceInline(admin.TabularInline):
    model = DetailOrdonnance
    extra = 1
    raw_id_fields = ('medicament',)
    verbose_name = "Médicament prescrit"
    verbose_name_plural = "Médicaments prescrits"


@admin.register(Ordonnance, site=admin_site)
class OrdonnanceAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient', 'medecin', 'date_prescription', 'nb_medicaments', 'code_securite', 'document')
    list_filter = ('date_prescription', 'medecin_prescripteur__specialite_medicale')
    date_hierarchy = 'date_prescription'
    search_fields = (
        'code_securite',
        'patient_beneficiaire__compte_utilisateur__last_name',
        'patient_beneficiaire__compte_utilisateur__first_name',
        'patient_beneficiaire__compte_utilisateur__numero_telephone',
        'medecin_prescripteur__compte_utilisateur__last_name',
    )
    raw_id_fields = ('consultation', 'medecin_prescripteur', 'patient_beneficiaire')
    inlines = [DetailOrdonnanceInline]
    list_per_page = 25

    fieldsets = (
        ('Liens consultation', {
            'fields': ('consultation',),
            'description': "Rattachement éventuel à une consultation existante",
        }),
        ('Acteurs', {
            'fields': ('medecin_prescripteur', 'patient_beneficiaire'),
        }),
        ('Sécurité & document', {
            'fields': ('code_securite', 'fichier_ordonnance'),
            'description': "Le code sécurité permet la vérification en pharmacie",
        }),
    )

    def patient(self, obj):
        u = obj.patient_beneficiaire.compte_utilisateur
        return f"{u.last_name} {u.first_name}"
    patient.short_description = "Patient"
    patient.admin_order_field = 'patient_beneficiaire__compte_utilisateur__last_name'

    def medecin(self, obj):
        u = obj.medecin_prescripteur.compte_utilisateur
        return f"Dr {u.last_name} {u.first_name}"
    medecin.short_description = "Médecin"
    medecin.admin_order_field = 'medecin_prescripteur__compte_utilisateur__last_name'

    def nb_medicaments(self, obj):
        n = obj.lignes.count()
        return f" {n}"
    nb_medicaments.short_description = "Médicaments"

    def document(self, obj):
        if obj.fichier_ordonnance:
            return format_html("<a href='{}' target='_blank'>PDF</a>", obj.fichier_ordonnance.url)
        return "—"
    document.short_description = "Document"


# ====================================================================================================
# COMMANDES
# ====================================================================================================

class LigneCommandeInline(admin.TabularInline):
    model = LigneCommande
    extra = 1
    raw_id_fields = ('produit', 'pharmacie')


@admin.register(Commande, site=admin_site)
class CommandeAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient', 'date_creation', 'statut', 'total')
    list_filter = ('statut', 'date_creation')
    raw_id_fields = ('patient',)
    inlines = [LigneCommandeInline]
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('patient', 'statut', 'methode_retrait', 'total', 'transaction_id')
        }),
    )

    def patient(self, obj):
        u = obj.patient.compte_utilisateur
        return f"{u.last_name} {u.first_name}"
    patient.short_description = "Patient"
    patient.admin_order_field = 'patient__compte_utilisateur__last_name'


# ====================================================================================================
# NOTIFICATIONS
# ====================================================================================================

@admin.register(Notification, site=admin_site)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'destinataire', 'message_court', 'heure_envoi', 'type_notification', 'lu')
    list_filter = ('type_notification', 'lu', 'heure_envoi')
    list_editable = ('lu',)
    search_fields = ('destinataire__username', 'destinataire__last_name')
    date_hierarchy = 'heure_envoi'
    list_per_page = 25

    def destinataire(self, obj):
        return f"{obj.destinataire.last_name} {obj.destinataire.first_name}"
    destinataire.short_description = "Destinataire"
    destinataire.admin_order_field = 'destinataire__last_name'

    def message_court(self, obj):
        return obj.message[:60] + "..." if len(obj.message) > 60 else obj.message
    message_court.short_description = "Message"


# ====================================================================================================
# ÉTABLISSEMENTS - PHARMACIES
# ====================================================================================================

@admin.register(Pharmacie, site=admin_site)
class PharmacieAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom', 'adresse', 'contact', 'garde')
    search_fields = ('nom', 'adresse')
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('nom', 'adresse', 'contact', 'coordonnee_latitude_gps', 'coordonnee_longitude_gps', 'plage_horaire_ouverture', 'image_etablissement')
        }),
        ('Paiement', {
            'fields': ('pharmacie_est_garde', 'numero_paiement', 'reseau_paiement')
        }),
    )

    def garde(self, obj):
        return "Oui" if obj.pharmacie_est_garde else "Non"
    garde.short_description = "Pharmacie de garde"
    garde.boolean = True


# ====================================================================================================
# ÉTABLISSEMENTS - HÔPITAUX
# ====================================================================================================

@admin.register(Hopital, site=admin_site)
class HopitalAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom', 'adresse', 'contact', 'type_urgences')
    search_fields = ('nom', 'adresse')
    list_per_page = 25

    fieldsets = (
        (None, {
            'fields': ('nom', 'adresse', 'contact', 'coordonnee_latitude_gps', 'coordonnee_longitude_gps', 'plage_horaire_ouverture', 'image_etablissement')
        }),
        ('Services', {
            'fields': ('type_urgences', 'liste_services')
        }),
    )