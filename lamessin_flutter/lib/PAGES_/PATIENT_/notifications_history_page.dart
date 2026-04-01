import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/notification_model.dart';
import '../../THEME_/app_theme.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar("Historique des notifications"),
      body: FutureBuilder<List<NotificationModel>>(
        future: ApiService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 36, color: AppColors.danger)),
              const SizedBox(height: 16),
              Text("Erreur : ${snapshot.error}",
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ]));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.notifications_off_outlined,
                      size: 36, color: AppColors.primary)),
              const SizedBox(height: 16),
              const Text("Aucune notification pour le moment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text("Vos alertes apparaîtront ici",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (_, index) {
              final notif = notifications[index];
              final String type = notif.typeNotification ?? "GENERAL";
              IconData icone = Icons.notifications_active_rounded;
              Color couleur  = AppColors.primary;
              if (type.contains('ORDONNANCE')) { icone = Icons.description_rounded; couleur = AppColors.primary; }
              else if (type.contains('RENDEZ_VOUS')) { icone = Icons.event_rounded; couleur = AppColors.warning; }
              else if (type.contains('COMMANDE')) { icone = Icons.shopping_bag_rounded; couleur = AppColors.accent; }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: couleur, width: 4)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icone, size: 18, color: couleur),
                  ),
                  title: Text(notif.message ?? "Notification sans contenu",
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(notif.heureEnvoi ?? "--:--",
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
