import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/notification_model.dart';

class PageUtilisateur extends StatefulWidget {
  const PageUtilisateur({super.key});

  @override
  State<PageUtilisateur> createState() => _PageUtilisateurState();
}

class _PageUtilisateurState extends State<PageUtilisateur> {
  String _nomAffichage = "Chargement...";
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  StreamSubscription<RemoteMessage>? _firebaseSubscription;

  final Color couleurBleue = const Color(0xFF1A73E8);
  final Color couleurVerte = const Color(0xFF00A896);
  final Color couleurFond = const Color.fromARGB(255, 135, 206, 235);

  @override
  void initState() {
    super.initState();
    _initialiserPage();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialiserPage() async {
    await _chargerDonneesProfil();
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) await ApiService.enregistrerFCMToken(token);
    } catch (e) {
      debugPrint("Erreur FCM: $e");
    }
    _firebaseSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      _chargerDonneesProfil();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${message.notification?.title ?? 'Alerte'}: ${message.notification?.body ?? ''}",
            ),
            backgroundColor: couleurVerte,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  Future<void> _chargerDonneesProfil() async {
    try {
      final data = await ApiService.getProfil();
      final List<NotificationModel> notifs =
          await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          if (data != null) {
            if (data is Patient) {
              _nomAffichage =
                  "${data.compteUtilisateur.firstName} ${data.compteUtilisateur.lastName}";
            } else if (data is Utilisateur) {
              _nomAffichage = "${data.firstName} ${data.lastName}";
            } else {
              _nomAffichage = data.username ?? "Utilisateur";
            }
          } else {
            _nomAffichage = "Utilisateur";
          }
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _calculerTempsEcoule(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Récemment";
    try {
      DateTime dateNotif = DateTime.parse(dateStr).toLocal();
      DateTime maintenant = DateTime.now();
      Duration difference = maintenant.difference(dateNotif);
      if (difference.inSeconds < 60) return "Il y a ${difference.inSeconds} s";
      if (difference.inMinutes < 60)
        return "Il y a ${difference.inMinutes} min";
      if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
      return "Il y a ${difference.inDays} j";
    } catch (e) {
      return "Récemment";
    }
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
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Notifications récentes"),
                          const SizedBox(height: 10),
                          if (_notifications.isEmpty)
                            _buildSimpleCard(
                              "Aucune notification",
                              Icons.notifications_off,
                            ) // ICI CORRECTION
                          else
                            ..._notifications
                                .take(5)
                                .map((n) => _buildNotificationCard(n))
                                .toList(),
                          const SizedBox(height: 25),
                          _buildSectionTitle("Nos Services"),
                          const SizedBox(height: 10),
                          _buildGridServices(),
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
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: couleurBleue,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () =>
              Navigator.pushNamed(context, '/historique_notifications'),
        ),
        IconButton(
          icon: const Icon(
            Icons.power_settings_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => _confirmerDeconnexion(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [couleurBleue, couleurVerte]),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bonjour,",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  "M. $_nomAffichage",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CARTES COMPACTES ---
  Widget _buildGridServices() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildCompactCard(
          "Pharmacies",
          Icons.local_hospital,
          '/recherches_services_medicaux',
          couleurBleue,
        ),
        _buildCompactCard(
          "Traitements",
          Icons.medical_services,
          '/suivi_traitements',
          couleurVerte,
        ),
        _buildCompactCard(
          "Rendez-vous",
          Icons.event_available,
          '/mes_rendez_vous_page',
          const Color(0xFFFF9F1C),
        ),
        _buildCompactCard(
          "Commandes",
          Icons.shopping_cart_outlined,
          '/mes_commandes',
          const Color(0xFFE91E63),
        ),
        _buildCompactCard(
          "Assistant",
          Icons.support_agent,
          '/assistant',
          const Color(0xFF00796B),
        ),
        _buildCompactCard(
          "Mon Profil",
          Icons.account_circle_outlined,
          '/profil_patient',
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildCompactCard(
    String titre,
    IconData icon,
    String route,
    Color couleur,
  ) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Icon(icon, color: couleur, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final String type = notif.typeNotification ?? "GENERAL";
    final String tempsAffiche = _calculerTempsEcoule(notif.heureEnvoi);
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: couleurType, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => _afficherMessageDetail(notif.message ?? ""),
        leading: CircleAvatar(
          backgroundColor: couleurType.withOpacity(0.1),
          child: Icon(icone, size: 18, color: couleurType),
        ),
        title: Text(
          notif.message ?? "Nouveau message",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(tempsAffiche, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  Widget _buildSimpleCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF2F3E46),
    ),
  );

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
            },
            child: const Text(
              "Se déconnecter",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherMessageDetail(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Notification"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}
