import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';
import '../THEME_/app_theme.dart';

class MenuNavigation extends StatelessWidget {
  const MenuNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF00ACC1),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 24, left: 20, right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              const Text("LAMESSIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const Text("Menu", style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _item(context, Icons.history_rounded, "Historique chatbot", "/historique_chatbot"),
              _item(context, Icons.notifications_rounded, "Notifications", "/historique_notifications"),
              const Divider(),
              _item(context, Icons.logout_rounded, "Deconnexion", "/login", isLogout: true),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _item(BuildContext context, IconData icon, String titre, String route, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? AppColors.danger : AppColors.textSecondary, size: 22),
        title: Text(titre, style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isLogout ? AppColors.danger : AppColors.textPrimary,
        )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () async {
          Navigator.pop(context);
          if (isLogout) {
            await ApiService.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
            }
          } else {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}