import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';

class ConfirmationCommandePage extends StatelessWidget {
  static const Color _brandColor = Color(0xFF00C2CB);
  
  const ConfirmationCommandePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_patient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.75),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF22863A).withOpacity(0.3), width: 3),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 52, color: Color(0xFF22863A)),
                  ),
                  const SizedBox(height: 28),
                  const Text("Commande confirmée !",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                    "Votre commande a été enregistrée avec succès.\nVous allez être redirigé vers le portail de paiement.",
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  AppWidgets.primaryButton(
                    label: "Voir mes commandes",
                    icon: Icons.shopping_bag_rounded,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/mes_commandes', ModalRoute.withName('/page_utilisateur')),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/page_utilisateur', (r) => false),
                    child: const Text("Retour à l'accueil",
                        style: TextStyle(color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}