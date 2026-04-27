import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/notification_model.dart';
import '../../THEME_/app_theme.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        title: const Text("Historique des notifications", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: FutureBuilder<List<NotificationModel>>(
              future: ApiService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.danger)),
                        const SizedBox(height: 16),
                        Text("Erreur : ${snapshot.error}", style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF00ACC1).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.notifications_off_outlined, size: 36, color: Color(0xFF00ACC1))),
                        const SizedBox(height: 16),
                        const Text("Aucune notification pour le moment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                        const SizedBox(height: 6),
                        const Text("Vos alertes apparaitront ici", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (_, index) {
                    final notif = notifications[index];
                    final String type = notif.typeNotification ?? "GENERAL";
                    IconData icone = Icons.notifications_rounded;
                    Color couleur = const Color(0xFF00ACC1);
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 38, height: 38, decoration: BoxDecoration(color: couleur.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icone, size: 18, color: couleur)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notif.message ?? "Notification sans contenu", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(notif.heureEnvoi ?? "--:--", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}