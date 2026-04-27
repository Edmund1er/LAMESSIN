# lamessin_app/urls.py

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import main_views, patient_views, doctor_views, pharma_views
from .views.ia_views import (
    StatutIAView,
    ChatbotIAView,
    AnalyseOrdonnanceIAView,
    InteractionMedicamenteuseIAView,
    ResumeMedicalIAView,
    assistant_ia
)


urlpatterns = [
    path('login/', main_views.Login.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('inscription/', main_views.InscriptionView.as_view(), name='inscription'),
    path('logout/', main_views.LogoutView.as_view(), name='logout'),

    path('profil/', main_views.UserProfil.as_view(), name='user_profil'),
    path('updateProfil/', main_views.UpdateProfilView.as_view(), name='modification_profil'),
    path('notifications/', main_views.ListeNotifications.as_view(), name='liste_notifications'),
    path('notifications/enregistrerToken/', main_views.EnregistrerFCMToken.as_view(), name='enregistrer_token'),

    path('listeMedecins/', patient_views.LiteMedecins.as_view(), name='liste_medecins'),
    path('creneauxDisponible/', patient_views.CreneauxDispo.as_view(), name='creneaux_dispo'),
    path('rendezvous/', patient_views.ListeRendezVousPatient.as_view(), name='liste_rdv'),
    path('rendezvous/creer/', patient_views.CreezRendezVous.as_view(), name='creer_rendezvous'),
    path('rendezvous/<int:pk>/', patient_views.AnnulerRendezVous.as_view(), name='annuler_rdv'),
    path('medecin/rendezvous/expirer/', doctor_views.ExpirerRendezVousView.as_view(), name='expirer_rendezvous'),
    path('patient/rendezvous/expirer/', patient_views.ExpirerRendezVousPatientView.as_view(), name='patient_expirer_rendezvous'),

    path('medicaments/recherche/', patient_views.RechercheMedicament.as_view(), name='recherche_medicament'),
    path('etablissements/', patient_views.ListeEtablissements.as_view(), name='liste_etablissements'),

    path('traitements/', patient_views.ListeTraitementsPatient.as_view(), name='liste_traitements'),
    path('traitements/<int:pk>/', patient_views.DetailTraitement.as_view(), name='detail_traitement'),
    path('traitements/valider-prise/<int:prise_id>/', patient_views.ValiderPriseMedicament.as_view(), name='valider_prise'),
    path('ordonnances/', patient_views.ListeOrdonnancesPatient.as_view(), name='liste_ordonnances'),

    path('commandes/', patient_views.MesCommandesView.as_view(), name='mes_commandes'),
    path('commandes/creer/', patient_views.CreerCommandeMultiple.as_view(), name='creer_paiement'),

    path('paiement/initier/', patient_views.InitierPaiementMobileMoney.as_view(), name='initier_paiement'),
    path('paiement/verifier/<int:commande_id>/', patient_views.VerifierStatutPaiement.as_view(), name='verifier_paiement'),

    path('assistant/chat/', patient_views.assistant, name='assistant_gemini'),
    path('assistant/historique/', patient_views.AssistantHistoriqueView.as_view(), name='assistant_historique'),

    path('ia/statut/', StatutIAView.as_view(), name='ia_statut'),
    path('ia/chatbot/', ChatbotIAView.as_view(), name='ia_chatbot'),
    path('ia/analyse-ordonnance/', AnalyseOrdonnanceIAView.as_view(), name='ia_analyse_ordonnance'),
    path('ia/interactions/', InteractionMedicamenteuseIAView.as_view(), name='ia_interactions'),
    path('ia/resume/', ResumeMedicalIAView.as_view(), name='ia_resume'),
    path('assistant-ia/', assistant_ia, name='assistant_ia'),

    path('medecin/dashboard/', doctor_views.DashboardMedecinView.as_view(), name='medecin_dashboard'),
    path('medecin/statistiques/', doctor_views.StatistiquesMedecinView.as_view(), name='medecin_statistiques'),
    path('medecin/rendezvous/', doctor_views.MedecinRendezVousView.as_view(), name='medecin_rendezvous'),
    path('medecin/rendezvous/<int:rdv_id>/statut/', doctor_views.UpdateRendezVousStatutView.as_view(), name='medecin_update_rdv_statut'),
    path('medecin/consultations/creer/', doctor_views.CreerConsultationView.as_view(), name='medecin_creer_consultation'),
    path('medecin/consultations/<int:consultation_id>/', doctor_views.GetConsultationView.as_view(), name='medecin_get_consultation'),
    path('medecin/consultations/by-rdv/<int:rdv_id>/', doctor_views.GetConsultationByRdvView.as_view(), name='medecin_get_consultation_by_rdv'),
    path('medecin/ordonnances/', doctor_views.OrdonnancesMedecinView.as_view(), name='medecin_ordonnances'),
    path('medecin/ordonnances/creer/', doctor_views.CreerOrdonnanceView.as_view(), name='medecin_creer_ordonnance'),
    path('medecin/plages-horaires/', doctor_views.GererPlagesHorairesView.as_view(), name='medecin_plages_horaires'),
    path('medecin/plages-horaires/<int:plage_id>/', doctor_views.GererPlagesHorairesView.as_view(), name='medecin_delete_plage_horaire'),
    path('medecin/patients/', doctor_views.ListePatientsMedecinView.as_view(), name='medecin_patients'),
    path('medecin/patients/<int:patient_id>/dossier/', doctor_views.DossierPatientView.as_view(), name='medecin_dossier_patient'),
    path('medecin/documents/upload/', doctor_views.UploadDocumentMedicalView.as_view(), name='medecin_upload_document'),

    path('pharmacien/dashboard/', pharma_views.DashboardPharmacienView.as_view(), name='pharmacien_dashboard'),
    path('pharmacien/statistiques/', pharma_views.StatistiquesPharmacieView.as_view(), name='pharmacien_statistiques'),
    path('pharmacien/stocks/', pharma_views.GererStockView.as_view(), name='pharmacien_stocks'),
    path('pharmacien/stocks/<int:stock_id>/', pharma_views.UpdateStockView.as_view(), name='pharmacien_update_stock'),
    path('pharmacien/stocks/alertes/', pharma_views.AlertesStockView.as_view(), name='pharmacien_alertes_stock'),
    path('pharmacien/commandes/', pharma_views.CommandesPharmacieView.as_view(), name='pharmacien_commandes'),
    path('pharmacien/commandes/<int:commande_id>/', pharma_views.DetailCommandePharmacieView.as_view(), name='pharmacien_detail_commande'),
    path('pharmacien/commandes/<int:commande_id>/valider/', pharma_views.ValiderCommandeView.as_view(), name='pharmacien_valider_commande'),
    path('pharmacien/commandes/<int:commande_id>/livrer/', pharma_views.MarquerCommandeLivreeView.as_view(), name='pharmacien_marquer_livree'),
    path('pharmacien/medicaments/', pharma_views.CatalogueMedicamentsView.as_view(), name='pharmacien_medicaments'),
    path('pharmacien/medicaments/ajouter/', pharma_views.GererMedicamentView.as_view(), name='pharmacien_ajouter_medicament'),
    path('pharmacien/medicaments/<int:medicament_id>/modifier/', pharma_views.GererMedicamentView.as_view(), name='pharmacien_modifier_medicament'),
    path('pharmacien/ordonnance/scanner/<str:code_securite>/', pharma_views.ScannerOrdonnanceView.as_view(), name='pharmacien_scanner_ordonnance'),
    path('pharmacien/ordonnance/<int:ordonnance_id>/valider/', pharma_views.ValiderOrdonnanceView.as_view(), name='pharmacien_valider_ordonnance'),
    path('pharmacien/stocks/<int:stock_id>/supprimer/', pharma_views.SupprimerStockView.as_view(), name='pharmacien_supprimer_stock'),
]
