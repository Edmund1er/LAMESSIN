import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Theme
import 'THEME_/app_theme.dart';

// Services
import 'SERVICES_/notification_service.dart';
import 'SERVICES_/api_service.dart';

// Pages Auth
import 'PAGES_/AUTH_/splash.dart';
import 'PAGES_/AUTH_/login.dart';
import 'PAGES_/AUTH_/register.dart';

// Pages Patient
import 'PAGES_/PATIENT_/patient_dashbord.dart';
import 'PAGES_/PATIENT_/recherches_services_medicaux.dart';
import 'PAGES_/PATIENT_/prise_rdv_patient.dart';
import 'PAGES_/PATIENT_/mes_commandes.dart';
import 'PAGES_/PATIENT_/assistant.dart';
import 'PAGES_/PATIENT_/suivi_traitements.dart';
import 'PAGES_/PATIENT_/edit_profil_page.dart';
import 'PAGES_/PATIENT_/mon_profil.dart';
import 'PAGES_/PATIENT_/mes_rendez_vous_page.dart';
import 'PAGES_/PATIENT_/AssistantHistoriquePage.dart';
import 'PAGES_/PATIENT_/notifications_history_page.dart';
import 'PAGES_/PATIENT_/paiement_page.dart';

// Pages Medecin
import 'PAGES_/MEDECIN_/medecin_dashboard.dart';
import 'PAGES_/MEDECIN_/medecin_profil_page.dart';
import 'PAGES_/MEDECIN_/medecin_rendezvous_page.dart';
import 'PAGES_/MEDECIN_/GererPlagesHorairesPage.dart';
import 'PAGES_/MEDECIN_/medecin_consultations_page.dart';
import 'PAGES_/MEDECIN_/medecin_detail_consultation_page.dart';
import 'PAGES_/MEDECIN_/medecin_ordonnances_page.dart';
import 'PAGES_/MEDECIN_/medecin_patients_page.dart';
import 'PAGES_/MEDECIN_/medecin_dossier_patient_page.dart';

// Pages Pharmacien
import 'PAGES_/PHARMACIEN_/pharmacien_dashboard_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_produits_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_profil_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_commandes_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_alertes_stock_page.dart';

import 'MODELS_/utilisateur_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCmbiha3Un8XQ00R21IFi3CGPfhtIEIGXE",
          appId: "1:888701279600:web:672541eb0f272462e443b5",
          messagingSenderId: "888701279600",
          projectId: "lamessin-ab826",
          storageBucket: "lamessin-ab826.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp();
      await NotificationService.initialiser();
    }
  } catch (e) {
    debugPrint("ALERTE Firebase : $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LAMESSIN',
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
      initialRoute: "/splash",
      onGenerateRoute: (settings) {
        // Gestion des routes avec paramètres
        switch (settings.name) {
          // ==================== AUTH ====================
          case "/splash":
            return MaterialPageRoute(builder: (_) => const Splash());
          case "/login":
            return MaterialPageRoute(builder: (_) => const Login());
          case "/register":
            return MaterialPageRoute(builder: (_) => const Register());

          // ==================== PATIENT ====================
          case "/profil_patient":
            return MaterialPageRoute(builder: (_) => const ProfilPatientPage());
          case "/edit_profil":
            final args = settings.arguments;
            if (args is Patient) {
              return MaterialPageRoute(builder: (_) => EditProfilPage(patient: args));
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Erreur : Aucun profil fourni"))));
          case "/page_utilisateur":
            return MaterialPageRoute(builder: (_) => const PageUtilisateur());
          case "/recherches_services_medicaux":
            return MaterialPageRoute(builder: (_) => const RechercheServicesPage());
          case "/assistant":
            return MaterialPageRoute(builder: (_) => const AssistantPage());
          case "/suivi_traitements":
            return MaterialPageRoute(builder: (_) => const SuiviTraitementsPage());
          case "/mes_commandes":
            return MaterialPageRoute(builder: (_) => const MesCommandesPage());
          case "/rendez_vous_page":
            return MaterialPageRoute(builder: (_) => const RendezVousPage());
          case "/mes_rendez_vous_page":
            return MaterialPageRoute(builder: (_) => const MesRendezVousPage());
          case "/historique_chatbot":
            return MaterialPageRoute(builder: (_) => const AssistantHistoriquePage());
          case "/historique_notifications":
            return MaterialPageRoute(builder: (_) => const NotificationHistoryPage());
          case "/paiement":
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => PaiementPage(
                  commandeId: args['commandeId'] ?? 0,
                  montant: args['montant'] ?? 0,
                ),
              );
            }
            return MaterialPageRoute(builder: (_) => const PaiementPage(commandeId: 0, montant: 0));

          // ==================== MÉDECIN ====================
          case "/dashboard_medecin":
            return MaterialPageRoute(builder: (_) => const MedecinDashboardPage());
          case "/medecin_rendezvous":
            return MaterialPageRoute(builder: (_) => const MedecinRendezVousPage());
          case "/medecin_profil":
            return MaterialPageRoute(builder: (_) => const MedecinProfilPage());
          case "/GererPlages":
            return MaterialPageRoute(builder: (_) => const GererPlagesHorairesPage());
          case "/medecin_consultations":
            return MaterialPageRoute(builder: (_) => const MedecinConsultationsPage());
          case "/medecin_detail_consultation":
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('rdvId')) {
              return MaterialPageRoute(
                builder: (_) => MedecinDetailConsultationPage(rdvId: args['rdvId']),
              );
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Erreur: RDV ID manquant"))));
          case "/medecin_ordonnances":
            return MaterialPageRoute(builder: (_) => const MedecinOrdonnancesPage());
          case "/medecin_patients":
            return MaterialPageRoute(builder: (_) => const MedecinPatientsPage());
          case "/medecin_dossier_patient":
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('patientId')) {
              return MaterialPageRoute(
                builder: (_) => MedecinDossierPatientPage(patientId: args['patientId']),
              );
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Erreur: Patient ID manquant"))));

          // ==================== PHARMACIEN ====================
          case "/dashboard_pharmacien":
            return MaterialPageRoute(builder: (_) => const PharmacienDashboardPage());
          case "/produits_pharmacien":
            return MaterialPageRoute(builder: (_) => const PharmacienProduitsPage());
          case "/profil_pharmacien":
            return MaterialPageRoute(builder: (_) => const PharmacienProfilPage());
          case "/commandes_pharmacien":
            return MaterialPageRoute(builder: (_) => const PharmacienCommandesPage());
          case "/alertes_stock_pharmacien":
            return MaterialPageRoute(builder: (_) => const PharmacienAlertesStockPage());

          default:
            return MaterialPageRoute(builder: (_) => const Splash());
        }
      },
    );
  }
}