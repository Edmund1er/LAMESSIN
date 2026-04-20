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

// Pages Pharmacien
import 'PAGES_/PHARMACIEN_/pharmacien_dashboard_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_produits_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_profil_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_commandes_page.dart';
import 'PAGES_/PHARMACIEN_/pharmacien_scan_ordonnance_page.dart';
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
      routes: {
        // Auth
        "/splash": (context) => const Splash(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),

        // Patient
        "/profil_patient": (context) => const ProfilPatientPage(),
        "/edit_profil": (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Patient) return EditProfilPage(patient: args);
          return const Scaffold(
            body: Center(child: Text("Erreur : Aucun profil fourni")),
          );
        },
        "/page_utilisateur": (context) => const PageUtilisateur(),
        "/recherches_services_medicaux": (context) => const RechercheServicesPage(),
        "/assistant": (context) => const AssistantPage(),
        "/suivi_traitements": (context) => const SuiviTraitementsPage(),
        "/mes_commandes": (context) => const MesCommandesPage(),
        "/rendez_vous_page": (context) => const RendezVousPage(),
        "/mes_rendez_vous_page": (context) => const MesRendezVousPage(),
        "/historique_chatbot": (context) => const AssistantHistoriquePage(),
        "/historique_notifications": (context) => const NotificationHistoryPage(),
        "/paiement": (context) => const PaiementPage(commandeId: 0, montant: 0),

        // Medecin
        "/dashboard_medecin": (context) => const MedecinDashboardPage(),
        "/medecin_rendezvous": (context) => const MedecinRendezVousPage(),
        "/medecin_profil": (context) => const MedecinProfilPage(),
        "/GererPlages": (context) => const GererPlagesHorairesPage(),

        // Pharmacien
        "/dashboard_pharmacien": (context) => const PharmacienDashboardPage(),
        "/produits_pharmacien": (context) => const PharmacienProduitsPage(),
        "/profil_pharmacien": (context) => const PharmacienProfilPage(),
        "/commandes_pharmacien": (context) => const PharmacienCommandesPage(),
        "/scan_ordonnance_pharmacien": (context) => const PharmacienScanOrdonnancePage(),
        "/alertes_stock_pharmacien": (context) => const PharmacienAlertesStockPage(),
      },
    );
  }
}