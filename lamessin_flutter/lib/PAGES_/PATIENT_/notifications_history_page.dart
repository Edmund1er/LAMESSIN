import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/notification_model.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Palette de couleurs cohérente avec ton application
    const Color couleurBleue = Color(0xFF1A73E8);
    const Color couleurTeal = Color(0xFF00A896);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fond légèrement grisé pour faire ressortir les cartes
      appBar: AppBar(
        title: const Text(
          "Historique des notifications",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: couleurBleue,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: ApiService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: couleurBleue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text("Erreur: ${snapshot.error}"),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Aucune notification pour le moment",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: couleurTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: couleurTeal,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notif.message ?? "Notification sans contenu",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 5),
                          Text(
                            notif.heureEnvoi ?? "--:--",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
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