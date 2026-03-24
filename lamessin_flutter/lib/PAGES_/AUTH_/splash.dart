import 'package:flutter/material.dart';
import 'dart:async';
import '../../SERVICES_/api_service.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _demarrerChrono();
  }

  void _demarrerChrono() async {
    // On attend 3 secondes pour le logo
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Petite logique bonus : Si le token existe, on peut rediriger vers l'accueil directement
    String? token = await ApiService.getToken();
    
    if (token != null) {
      Navigator.pushReplacementNamed(context, "/page_utilisateur");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  "assets/images/accueil_image.jpeg", 
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.medical_services, size: 80, color: Colors.blue);
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "LAMESSIN",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Votre santé, notre priorité",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}