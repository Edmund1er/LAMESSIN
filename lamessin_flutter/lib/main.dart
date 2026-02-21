import 'package:flutter/material.dart';
import 'PAGES_/splash.dart';
import 'PAGES_/acceuill.dart';
import 'PAGES_/login.dart';
import 'PAGES_/register.dart';
import 'PAGES_/page_utilisateur.dart';
import 'PAGES_/recherches_services_medicaux.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      routes: {
        "/": (context) => const Splash(),
        "/home": (context) => const Acceuill(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),
        "/page_utilisateur": (context) => const page_utilisateur(),
        "/recherches_services_medicaux.dart": (context) =>
            const recherches_services_medicaux(),
      },
    );
  }
}
