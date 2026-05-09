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
    '7j':  ('7 derniers jours', 7),
    '30j': ('30 derniers jours', 30),
    '90j': ('90 derniers jours', 90),
    'all': ('Tout l\'historique', None),
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
            'cl': ChangeList(request, RendezVous, RendezVousAdmin.list_display,
                            RendezVousAdmin.list_display_links, RendezVousAdmin.list_filter,
                            RendezVousAdmin.date_hierarchy, RendezVousAdmin.search_fields,
                            RendezVousAdmin.list_select_related, RendezVousAdmin.list_per_page,
                            RendezVousAdmin.list_max_show_all, RendezVousAdmin.list_editable,
                            RendezVousAdmin)
        }
        return TemplateResponse(request, 'admin/rendezvous_calendar.html', context)

    def stats_full_view(self, request):
        """Page fullscreen dédiée aux statistiques"""
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
            .values('mois').annotate(total=Count('id'))
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

        context = {
            **self.each_context(request),
            'title': 'Tableau de bord - Statistiques',
            **stats,
        }
        return TemplateResponse(request, 'admin/stats_full.html', context)

    def index(self, request, extra_context=None):
        aujourdhui = timezone.now().date()

        # ===== FILTRE PÉRIODE (?periode=7j|30j|90j|all) =====
        periode_key = request.GET.get('periode', '30j')
        if periode_key not in PERIODES:
            periode_key = '30j'
        periode_label, periode_jours = PERIODES[periode_key]
        date_debut = aujourdhui - timedelta(days=periode_jours) if periode_jours else None

        # ===== ÉVOLUTION RDV (sur la période, max 30 points) =====
        n_points = min(periode_jours or 30, 30)
        evolution_labels, evolution_data = [], []
        for i in range(n_points - 1, -1, -1):
            d = aujourdhui - timedelta(days=i)
            evolution_labels.append(d.strftime('%d/%m'))
            evolution_data.append(RendezVous.objects.filter(date_rdv=d).count())

        # ===== ORDONNANCES PAR MOIS (12 derniers mois) =====
        date_il_y_a_un_an = aujourdhui - timedelta(days=365)
        ordo_par_mois = list(
            Ordonnance.objects
            .filter(date_prescription__gte=date_il_y_a_un_an)
            .annotate(mois=TruncMonth('date_prescription'))
            .values('mois').annotate(total=Count('id'))
            .order_by('mois')
        )
        ordo_labels = [item['mois'].strftime('%b %Y') for item in ordo_par_mois]
        ordo_data = [item['total'] for item in ordo_par_mois]

        # ===== TOP 10 MÉDICAMENTS PRESCRITS =====
        top_medicaments = list(
            DetailOrdonnance.objects
            .values('medicament__nom_commercial')
            .annotate(total=Count('id'))
            .order_by('-total')[:10]
        )

        # ===== FILTRES PÉRIODE POUR COMMANDES & ORDONNANCES =====
        cmd_qs = Commande.objects.all()
        ordo_qs = Ordonnance.objects.all()
        if date_debut:
            cmd_qs = cmd_qs.filter(date_creation__date__gte=date_debut)
            ordo_qs = ordo_qs.filter(date_prescription__gte=date_debut)

        revenus = cmd_qs.filter(statut='PAYE').aggregate(t=Sum('total'))['t'] or 0

        stats = {
            # ===== En-tête / filtres =====
            'periode_active': periode_key,
            'periode_label': periode_label,
            'periode_options': [(k, v[0]) for k, v in PERIODES.items()],

            # ===== KPI principaux (opérationnel santé) =====
            'total_rdv': RendezVous.objects.count(),
            'total_patients': Utilisateur.objects.filter(est_un_compte_patient=True, is_active=True).count(),
            'total_medecins': Utilisateur.objects.filter(est_un_compte_medecin=True, is_active=True).count(),
            'commandes_total': cmd_qs.count(),

            # ===== Stats RDV =====
            'rdv_aujourdhui': RendezVous.objects.filter(date_rdv=aujourdhui).count(),
            'rdv_en_attente': RendezVous.objects.filter(statut_actuel_rdv='en_attente').count(),
            'rdv_confirme': RendezVous.objects.filter(statut_actuel_rdv='confirme').count(),
            'rdv_termine': RendezVous.objects.filter(statut_actuel_rdv='termine').count(),
            'rdv_annule': RendezVous.objects.filter(statut_actuel_rdv='annule').count(),
            'evolution_labels': evolution_labels,
            'evolution_data': evolution_data,

            # ===== Stats Commandes =====
            'commandes_attente': cmd_qs.filter(statut='EN_ATTENTE').count(),
            'commandes_payees': cmd_qs.filter(statut='PAYE').count(),
            'commandes_livrees': cmd_qs.filter(statut='LIVRE').count(),
            'commandes_annulees': cmd_qs.filter(statut='ANNULE').count(),
            'revenus_periode': revenus,

            # ===== Établissements =====
            'total_pharmacies': Pharmacie.objects.count(),
            'pharmacies_garde': Pharmacie.objects.filter(pharmacie_est_garde=True).count(),
            'total_hopitaux': Hopital.objects.count(),
            'total_pharmaciens': Utilisateur.objects.filter(est_un_compte_pharmacien=True, is_active=True).count(),
            'total_consultations': Consultation.objects.count(),
            'total_ordonnances': ordo_qs.count(),
            'total_medicaments': Medicament.objects.count(),
            'stocks_alerte': Stock.objects.filter(quantite_actuelle_en_stock__lte=models.F('seuil_alerte')).count(),

            # ===== Ordonnances =====
            'ordo_labels': ordo_labels,
            'ordo_data': ordo_data,
            'top_medicaments': top_medicaments,
        }
        extra_context = {**stats, **(extra_context or {})}
        return super().index(request, extra_context=extra_context)


