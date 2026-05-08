from django.contrib import admin
from django.contrib.admin import AdminSite
from django.utils.html import format_html
from django.db import models
from .models import *
from django.utils import timezone
from datetime import timedelta
from django.template.response import TemplateResponse
from django.urls import path
from django.contrib.admin.views.main import ChangeList


class LamessinAdminSite(AdminSite):
    site_header = "LAMESSIN"
    site_title = "Administration LAMESSIN"
    index_title = "Tableau de bord"
    site_logo = None

    index_template = 'admin/index.html'

    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path('rendezvous-calendrier/', self.admin_view(self.rendezvous_calendar_view), name='rendezvous_calendar'),
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

    def index(self, request, extra_context=None):
        aujourdhui = timezone.now().date()

        evolution_labels = []
        evolution_data = []
        for i in range(6, -1, -1):
            date = aujourdhui - timedelta(days=i)
            evolution_labels.append(date.strftime('%d/%m'))
            count = RendezVous.objects.filter(date_rdv=date).count()
            evolution_data.append(count)

        context = {
            'total_medecins': Utilisateur.objects.filter(est_un_compte_medecin=True).count(),
            'total_patients': Utilisateur.objects.filter(est_un_compte_patient=True).count(),
            'rdv_aujourdhui': RendezVous.objects.filter(date_rdv=aujourdhui).count(),
            'commandes_total': Commande.objects.count(),
            'rdv_en_attente': RendezVous.objects.filter(statut_actuel_rdv='en_attente').count(),
            'rdv_confirme': RendezVous.objects.filter(statut_actuel_rdv='confirme').count(),
            'rdv_termine': RendezVous.objects.filter(statut_actuel_rdv='termine').count(),
            'rdv_annule': RendezVous.objects.filter(statut_actuel_rdv='annule').count(),
            'commandes_attente': Commande.objects.filter(statut='EN_ATTENTE').count(),
            'commandes_payees': Commande.objects.filter(statut='PAYE').count(),
            'commandes_livrees': Commande.objects.filter(statut='LIVRE').count(),
            'commandes_annulees': Commande.objects.filter(statut='ANNULE').count(),
            'evolution_labels': evolution_labels,
            'evolution_data': evolution_data,
        }
        context.update(extra_context or {})
        return TemplateResponse(request, self.index_template, context)


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

@admin.register(Ordonnance, site=admin_site)
class OrdonnanceAdmin(admin.ModelAdmin):
    list_display = ('id', 'get_patient', 'get_medecin', 'date_prescription', 'code_securite')
    raw_id_fields = ('consultation', 'medecin_prescripteur', 'patient_beneficiaire')
    inlines = [DetailOrdonnanceInline]

    fieldsets = (
        (None, {
            'fields': ('consultation', 'medecin_prescripteur', 'patient_beneficiaire', 'code_securite', 'fichier_ordonnance')
        }),
    )

    def get_patient(self, obj):
        return obj.patient_beneficiaire.compte_utilisateur.last_name
    get_patient.short_description = "Patient"

    def get_medecin(self, obj):
        return f"Dr {obj.medecin_prescripteur.compte_utilisateur.last_name}"
    get_medecin.short_description = "Médecin"


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
