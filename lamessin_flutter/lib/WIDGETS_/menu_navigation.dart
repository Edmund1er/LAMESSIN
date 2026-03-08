import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({super.key});

  @override
  State<MenuNavigation> createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  Map<String, dynamic>? _profil;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonneesProfil();
  }

  // --- RÉCUPÉRATION DYNAMIQUE DES INFOS ---
  Future<void> _chargerDonneesProfil() async {
    final donnees = await ApiService.getProfil();
    if (mounted) {
      setState(() {
        _profil = donnees;
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extraction des données dynamiques
    final String nomUser = _profil?['compte_utilisateur']?['last_name'] ?? "Utilisateur";
    final String prenomUser = _profil?['compte_utilisateur']?['first_name'] ?? "";
    final String roleUser = _profil?['type_utilisateur'] ?? "...";

    return Drawer(
      child: Column(
        children: [
          // EN-TÊTE DYNAMIQUE
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 78, 192, 17),
            ),
            accountName: _chargement 
                ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("$prenomUser $nomUser", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(roleUser.toUpperCase()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                nomUser[0].toUpperCase(),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 78, 192, 17)),
              ),
            ),
          ),

          // LISTE DES ACTIONS (LIÉES AUX ROUTES DYNAMIQUE)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                      _elementMenu(context, Icons.dashboard_rounded, "Tableau de bord", "/page_utilisateur"),
                      _elementMenu(context, Icons.add_task_rounded, "Prendre Rendez-vous", "/rendez_vous_page"),
                      _elementMenu(context, Icons.event_note_rounded, "Mes Rendez-vous", "/mes_rendez_vous_page"),
                      _elementMenu(context, Icons.medication_rounded, "Suivi Traitements", "/suivi_traitements"),
                      _elementMenu(context, Icons.local_hospital_rounded, "Établissements", "/recherches_services_medicaux"),
                      
                      // AJOUT DU MENU COMMANDES ICI
                      _elementMenu(context, Icons.shopping_bag_rounded, "Mes Commandes", "/mes_commandes"),
                      
                      const Divider(),
                      _elementMenu(context, Icons.account_circle_rounded, "Mon Profil", "/profil_patient"),
                    ],
            ),
          ),

          // DÉCONNEXION RÉELLE
          const Divider(),
          ListTile(
            leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
            title: const Text("Déconnexion", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _elementMenu(BuildContext context, IconData icone, String titre, String route) {
    return ListTile(
      leading: Icon(icone, color: Colors.blueAccent),
      title: Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context); // Ferme le menu
        // On évite de recharger la page si on y est déjà
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}