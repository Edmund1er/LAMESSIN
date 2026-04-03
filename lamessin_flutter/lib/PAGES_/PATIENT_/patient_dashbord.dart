import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/notification_model.dart';
import '../../THEME_/app_theme.dart';
import '../../WIDGETS_/menu_navigation.dart';

class PageUtilisateur extends StatefulWidget {
  const PageUtilisateur({super.key});
  @override
  State<PageUtilisateur> createState() => _PageUtilisateurState();
}

class _PageUtilisateurState extends State<PageUtilisateur> {
  static const Color _brandColor = Color(0xFF00C2CB);
  String _nomAffichage = "Chargement...";
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  StreamSubscription<RemoteMessage>? _firebaseSubscription;

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
        AppWidgets.showSnack(context,
            "${msg.notification?.title ?? 'Alerte'}: ${msg.notification?.body ?? ''}",
            color: _brandColor);
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
      final diff =
          DateTime.now().difference(DateTime.parse(dateStr).toLocal());
      if (diff.inSeconds < 60) return "Il y a ${diff.inSeconds} s";
      if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
      if (diff.inHours < 24)   return "Il y a ${diff.inHours} h";
      return "Il y a ${diff.inDays} j";
    } catch (_) { return "Récemment"; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/fond_patient.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _chargerDonneesProfil,
                color: _brandColor,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverHeader(),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white.withOpacity(0.75),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle("Notifications récentes"),
                              const SizedBox(height: 12),
                              if (_notifications.isEmpty)
                                _buildEmptyNotif()
                              else
                                ..._notifications.take(5).map(_buildNotifCard),
                              const SizedBox(height: 24),
                              _sectionTitle("Nos Services"),
                              const SizedBox(height: 14),
                              _buildGrilleServices(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () =>
              Navigator.pushNamed(context, '/historique_notifications'),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.power_settings_new_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () => _confirmerDeconnexion(context),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.only(left: 22, bottom: 24, top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bonjour,",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 15)),
              const SizedBox(height: 4),
              Text("M. $_nomAffichage 👋",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary));

  Widget _buildNotifCard(NotificationModel notif) {
    final String type = notif.typeNotification ?? "GENERAL";
    IconData icone = Icons.notifications_rounded;
    Color couleur  = _brandColor;
    if (type.contains('ORDONNANCE')) { icone = Icons.description_rounded; couleur = _brandColor; }
    else if (type.contains('RENDEZ_VOUS')) { icone = Icons.event_rounded; couleur = AppColors.warning; }
    else if (type.contains('COMMANDE')) { icone = Icons.shopping_bag_rounded; couleur = AppColors.accent; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: couleur, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => _afficherDetailNotif(notif.message ?? ""),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 18, color: couleur),
        ),
        title: Text(notif.message ?? "Nouveau message",
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        subtitle: Text(_calculerTempsEcoule(notif.heureEnvoi),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildEmptyNotif() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: [
        Icon(Icons.notifications_off_outlined,
            color: Colors.grey[400], size: 40),
        const SizedBox(height: 8),
        const Text("Aucune notification",
            style: TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildGrilleServices() {
    final services = [
      {'label':'Pharmacies','icon':Icons.local_pharmacy_rounded,'route':'/recherches_services_medicaux','color':_brandColor,'bg':_brandColor.withOpacity(0.15)},
      {'label':'Traitements','icon':Icons.medication_rounded,'route':'/suivi_traitements','color':const Color(0xFF22863A),'bg':AppColors.successLight},
      {'label':'Rendez-vous','icon':Icons.calendar_month_rounded,'route':'/mes_rendez_vous_page','color':const Color(0xFFE65100),'bg':AppColors.warningLight},
      {'label':'Commandes','icon':Icons.shopping_bag_rounded,'route':'/mes_commandes','color':AppColors.accent,'bg':AppColors.dangerLight},
      {'label':'Assistant IA','icon':Icons.smart_toy_rounded,'route':'/assistant','color':_brandColor,'bg':_brandColor.withOpacity(0.15)},
      {'label':'Mon Profil','icon':Icons.account_circle_rounded,'route':'/profil_patient','color':_brandColor,'bg':_brandColor.withOpacity(0.15)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 6, 
      mainAxisSpacing: 6,
      childAspectRatio: 1.0,
      children: services.map((s) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, s['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 3)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: s['bg'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s['icon'] as IconData,
                      color: s['color'] as Color, size: 16),
                ),
                const SizedBox(height: 4),
                Text(s['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
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
        title: const Text("Déconnexion",
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Voulez-vous vraiment quitter LAMESSIN ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted)
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
            },
            child: const Text("Se déconnecter",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _afficherDetailNotif(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Notification",
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}