admin_site = LamessinAdminSite(name='lamessin_admin')


# ====================================================================================================
# UTILISATEURS (MODÈLE DE BASE)
# ====================================================================================================

@admin.register(Utilisateur, site=admin_site)
class UtilisateurAdmin(admin.ModelAdmin):
    list_display = ('id', 'username', 'numero_telephone', 'email', 'first_name', 'last_name', 'get_role')
    list_filter = ('est_un_compte_patient', 'est_un_compte_medecin', 'est_un_compte_pharmacien', 'is_active')
    search_fields = ('username', 'numero_telephone', 'email', 'first_name', 'last_name')

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

    def get_role(self, obj):
        if obj.est_un_compte_patient:
            return "Patient"
        if obj.est_un_compte_medecin:
            return "Médecin"
        if obj.est_un_compte_pharmacien:
            return "Pharmacien"
        return "Admin"
    get_role.short_description = "Rôle"


# ====================================================================================================
# PATIENTS (LIÉ À UTILISATEUR)
# ====================================================================================================

@admin.register(Patient, site=admin_site)
class PatientAdmin(admin.ModelAdmin):
    list_display = ('get_telephone', 'get_nom', 'get_prenom', 'groupe_sanguin', 'date_naissance')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'compte_utilisateur__numero_telephone')
    raw_id_fields = ('compte_utilisateur',)

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations médicales', {
            'fields': ('date_naissance', 'groupe_sanguin', 'photo_profil')
        }),
    )

    def get_telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    get_telephone.short_description = "Téléphone"

    def get_nom(self, obj):
        return obj.compte_utilisateur.last_name
    get_nom.short_description = "Nom"

    def get_prenom(self, obj):
        return obj.compte_utilisateur.first_name
    get_prenom.short_description = "Prénom"


# ====================================================================================================
# MÉDECINS (LIÉ À UTILISATEUR)
# ====================================================================================================

@admin.register(Medecin, site=admin_site)
class MedecinAdmin(admin.ModelAdmin):
    list_display = ('get_telephone', 'get_nom', 'get_prenom', 'specialite_medicale', 'numero_licence')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'specialite_medicale')
    list_filter = ('specialite_medicale',)
    raw_id_fields = ('compte_utilisateur',)

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations professionnelles', {
            'fields': ('specialite_medicale', 'numero_licence', 'photo_profil')
        }),
    )

    def get_telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    get_telephone.short_description = "Téléphone"

    def get_nom(self, obj):
        return f"Dr {obj.compte_utilisateur.last_name}"
    get_nom.short_description = "Nom"

    def get_prenom(self, obj):
        return obj.compte_utilisateur.first_name
    get_prenom.short_description = "Prénom"


# ====================================================================================================
# PHARMACIENS (LIÉ À UTILISATEUR ET PHARMACIE)
# ====================================================================================================

