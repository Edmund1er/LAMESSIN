import 'package:flutter/material.dart';
import 'PAGES_/splash.dart';
import 'PAGES_/acceuill.dart';
import 'PAGES_/login.dart';
import 'PAGES_/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => const Splash(),
        "/home": (context) => const Acceuill(),
        "/login": (context) => const Login(),
        "/register": (context) => const Register(),
      },
    );
  }
}
