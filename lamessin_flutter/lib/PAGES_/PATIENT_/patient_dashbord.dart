import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class PageUtilisateur extends StatelessWidget {
  const PageUtilisateur({super.key});

  // Fonction pour gérer la déconnexion proprement
  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter lamessin ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ApiService.logout(); // Supprime le token dans SharedPreferences
              // Retour au login en effaçant l'historique de navigation
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("Se déconnecter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LAMESIN", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0056b3),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmerDeconnexion(context),
            tooltip: "Déconnexion",
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE1F0FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              // --- OPTION 1 : RECHERCHE ---
              _buildMenuCard(
                context,
                title: "Hôpitaux et pharmacies proches",
                icon: Icons.local_hospital,
                route: '/recherches_services_medicaux',
                color: const Color(0xFF0056b3),
              ),

              const SizedBox(height: 15),

              // --- OPTION 2 : PRENDRE RDV ---
              _buildMenuCard(
                context,
                title: "Prendre un rendez-vous",
                icon: Icons.add_alarm,
                route: '/rendez_vous_page',
                color: const Color(0xFF0056b3),
              ),

              const SizedBox(height: 15),

              // --- OPTION 3 : MES RDV (HISTORIQUE) ---
              _buildMenuCard(
                context,
                title: "Mes rendez-vous & Historique",
                icon: Icons.calendar_month,
                route: '/mes_rendez_vous_page',
                color: const Color(0xFF0056b3),
              ),

              const SizedBox(height: 15),

              // --- OPTION 4 : CHATBOT ---
              _buildMenuCard(
                context,
                title: "Assistant Virtuel (Chatbot)",
                icon: Icons.chat_bubble,
                route: '/assistant',
                color: const Color(0xFF0056b3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget réutilisable pour les cartes du menu
  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 100,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 35),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}