@admin.register(Pharmacien, site=admin_site)
class PharmacienAdmin(admin.ModelAdmin):
    list_display = ('get_telephone', 'get_nom', 'get_prenom', 'pharmacie', 'numero_licence')
    search_fields = ('compte_utilisateur__first_name', 'compte_utilisateur__last_name', 'pharmacie__nom')
    list_filter = ('pharmacie',)
    raw_id_fields = ('compte_utilisateur',)

    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('compte_utilisateur',)
        }),
        ('Informations professionnelles', {
            'fields': ('pharmacie', 'numero_licence')
        }),
    )

    def get_telephone(self, obj):
        return obj.compte_utilisateur.numero_telephone
    get_telephone.short_description = "Téléphone"

    def get_nom(self, obj):
        return obj.compte_utilisateur.last_name
    get_nom.short_description = "Nom"

    def get_prenom(self, obj):
        return obj.compte_utilisateur.first_name
    get_prenom.short_description = "Prénom"


# ====================================================================================================
# MÉDICAMENTS
# ====================================================================================================

@admin.register(Medicament, site=admin_site)
class MedicamentAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom_commercial', 'prix_vente')
    search_fields = ('nom_commercial',)

    fieldsets = (
        (None, {
            'fields': ('nom_commercial', 'description', 'posologie_standard', 'prix_vente', 'image_produit')
        }),
    )


# ====================================================================================================
# STOCKS (LIÉ À MÉDICAMENT ET PHARMACIE)
# ====================================================================================================

@admin.register(Stock, site=admin_site)
class StockAdmin(admin.ModelAdmin):
    list_display = ('produit_concerne', 'pharmacie_detentrice', 'quantite_actuelle_en_stock', 'statut_stock', 'date_peremption')
    list_filter = ('pharmacie_detentrice', 'seuil_alerte')
    raw_id_fields = ('produit_concerne',)

    fieldsets = (
        (None, {
            'fields': ('produit_concerne', 'pharmacie_detentrice', 'quantite_actuelle_en_stock', 'seuil_alerte', 'date_peremption')
        }),
    )

    def statut_stock(self, obj):
        if obj.quantite_actuelle_en_stock == 0:
            return "Rupture"
        if obj.quantite_actuelle_en_stock <= obj.seuil_alerte:
            return "Alerte"
        return "OK"
    statut_stock.short_description = "Statut"


# ====================================================================================================
# RENDEZ-VOUS (LIÉ À PATIENT ET MÉDECIN)
# ====================================================================================================

@admin.register(RendezVous, site=admin_site)
class RendezVousAdmin(admin.ModelAdmin):
    list_display = ('get_patient', 'get_medecin', 'date_rdv', 'heure_rdv', 'motif_consultation', 'statut_actuel_rdv')
    list_filter = ('statut_actuel_rdv', 'date_rdv', 'medecin_concerne')
    date_hierarchy = 'date_rdv'
    raw_id_fields = ('patient_demandeur', 'medecin_concerne')

    fieldsets = (
        (None, {
            'fields': ('patient_demandeur', 'medecin_concerne', 'date_rdv', 'heure_rdv', 'motif_consultation', 'statut_actuel_rdv')
        }),
    )

    def get_patient(self, obj):
        return obj.patient_demandeur.compte_utilisateur.last_name
    get_patient.short_description = "Patient"

    def get_medecin(self, obj):
        return f"Dr {obj.medecin_concerne.compte_utilisateur.last_name}"
    get_medecin.short_description = "Médecin"


# ====================================================================================================
# CONSULTATIONS (LIÉ À RENDEZ-VOUS)
# ====================================================================================================

@admin.register(Consultation, site=admin_site)
class ConsultationAdmin(admin.ModelAdmin):
    list_display = ('get_patient', 'get_medecin', 'date_consultation')
    raw_id_fields = ('rdv',)

    fieldsets = (
        (None, {
            'fields': ('rdv', 'diagnostic', 'actes_effectues', 'notes_medecin', 'document_joint')
        }),
    )

    def get_patient(self, obj):
        return obj.rdv.patient_demandeur.compte_utilisateur.last_name
    get_patient.short_description = "Patient"

    def get_medecin(self, obj):
        return f"Dr {obj.rdv.medecin_concerne.compte_utilisateur.last_name}"
    get_medecin.short_description = "Médecin"


# ====================================================================================================
# ORDONNANCES (LIÉ À CONSULTATION, MÉDECIN, PATIENT)
# ====================================================================================================

class DetailOrdonnanceInline(admin.TabularInline):
    model = DetailOrdonnance
    extra = 1
    raw_id_fields = ('medicament',)
    verbose_name = "Médicament prescrit"
    verbose_name_plural = "Médicaments prescrits"


