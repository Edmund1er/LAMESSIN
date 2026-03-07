import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class PageUtilisateur extends StatefulWidget {
  const PageUtilisateur({super.key});

  @override
  State<PageUtilisateur> createState() => _PageUtilisateurState();
}

class _PageUtilisateurState extends State<PageUtilisateur> {
  String _prenom = "Patient";
  List<dynamic> _notifications = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonneesProfil();
  }

  Future<void> _chargerDonneesProfil() async {
    try {
      final profil = await ApiService.getProfil();
      final notifs = await ApiService.getNotifications();

      if (profil != null) {
        setState(() {
          if (profil.containsKey('compte_utilisateur')) {
            _prenom = profil['compte_utilisateur']['first_name'] ?? "Patient";
          } else {
            _prenom = profil['first_name'] ?? "Patient";
          }
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      print("Erreur chargement données : $e");
      setState(() => _chargement = false);
    }
  }

  // Fonction pour afficher un message simple si la notif n'est pas redirigeable
  void _afficherMessageDetail(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter LAMESSIN ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ApiService.logout();
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
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text("LAMESSIN", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0056b3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmerDeconnexion(context),
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerDonneesProfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bonjour,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        Text(
                          "M. $_prenom",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0056b3), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 5),
                        const Text("Bienvenue dans votre espace patient", style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text("Notifications récentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Gestion de l'affichage des notifications
                    if (_notifications.isEmpty)
                      _buildSimpleCard("Aucune notification pour le moment", Icons.notifications_none)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notifications.length > 3 ? 3 : _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index], Icons.notifications_active);
                        },
                      ),

                    const SizedBox(height: 25),
                    const Text("Nos Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(context, "Pharmacie / Hôpital", Icons.map, '/recherches_services_medicaux', Colors.blue),
                        _buildActionCard(context, "Mes traitements", Icons.medication, '/suivi_traitements', Colors.green),
                        _buildActionCard(context, "Mes rendez-vous", Icons.calendar_today, '/mes_rendez_vous_page', Colors.orange),
                        _buildActionCard(context, "Mes commandes", Icons.shopping_basket, '/mes_commandes', Colors.purple),
                        _buildActionCard(context, "Assistant virtuel", Icons.smart_toy, '/assistant', Colors.teal),
                        _buildActionCard(context, "Mon Profil", Icons.person, '/profil_patient', Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Carte cliquable pour les vraies notifications
  Widget _buildNotificationCard(dynamic notif, IconData icon) {
    return InkWell(
      onTap: () {
        if (notif['type_notification'] == 'RDV') {
          Navigator.pushNamed(context, '/mes_rendez_vous_page');
        } else if (notif['type_notification'] == 'TRAITEMENT') {
          Navigator.pushNamed(context, '/suivi_traitements');
        } else {
          _afficherMessageDetail(notif['message'] ?? "");
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif['message'] ?? "", style: const TextStyle(fontSize: 14)),
                  const Text("Il y a un instant", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Carte simple pour le message "Aucune notification"
  Widget _buildSimpleCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 15),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String route, Color color) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}