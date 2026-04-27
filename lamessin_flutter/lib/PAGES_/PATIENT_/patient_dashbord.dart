import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/notification_model.dart';
import '../../THEME_/app_theme.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'recherches_services_medicaux.dart';
import 'mes_rendez_vous_page.dart';
import 'assistant.dart';
import 'mon_profil.dart';
import 'notifications_history_page.dart';
import 'suivi_traitements.dart';

class PageUtilisateur extends StatefulWidget {
  const PageUtilisateur({super.key});

  @override
  State<PageUtilisateur> createState() => _PageUtilisateurState();
}

class _PageUtilisateurState extends State<PageUtilisateur> {
  static const Color _brandColor = Color(0xFF00ACC1);
  
  String _nomAffichage = "Chargement...";
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  StreamSubscription<RemoteMessage>? _firebaseSubscription;
  int _selectedIndex = 0;

  final String _imageFond = "assets/images/fond_patient.jpg";

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
    _firebaseSubscription = FirebaseMessaging.onMessage.listen((msg) {
      _chargerDonneesProfil();
      if (mounted) {
        AppWidgets.showSnack(
          context,
          "${msg.notification?.title ?? 'Alerte'}: ${msg.notification?.body ?? ''}",
          color: _brandColor,
        );
      }
    });
  }

  Future<void> _chargerDonneesProfil() async {
    try {
      final data = await ApiService.getProfil();
      final List<NotificationModel> notifs = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          if (data != null) {
            if (data is Patient) {
              _nomAffichage = "${data.compteUtilisateur.firstName} ${data.compteUtilisateur.lastName}";
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
    if (dateStr == null || dateStr.isEmpty) return "Recemment";
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr).toLocal());
      if (diff.inSeconds < 60) return "Il y a ${diff.inSeconds} s";
      if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
      if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
      return "Il y a ${diff.inDays} j";
    } catch (_) {
      return "Recemment";
    }
  }

  void _openNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationHistoryPage()));
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RechercheServicesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MesRendezVousPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssistantPage()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilPatientPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : RefreshIndicator(
              onRefresh: _chargerDonneesProfil,
              color: _brandColor,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _imageFond,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100]),
                    ),
                  ),
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 180,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                            ),
                            onPressed: _openNotifications,
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                            ),
                            onPressed: () => _confirmerDeconnexion(context),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [_brandColor.withOpacity(0.85), _brandColor.withOpacity(0.7)],
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 22, bottom: 24, top: 60),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Bonjour,", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("M. $_nomAffichage", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white.withOpacity(0.92),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Notifications recentes", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
                                const SizedBox(height: 12),
                                if (_notifications.isEmpty)
                                  _buildEmptyNotif()
                                else
                                  ..._notifications.take(2).map((n) => _buildNotifCard(n)),
                                const SizedBox(height: 24),
                                const Text("Nos Services", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
                                const SizedBox(height: 14),
                                _buildGrilleServices(),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  Widget _buildNotifCard(NotificationModel notif) {
    final String type = notif.typeNotification ?? "GENERAL";
    IconData icone = Icons.notifications_rounded;
    Color couleur = _brandColor;
    if (type.contains('ORDONNANCE')) {
      icone = Icons.description_rounded;
    } else if (type.contains('RENDEZ_VOUS')) {
      icone = Icons.event_rounded;
      couleur = AppColors.warning;
    } else if (type.contains('COMMANDE')) {
      icone = Icons.shopping_bag_rounded;
      couleur = AppColors.accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: couleur.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, size: 18, color: couleur),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.message ?? "Nouveau message", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(_calculerTempsEcoule(notif.heureEnvoi), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotif() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          const Text("Aucune notification", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGrilleServices() {
    final services = [
      {'label': 'Pharmacies', 'icon': Icons.local_pharmacy_rounded, 'route': '/recherches_services_medicaux', 'color': _brandColor, 'bg': _brandColor.withOpacity(0.15)},
      {'label': 'Traitements', 'icon': Icons.medication_rounded, 'route': '/suivi_traitements', 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9)},
      {'label': 'Rendez-vous', 'icon': Icons.calendar_month_rounded, 'route': '/mes_rendez_vous_page', 'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0)},
      {'label': 'Commandes', 'icon': Icons.shopping_bag_rounded, 'route': '/mes_commandes', 'color': AppColors.accent, 'bg': const Color(0xFFE3F2FD)},
      {'label': 'Assistant IA', 'icon': Icons.smart_toy_rounded, 'route': '/assistant', 'color': _brandColor, 'bg': _brandColor.withOpacity(0.15)},
      {'label': 'Mon Profil', 'icon': Icons.person_rounded, 'route': '/profil_patient', 'color': _brandColor, 'bg': _brandColor.withOpacity(0.15)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: services.map((s) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, s['route'] as String),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 45, height: 45, decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(12)), child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22)),
                const SizedBox(height: 8),
                Text(s['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Deconnexion", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Voulez-vous vraiment quitter LAMESSIN ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            child: const Text("Se deconnecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, index),
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, index),
              _navItem(Icons.calendar_month_rounded, "RDV", 2, index),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, index),
              _navItem(Icons.person_rounded, "Profil", 4, index),
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