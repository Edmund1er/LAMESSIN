# lamessin_app/urls.py

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

# Import des vues modulaires
from .views import main_views, patient_views, doctor_views, pharma_views

urlpatterns = [
    # ====================================================================================================
    # AUTHENTIFICATION & SESSION
    # ====================================================================================================
    path('login/', main_views.Login.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('inscription/', main_views.InscriptionView.as_view(), name='inscription'),
    path('logout/', main_views.LogoutView.as_view(), name='logout'),

    # ====================================================================================================
    # PROFIL UTILISATEUR (COMMUN)
    # ====================================================================================================
    path('profil/', main_views.UserProfil.as_view(), name='user_profil'),
    path('updateProfil/', main_views.UpdateProfilView.as_view(), name='modification_profil'),
    path('notifications/', main_views.ListeNotifications.as_view(), name='liste_notifications'),
    path('notifications/enregistrerToken/', main_views.EnregistrerFCMToken.as_view(), name='enregistrer_token'),

    # ====================================================================================================
    # PATIENT - MÉDECINS & RENDEZ-VOUS
    # ====================================================================================================
    path('listeMedecins/', patient_views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', patient_views.CreneauxDispo.as_view(), name='creneaux_dispo'),
    path('rendezvous/', patient_views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
    path('rendezvous/creer/', patient_views.CreezRendezVous.as_view(), name='creer_rendezvous'),
    path('rendezvous/<int:pk>/', patient_views.AnnulerRendezVous.as_view(), name='annuler_rdv'),

    # ====================================================================================================
    # PATIENT - MÉDICAMENTS & ÉTABLISSEMENTS
    # ====================================================================================================
    path('medicaments/recherche/', patient_views.RechercheMedicament.as_view(), name='recherche_medicament'),
    path('etablissements/', patient_views.ListeEtablissements.as_view(), name='liste_etablissements'),

    # ====================================================================================================
    # PATIENT - TRAITEMENTS & ORDONNANCES
    # ====================================================================================================
    path('traitements/', patient_views.ListeTraitementsPatient.as_view(), name='liste_traitements'),
    path('traitements/<int:pk>/', patient_views.DetailTraitement.as_view(), name='detail_traitement'),
    path('traitements/valider-prise/<int:prise_id>/', patient_views.ValiderPriseMedicament.as_view(), name='valider_prise'),
    path('ordonnances/', patient_views.ListeOrdonnancesPatient.as_view(), name='liste_ordonnances'),
    # ====================================================================================================
    # PATIENT - COMMANDES & PAIEMENTS
    # ====================================================================================================
    path('commandes/', patient_views.MesCommandesView.as_view(), name='mes_commandes'),
    path('commandes/creerEtPayer/', patient_views.CreerCommandeMultiple.as_view(), name='creer_paiement'),
    path('commandes/<int:commande_id>/genererLien/', patient_views.GenererLienPaiement.as_view(), name='generer_lien'),
    path('cinetpay/webhook/', patient_views.cinetpay_webhook, name='cinetpay_webhook'),

    # ====================================================================================================
    # PATIENT - ASSISTANT IA
    # ====================================================================================================
    path('assistant/chat/', patient_views.assistant, name='assistant_gemini'),
    path('assistant/historique/', patient_views.AssistantHistoriqueView.as_view(), name='assistant_historique'),

    # ====================================================================================================
    # MÉDECIN - URLs
    # ====================================================================================================
    # Dashboard & Statistiques
    path('medecin/dashboard/', doctor_views.DashboardMedecinView.as_view(), name='medecin_dashboard'),
    path('medecin/statistiques/', doctor_views.StatistiquesMedecinView.as_view(), name='medecin_statistiques'),

    # Rendez-vous
    path('medecin/rendezvous/', doctor_views.MedecinRendezVousView.as_view(), name='medecin_rendezvous'),
    path('medecin/rendezvous/<int:rdv_id>/statut/', doctor_views.UpdateRendezVousStatutView.as_view(), name='update_rdv_statut'),

    # Consultations
    path('medecin/consultations/creer/', doctor_views.CreerConsultationView.as_view(), name='creer_consultation'),
    path('medecin/consultations/<int:consultation_id>/', doctor_views.GetConsultationView.as_view(), name='detail_consultation'),

    # Ordonnances
    path('medecin/ordonnances/', doctor_views.OrdonnancesMedecinView.as_view(), name='medecin_ordonnances'),
    path('medecin/ordonnances/creer/', doctor_views.CreerOrdonnanceView.as_view(), name='creer_ordonnance'),

    # Disponibilités
    path('medecin/plages-horaires/', doctor_views.GererPlagesHorairesView.as_view(), name='gerer_plages'),
    path('medecin/plages-horaires/<int:plage_id>/', doctor_views.GererPlagesHorairesView.as_view(), name='supprimer_plage'),

    # Patients
    path('medecin/patients/', doctor_views.ListePatientsMedecinView.as_view(), name='medecin_patients'),
    path('medecin/patients/<int:patient_id>/dossier/', doctor_views.DossierPatientView.as_view(), name='dossier_patient'),

    # Documents
    path('medecin/documents/upload/', doctor_views.UploadDocumentMedicalView.as_view(), name='upload_document'),

    # ====================================================================================================
    # PHARMACIEN - URLs
    # ====================================================================================================
    # Dashboard & Statistiques
    path('pharmacien/dashboard/', pharma_views.DashboardPharmacienView.as_view(), name='pharmacien_dashboard'),
    path('pharmacien/statistiques/', pharma_views.StatistiquesPharmacieView.as_view(), name='pharmacien_statistiques'),

    # Gestion des stocks
    path('pharmacien/stocks/', pharma_views.GererStockView.as_view(), name='gerer_stocks'),
    path('pharmacien/stocks/<int:stock_id>/', pharma_views.UpdateStockView.as_view(), name='update_stock'),
    path('pharmacien/stocks/alertes/', pharma_views.AlertesStockView.as_view(), name='alertes_stock'),

    # Gestion des commandes
    path('pharmacien/commandes/', pharma_views.CommandesPharmacieView.as_view(), name='pharmacien_commandes'),
    path('pharmacien/commandes/<int:commande_id>/', pharma_views.DetailCommandePharmacieView.as_view(), name='detail_commande'),
    path('pharmacien/commandes/<int:commande_id>/valider/', pharma_views.ValiderCommandeView.as_view(), name='valider_commande'),

    # Gestion des médicaments
    path('pharmacien/medicaments/', pharma_views.CatalogueMedicamentsView.as_view(), name='catalogue_medicaments'),
    path('pharmacien/medicaments/ajouter/', pharma_views.GererMedicamentView.as_view(), name='ajouter_medicament'),
    path('pharmacien/medicaments/<int:medicament_id>/modifier/', pharma_views.GererMedicamentView.as_view(), name='modifier_medicament'),

    # Scan d'ordonnance
    path('pharmacien/ordonnance/scanner/<str:code_securite>/', pharma_views.ScannerOrdonnanceView.as_view(), name='scanner_ordonnance'),
    path('pharmacien/ordonnance/<int:ordonnance_id>/valider/', pharma_views.ValiderOrdonnanceView.as_view(), name='valider_ordonnance'),
]