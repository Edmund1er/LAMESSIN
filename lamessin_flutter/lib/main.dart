import 'package:flutter/material.dart';
import "package:lamessin_flutter/PAGES_/splash.dart";

import "PAGES_/login.dart";

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
        "/login": (context) => const Login(),
      },
    );
  }
}
