import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    
    // 1. Enregistrement du Token Firebase (Essentiel pour Edge et Mobile)
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("FCM Token récupéré : $token");
        await ApiService.enregistrerFCMToken(token);
      }
    } catch (e) {
      print("Erreur Token FCM: $e");
    }

    // 2. Écoute en temps réel quand l'application est ouverte
    _firebaseSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notification reçue en direct !");
      
      // On rafraîchit la liste des notifications depuis le serveur
      _chargerDonneesProfil();

      // Affichage d'un bandeau visuel (SnackBar) car sur Web la bannière système est discrète
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${message.notification?.title ?? 'Alerte'}: ${message.notification?.body}"),
            backgroundColor: couleurVerte,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // LOGIQUE & SERVICES
  // ---------------------------------------------------------------------------
  
  Future<void> _chargerDonneesProfil() async {
    try {
      final profil = await ApiService.getProfil();
      // Ici, on appelle l'URL /api/notifications/ que tu as ajoutée dans Django
      final notifs = await ApiService.getNotifications();

      if (mounted) {
        setState(() {
          if (profil != null) {
            final dynamic userMap = profil['compte_utilisateur'];
            _prenom = (userMap != null) 
                ? (userMap['first_name'] ?? "Patient") 
                : (profil['first_name'] ?? "Patient");
          }
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      print("Erreur chargement : $e");
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _calculerTempsEcoule(String? dateStr) {
    if (dateStr == null) return "À l'instant";
    try {
      DateTime dateNotif = DateTime.parse(dateStr).toLocal();
      DateTime maintenant = DateTime.now();
      Duration difference = maintenant.difference(dateNotif);

      if (difference.inSeconds < 60) return "Il y a ${difference.inSeconds} s";
      if (difference.inMinutes < 60) return "Il y a ${difference.inMinutes} min";
      if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
      return "Il y a ${difference.inDays} j";
    } catch (e) { return "Récemment"; }
  }

  // ---------------------------------------------------------------------------
  // INTERFACE UTILISATEUR
  // ---------------------------------------------------------------------------

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
                            _buildSimpleCard("Aucune notification", Icons.notifications_off_outlined)
                          else
                            ..._notifications.take(5).map((n) => _buildNotificationCard(n)).toList(),
                          const SizedBox(height: 30),
                          _buildSectionTitle("Nos Services"),
                          const SizedBox(height: 15),
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
      expandedHeight: 180, pinned: true, elevation: 0, backgroundColor: couleurBleue,
      actions: [
        IconButton(
          icon: const Icon(Icons.power_settings_new, color: Colors.white), 
          onPressed: () => _confirmerDeconnexion(context)
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [couleurBleue, couleurVerte])),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bonjour,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text("M. $_prenom", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridServices() {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.25,
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

  Widget _buildActionCard(String titre, IconData icon, String route, Color couleur) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: couleur, size: 28),
            const SizedBox(height: 10),
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notif) {
    final String type = notif['type_notification'] ?? "INFO";
    final String tempsAffiche = _calculerTempsEcoule(notif['heure_envoi']);
    IconData icone = Icons.notifications;
    Color couleurType = couleurVerte;

    if (type.contains('ORDONNANCE')) { icone = Icons.description; couleurType = couleurBleue; }
    else if (type.contains('RENDEZ_VOUS')) { icone = Icons.event; couleurType = const Color(0xFFFF9F1C); }
    else if (type.contains('COMMANDE')) { icone = Icons.shopping_bag; couleurType = Colors.purple; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: couleurType, width: 5)),
      ),
      child: ListTile(
        onTap: () => _afficherMessageDetail(notif['message'] ?? ""),
        leading: CircleAvatar(backgroundColor: couleurType.withOpacity(0.1), child: Icon(icone, size: 20, color: couleurType)),
        title: Text(notif['message'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(tempsAffiche, style: const TextStyle(fontSize: 10)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildSimpleCard(String message, IconData icon) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)));
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter LAMESSIN ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text("Se déconnecter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _afficherMessageDetail(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))],
      ),
    );
  }
}