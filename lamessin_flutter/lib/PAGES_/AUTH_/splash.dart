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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _demarrerChrono();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _demarrerChrono() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    String? token = await ApiService.getToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, token != null ? "/page_utilisateur" : "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/accueil_image.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5), 
                    AppColors.primary.withOpacity(0.85), 
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.25),
                             blurRadius: 20,
                             spreadRadius: 5
                           )
                        ]
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 28),
                    const Text('LAMESSIN',
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
                              )
                            ]
                        )),
                    const SizedBox(height: 10),
                    Text('Votre santé, notre priorité',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16, 
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 80),
                    SizedBox(
                      width: 30, height: 30,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
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