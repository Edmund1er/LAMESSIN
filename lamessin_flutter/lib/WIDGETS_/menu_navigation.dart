import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';
import '../MODELS_/utilisateur_model.dart'; 

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({super.key});

  @override
  State<MenuNavigation> createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  // On utilise dynamic pour ne plus JAMAIS avoir d'erreur d'assignation
  dynamic _donneesRecues; 
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonneesProfil();
  }

  Future<void> _chargerDonneesProfil() async {
    try {
      final resultat = await ApiService.getProfil(); 
      if (mounted) {
        setState(() {
          _donneesRecues = resultat;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // LOGIQUE DE RÉCUPÉRATION INTELLIGENTE
    // On cherche le nom soit dans Patient.compteUtilisateur, soit directement dans Utilisateur
    String nom = "Utilisateur";
    String prenom = "";
    String infoSante = "Chargement...";

    if (_donneesRecues != null) {
      if (_donneesRecues is Patient) {
        nom = _donneesRecues.compteUtilisateur.lastName;
        prenom = _donneesRecues.compteUtilisateur.firstName;
        infoSante = _donneesRecues.groupeSanguin ?? "Groupe inconnu";
      } else if (_donneesRecues is Utilisateur) {
        nom = _donneesRecues.lastName;
        prenom = _donneesRecues.firstName;
        infoSante = "Profil Patient";
      }
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color.fromARGB(255, 78, 192, 17)),
            accountName: _chargement 
                ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("$prenom $nom", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(infoSante),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 78, 192, 17)),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _elementMenu(context, Icons.dashboard_rounded, "Tableau de bord", "/page_utilisateur"),
                _elementMenu(context, Icons.add_task_rounded, "Prendre Rendez-vous", "/rendez_vous_page"),
                _elementMenu(context, Icons.event_note_rounded, "Mes Rendez-vous", "/mes_rendez_vous_page"),
                _elementMenu(context, Icons.medication_rounded, "Suivi Traitements", "/suivi_traitements"),
                _elementMenu(context, Icons.local_hospital_rounded, "Établissements", "/recherches_services_medicaux"),
                _elementMenu(context, Icons.assistant_rounded, "Assistant IA", "/assistant"),
                _elementMenu(context, Icons.history_rounded, "Historique Chat", "/historique_chatbot"),
                _elementMenu(context, Icons.shopping_bag_rounded, "Mes Commandes", "/mes_commandes"),
                const Divider(),
                _elementMenu(context, Icons.account_circle_rounded, "Mon Profil", "/profil_patient"),
              ],
            ),
          ),

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
        Navigator.pop(context); 
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}