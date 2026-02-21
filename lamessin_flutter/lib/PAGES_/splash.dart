import 'package:flutter/material.dart';
import 'dart:async';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 10), () {
// "mounted" vérifie que la page existe toujours avant de naviguer
      if (mounted) 
        {
          Navigator.pushReplacementNamed(context, "/login");
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE1F0FF),
      body: Center(
        child: Image.asset(
          "assets/images/accueil_image.jpeg",
          width: 1000,
          height: 1000,
        ),
      ),
    );
  }
}