@admin.register(Ordonnance, site=admin_site)
class OrdonnanceAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'get_patient_full',
        'get_medecin_full',
        'date_prescription',
        'get_nb_medicaments',
        'code_securite',
        'get_pdf_link',
    )
    list_filter = ('date_prescription', 'medecin_prescripteur__specialite_medicale')
    date_hierarchy = 'date_prescription'
    search_fields = (
        'code_securite',
        'patient_beneficiaire__compte_utilisateur__last_name',
        'patient_beneficiaire__compte_utilisateur__first_name',
        'patient_beneficiaire__compte_utilisateur__numero_telephone',
        'medecin_prescripteur__compte_utilisateur__last_name',
        'medecin_prescripteur__numero_licence',
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

    def get_patient_full(self, obj):
        u = obj.patient_beneficiaire.compte_utilisateur
        return f"{u.first_name} {u.last_name}"
    get_patient_full.short_description = "Patient"
    get_patient_full.admin_order_field = 'patient_beneficiaire__compte_utilisateur__last_name'

    def get_medecin_full(self, obj):
        u = obj.medecin_prescripteur.compte_utilisateur
        spec = obj.medecin_prescripteur.specialite_medicale or "—"
        return format_html("Dr {} {}<br><small style='color:#94a3b8'>{}</small>",
                           u.first_name, u.last_name, spec)
    get_medecin_full.short_description = "Médecin"

    def get_nb_medicaments(self, obj):
        n = obj.lignes.count()
        return format_html(
            "<span style='background:#dbeafe;color:#1d4ed8;padding:2px 8px;border-radius:9999px;font-weight:600;'>{}</span>",
            n
        )
    get_nb_medicaments.short_description = "Médicaments"

    def get_pdf_link(self, obj):
        if obj.fichier_ordonnance:
            return format_html(
                "<a href='{}' target='_blank' style='color:#2563eb;font-weight:600'>📄 PDF</a>",
                obj.fichier_ordonnance.url
            )
        return format_html("<span style='color:#94a3b8'>—</span>")
    get_pdf_link.short_description = "Document"


# ====================================================================================================
# COMMANDES (LIÉ À PATIENT)
# ====================================================================================================

class LigneCommandeInline(admin.TabularInline):
    model = LigneCommande
    extra = 1
    raw_id_fields = ('produit', 'pharmacie')

@admin.register(Commande, site=admin_site)
class CommandeAdmin(admin.ModelAdmin):
    list_display = ('id', 'get_patient', 'date_creation', 'statut', 'total')
    list_filter = ('statut', 'date_creation')
    raw_id_fields = ('patient',)
    inlines = [LigneCommandeInline]

    fieldsets = (
        (None, {
            'fields': ('patient', 'statut', 'methode_retrait', 'total', 'transaction_id')
        }),
    )

    def get_patient(self, obj):
        return obj.patient.compte_utilisateur.last_name
    get_patient.short_description = "Patient"


# ====================================================================================================
# NOTIFICATIONS
# ====================================================================================================

@admin.register(Notification, site=admin_site)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'destinataire', 'message_courte', 'heure_envoi', 'type_notification', 'lu')
    list_filter = ('type_notification', 'lu', 'heure_envoi')
    list_editable = ('lu',)
    search_fields = ('destinataire__username', 'destinataire__last_name')
    date_hierarchy = 'heure_envoi'

    def message_courte(self, obj):
        return obj.message[:60] + "..." if len(obj.message) > 60 else obj.message
    message_courte.short_description = "Message"


# ====================================================================================================
# ÉTABLISSEMENTS
# ====================================================================================================

@admin.register(Pharmacie, site=admin_site)
class PharmacieAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom', 'adresse', 'contact', 'pharmacie_est_garde')
    search_fields = ('nom', 'adresse')

    fieldsets = (
        (None, {
            'fields': ('nom', 'adresse', 'contact', 'coordonnee_latitude_gps', 'coordonnee_longitude_gps', 'plage_horaire_ouverture', 'image_etablissement')
        }),
        ('Paiement', {
            'fields': ('pharmacie_est_garde', 'numero_paiement', 'reseau_paiement')
        }),
    )


@admin.register(Hopital, site=admin_site)
class HopitalAdmin(admin.ModelAdmin):
    list_display = ('id', 'nom', 'adresse', 'contact', 'type_urgences')
    search_fields = ('nom', 'adresse')

    fieldsets = (
        (None, {
            'fields': ('nom', 'adresse', 'contact', 'coordonnee_latitude_gps', 'coordonnee_longitude_gps', 'plage_horaire_ouverture', 'image_etablissement')
        }),
        ('Services', {
            'fields': ('type_urgences', 'liste_services')
        }),
    )
