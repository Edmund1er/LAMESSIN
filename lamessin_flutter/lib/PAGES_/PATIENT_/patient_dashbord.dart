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

  // Couleurs de la charte graphique LAMESSIN
  final Color couleurBleue = const Color(0xFF1A73E8);
  final Color couleurVerte = const Color(0xFF00A896);
  final Color couleurFond = const Color.fromARGB(255, 135, 206, 235);

  @override
  void initState() {
    super.initState();
    _chargerDonneesProfil();
  }

  // ---------------------------------------------------------------------------
  // LOGIQUE DE CALCUL DU TEMPS ÉCOULÉ
  // ---------------------------------------------------------------------------
  String _calculerTempsEcoule(String? dateStr) {
    if (dateStr == null) {
      return "À l'instant";
    }
    try {
      DateTime dateNotif = DateTime.parse(dateStr).toLocal();
      DateTime maintenant = DateTime.now();
      Duration difference = maintenant.difference(dateNotif);

      if (difference.inSeconds < 60) {
        return "Il y a ${difference.inSeconds} s";
      }
      if (difference.inMinutes < 60) {
        return "Il y a ${difference.inMinutes} min";
      }
      if (difference.inHours < 24) {
        return "Il y a ${difference.inHours} h";
      }
      return "Il y a ${difference.inDays} j";
    } catch (e) {
      return "Récemment";
    }
  }

  Future<void> _chargerDonneesProfil() async {
    try {
      final profil = await ApiService.getProfil();
      final notifs = await ApiService.getNotifications();

      if (mounted) {
        setState(() {
          if (profil != null) {
            // Correction pour éviter le "dead code" et gérer la structure du profil
            final dynamic userMap = profil['compte_utilisateur'];
            if (userMap != null) {
              _prenom = userMap['first_name'] ?? "Patient";
            } else {
              _prenom = profil['first_name'] ?? "Patient";
            }
          }
          // On s'assure que _notifications n'est pas nul
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  void _afficherMessageDetail(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Notification"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          )
        ],
      ),
    );
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter LAMESSIN ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
      backgroundColor: couleurFond,
      body: _chargement
          ? Center(child: CircularProgressIndicator(color: couleurBleue))
          : RefreshIndicator(
              onRefresh: _chargerDonneesProfil,
              color: couleurBleue,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Notifications récentes"),
                          const SizedBox(height: 12),
                          if (_notifications.isEmpty)
                            _buildSimpleCard("Aucune notification pour le moment", Icons.notifications_off_outlined)
                          else
                            ..._notifications.take(3).map((n) => _buildNotificationCard(n)).toList(),
                          const SizedBox(height: 30),
                          _buildSectionTitle("Nos Services"),
                          const SizedBox(height: 15),
                          _buildGridServices(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: couleurBleue,
      actions: [
        IconButton(
          icon: const Icon(Icons.power_settings_new, color: Colors.white),
          onPressed: () => _confirmerDeconnexion(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [couleurBleue, couleurVerte],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bonjour,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text("M. $_prenom",
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridServices() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.25,
      children: [
        _buildActionCard("Pharmacies", Icons.local_hospital, '/recherches_services_medicaux', couleurBleue),
        _buildActionCard("Traitements", Icons.medical_services, '/suivi_traitements', couleurVerte),
        _buildActionCard("Rendez-vous", Icons.event_available, '/mes_rendez_vous_page', const Color(0xFFFF9F1C)),
        _buildActionCard("Commandes", Icons.shopping_cart_outlined, '/mes_commandes', const Color(0xFFE91E63)),
        _buildActionCard("Assistant", Icons.support_agent, '/assistant', const Color(0xFF00796B)),
        _buildActionCard("Mon Profil", Icons.account_circle_outlined, '/profil_patient', Colors.indigo),
      ],
    );
  }

  Widget _buildNotificationCard(dynamic notif) {
    final String type = notif['type_notification'] ?? "INFO";
    final String tempsAffiche = _calculerTempsEcoule(notif['heure_envoi']);

    IconData icone = Icons.notifications;
    Color couleurType = couleurVerte;

    if (type.contains('ORDONNANCE')) {
      icone = Icons.description;
      couleurType = couleurBleue;
    } else if (type.contains('RENDEZ_VOUS')) {
      icone = Icons.event;
      couleurType = const Color(0xFFFF9F1C);
    } else if (type.contains('COMMANDE')) {
      icone = Icons.shopping_bag;
      couleurType = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: couleurType, width: 5)),
      ),
      child: ListTile(
        onTap: () {
          // Utilisation correcte des blocs pour éviter l'erreur curly_braces
          if (type.contains('RDV')) {
            Navigator.pushNamed(context, '/mes_rendez_vous_page');
          } else if (type.contains('COMMANDE')) {
            Navigator.pushNamed(context, '/mes_commandes');
          } else if (type.contains('ORDONNANCE')) {
            Navigator.pushNamed(context, '/suivi_traitements');
          } else {
            _afficherMessageDetail(notif['message'] ?? "");
          }
        },
        leading: CircleAvatar(
          backgroundColor: couleurType.withOpacity(0.1),
          child: Icon(icone, size: 20, color: couleurType),
        ),
        title: Text(notif['message'] ?? "",
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(tempsAffiche, style: const TextStyle(fontSize: 10)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)));
  }

  Widget _buildActionCard(String titre, IconData icon, String route, Color couleur) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: couleur.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: couleur, size: 28),
              ),
              const SizedBox(height: 10),
              Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2F3E46))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[400], size: 40),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}