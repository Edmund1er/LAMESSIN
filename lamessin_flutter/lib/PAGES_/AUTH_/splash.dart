import 'package:flutter/material.dart';
import 'dart:async';
import '../../SERVICES_/api_service.dart';
import '../../THEME_/app_theme.dart';


class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;

  late Animation<double> _fade;
 
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
// Initialisons le controleur d'animation 
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _demarrerChrono();
  }

  @override
  void dispose() {
 
    _ctrl.dispose();
    super.dispose();
  }

  void _demarrerChrono() async {
// Pause de 3 secondes pour l'animation

    await Future.delayed(const Duration(seconds: 3));

   
    if (!mounted) return;

// Verification du token d'authentification s'il existe 

    String? token = await ApiService.getToken();

    if (!mounted) return;

// Redirection vers le tableau de bord si connecte, sinon vers la page de connexion

    Navigator.pushReplacementNamed(
      context,
      token != null ? "/page_utilisateur" : "/login",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
//l'image de fond 
          Positioned.fill(
            child: Image.asset(
              'assets/images/accueil_image.jpeg',
              fit: BoxFit
                  .cover, 
            ),
          ),

//on applique une voile degrade par-dessus l'image pour ameliorer la lisibilite
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(
                      0.5,
                    ), 
                    AppColors.primary.withOpacity(
                      0.85,
                    ), 
                  ],
                ),
              ),
            ),
          ),
// Contenu centre
          Center(
            child: FadeTransition(
              opacity: _fade, 
              child: ScaleTransition(
                scale: _scale, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
// logo
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.2,
                        ), 
                        borderRadius: BorderRadius.circular(
                          24,
                        ), 
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded, 
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 28),
// Nom de l'application
                    const Text(
                      'LAMESSIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
// Slogan de lamessin
                    Text(
                      'Votre santé, notre priorité',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 80),
// l'indicateur de chargement pendant l'attente
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
