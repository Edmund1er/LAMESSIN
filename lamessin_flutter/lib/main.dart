import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'PAGES_/AUTH_/splash.dart';
import 'PAGES_/AUTH_/login.dart';
import 'PAGES_/AUTH_/register.dart';
import 'PAGES_/home_page.dart';
import 'PAGES_/PATIENT_/patient_dashbord.dart';
import 'PAGES_/PATIENT_/recherches_services_medicaux.dart';
import 'PAGES_/PATIENT_/prise_rdv_patient.dart';
import "PAGES_/PATIENT_/services.dart";
import "PAGES_/PATIENT_/assistant.dart";
import 'PAGES_/PATIENT_/suivi_traitements.dart';
import 'PAGES_/PATIENT_/mon_profil.dart';
import "PAGES_/PATIENT_/mes_rendez_vous_page.dart"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Initialisation du format de date 

  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LAMESIN',
      
// Configuration de la langue 

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),

      initialRoute: "/splash",

      routes: {
        // authentification, profils et comptes  
        "/splash": (context) => const Splash(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),
        "/home_page": (context) => const HomePage(),
        "/profil_patient": (context) => const ProfilPatientPage(),

        // Dashboard et Services patient
        "/page_utilisateur": (context) => const PageUtilisateur (),

        "/recherches_services_medicaux": (context) => const RechercheServicesPage(),
        "/services": (context) => const Services(),
        "/assistant": (context) => const Assistant(),
        '/suivi_traitements': (context) => const SuiviTraitementsPage(),

        // Gestion des Rendez-vous patient
        "/rendez_vous_page": (context) => const RendezVousPage(), 
        "/mes_rendez_vous_page": (context) => const MesRendezVousPage(), 
      },
    );
  }
}