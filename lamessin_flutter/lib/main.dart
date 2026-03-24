import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

// Services
import 'SERVICES_/notification_service.dart'; 
import 'SERVICES_/api_service.dart';

// Pages
import 'PAGES_/AUTH_/splash.dart';
import 'PAGES_/AUTH_/login.dart';
import 'PAGES_/AUTH_/register.dart';
import 'PAGES_/home_page.dart';
import 'PAGES_/PATIENT_/patient_dashbord.dart';
import 'PAGES_/PATIENT_/recherches_services_medicaux.dart';
import 'PAGES_/PATIENT_/prise_rdv_patient.dart';
import 'PAGES_/PATIENT_/mes_commandes.dart';
import "PAGES_/PATIENT_/assistant.dart";
import 'PAGES_/PATIENT_/suivi_traitements.dart';
import 'PAGES_/PATIENT_/edit_profil_page.dart';
import 'PAGES_/PATIENT_/mon_profil.dart';
import "PAGES_/PATIENT_/mes_rendez_vous_page.dart"; 
import "PAGES_/PATIENT_/AssistantHistoriquePage.dart";
import "PAGES_/PATIENT_/notifications_history_page.dart";

// Import du modèle Patient pour la route
import 'MODELS_/utilisateur_model.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  try {
    if (kIsWeb) {
      // Config Web pour Edge
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCmbiha3Un8XQ00R21IFi3CGPfhtIEIGXE",
          appId: "1:888701279600:web:672541eb0f272462e443b5",
          messagingSenderId: "888701279600",
          projectId: "lamessin-ab826",
          storageBucket: "lamessin-ab826.firebasestorage.app",
        ),
      );
      print("Firebase Web initialisé.");
    } else {
      // Config Android
      await Firebase.initializeApp();
      await NotificationService.initialiser();
    }
  } catch (e) {
    print("ALERTE Firebase : $e");
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => const Splash(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),
        "/home_page": (context) => const HomePage(),
        "/profil_patient": (context) => const ProfilPatientPage(),
        
        "/edit_profil": (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Patient) {
            return EditProfilPage(patient: args);
          }
          return const Scaffold(body: Center(child: Text("Erreur : Aucun profil fourni")));
        },

        "/page_utilisateur": (context) => const PageUtilisateur(),
        "/recherches_services_medicaux": (context) => const RechercheServicesPage(),
        "/assistant": (context) => const AssistantPage(),
        '/suivi_traitements': (context) => const SuiviTraitementsPage(),
        "/mes_commandes": (context) => const MesCommandesPage(), 
        "/rendez_vous_page": (context) => const RendezVousPage(),
        "/mes_rendez_vous_page": (context) => const MesRendezVousPage(),
        "/historique_chatbot": (context) => const AssistantHistoriquePage(),  
        "/historique_notifications": (context) => const NotificationHistoryPage(),
      },
    );
  }
}
