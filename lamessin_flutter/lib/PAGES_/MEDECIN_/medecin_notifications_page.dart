import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../THEME_/app_theme.dart';
import '../../MODELS_/notification_model.dart';
import 'medecin_dashboard.dart';

class MedecinNotificationsPage extends StatefulWidget {
  const MedecinNotificationsPage({super.key});

  @override
  State<MedecinNotificationsPage> createState() => _MedecinNotificationsPageState();
}

class _MedecinNotificationsPageState extends State<MedecinNotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  bool _enActualisation = false;

  final String _imageFond = "assets/images/fond_medecin_dashboard.jpg";

  @override
  void initState() {
    super.initState();
    _chargerNotifications();
  }

  Future<void> _chargerNotifications() async {
    setState(() => _chargement = true);
    try {
      final notifs = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _chargement = false;
          _enActualisation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chargement = false;
          _enActualisation = false;
        });
      }
    }
  }

  Future<void> _actualiser() async {
    setState(() => _enActualisation = true);
    await _chargerNotifications();
  }

  String _formaterDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Date inconnue";
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return "Il y a ${difference.inDays} jour(s)";
      } else if (difference.inHours > 0) {
        return "Il y a ${difference.inHours} heure(s)";
      } else if (difference.inMinutes > 0) {
        return "Il y a ${difference.inMinutes} minute(s)";
      } else {
        return "A l'instant";
      }
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications_rounded;
    if (type.contains('ORDONNANCE')) return Icons.description_rounded;
    if (type.contains('RENDEZ_VOUS')) return Icons.event_rounded;
    if (type.contains('CONSULTATION')) return Icons.medical_information_rounded;
    if (type.contains('COMMANDE')) return Icons.shopping_bag_rounded;
    return Icons.notifications_rounded;
  }

  Color _getColorForType(String? type) {
    if (type == null) return const Color(0xFF00ACC1);
    if (type.contains('ORDONNANCE')) return const Color(0xFF9C27B0);
    if (type.contains('RENDEZ_VOUS')) return const Color(0xFFF57C00);
    if (type.contains('CONSULTATION')) return const Color(0xFF4CAF50);
    if (type.contains('COMMANDE')) return const Color(0xFF2196F3);
    return const Color(0xFF00ACC1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage())),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _actualiser,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          _chargement
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
              : Container(
                  color: Colors.white.withOpacity(0.92),
                  child: RefreshIndicator(
                    onRefresh: _actualiser,
                    color: const Color(0xFF00ACC1),
                    child: _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text("Aucune notification", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                const SizedBox(height: 8),
                                Text("Les notifications apparaetront ici", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            itemBuilder: (_, i) {
                              final notif = _notifications[i];
                              final type = notif.typeNotification;
                              final icone = _getIconForType(type);
                              final couleur = _getColorForType(type);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: couleur.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icone, color: couleur, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.message ?? "Notification",
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formaterDate(notif.heureEnvoi),
                                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notif.lu)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00ACC1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
        ],
      ),
    );
  }
}