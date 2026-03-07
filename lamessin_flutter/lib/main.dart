import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'PAGES_/AUTH_/splash.dart';
import 'PAGES_/AUTH_/login.dart';
import 'PAGES_/AUTH_/register.dart';
import 'PAGES_/home_page.dart';
import 'PAGES_/PATIENT_/page_utilisateur.dart';
import 'PAGES_/PATIENT_/recherches_services_medicaux.dart';
import 'PAGES_/PATIENT_/prise_rdv_patient.dart';
import "PAGES_/PATIENT_/services.dart";
import "PAGES_/PATIENT_/assistant.dart";

void main() async{
// On s'assure que les widgets sont bien liés
  WidgetsFlutterBinding.ensureInitialized();
// On initialise les données de date pour le français
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: "/splash",

      routes: {
        "/splash": (context) => const Splash(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),
        "/home_page": (context) => const HomePage(),
        "/page_utilisateur": (context) => const page_utilisateur(),
        "/recherches_services_medicaux": (context) => const recherches_services_medicaux(),
        "/rendez_vous_page": (context) => const RendezVousPage(),
        "services": (context) => const Services(),
        "/assistant": (context) => const Assistant(),
      },
    
    localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('fr', 'FR'),
  ],
  locale: const Locale('fr', 'FR'),
    );
  }
}
