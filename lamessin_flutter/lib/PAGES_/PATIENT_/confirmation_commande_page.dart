import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';

class ConfirmationCommandePage extends StatefulWidget {
  const ConfirmationCommandePage({super.key});

  @override
  State<ConfirmationCommandePage> createState() => _ConfirmationCommandePageState();
}

class _ConfirmationCommandePageState extends State<ConfirmationCommandePage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 2;

  final String _imageFond = "assets/images/fond_patient.jpg";

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 3)),
                      child: const Icon(Icons.check_rounded, size: 52, color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 28),
                    const Text("Commande confirmee !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    const Text(
                      "Votre commande a ete enregistree avec succes.\nVous allez etre redirige vers le portail de paiement.",
                      style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    AppWidgets.primaryButton(
                      label: "Voir mes commandes",
                      icon: Icons.shopping_bag_rounded,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/mes_commandes', ModalRoute.withName('/page_utilisateur')),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/page_utilisateur', (r) => false),
                      child: const Text("Retour a l'accueil", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, currentIndex),
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, currentIndex),
              _navItem(Icons.shopping_bag_rounded, "Commandes", 2, currentIndex),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, currentIndex),
              _navItem(Icons.person_rounded, "Profil", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: () => _onItemTapped(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}