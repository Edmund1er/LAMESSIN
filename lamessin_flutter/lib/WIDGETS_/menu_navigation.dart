import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';
import '../MODELS_/utilisateur_model.dart';
import '../THEME_/app_theme.dart';

class MenuNavigation extends StatefulWidget {
  const MenuNavigation({super.key});
  @override
  State<MenuNavigation> createState() => _MenuNavigationState();
}

class _MenuNavigationState extends State<MenuNavigation> {
  dynamic _donneesRecues;
  bool _chargement = true;

  @override
  void initState() { super.initState(); _chargerDonneesProfil(); }

  Future<void> _chargerDonneesProfil() async {
    try {
      final resultat = await ApiService.getProfil();
      if (mounted) setState(() { _donneesRecues = resultat; _chargement = false; });
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String nom = "Utilisateur", prenom = "", infoSante = "Chargement...";
    if (_donneesRecues != null) {
      if (_donneesRecues is Patient) {
        nom = _donneesRecues.compteUtilisateur.lastName;
        prenom = _donneesRecues.compteUtilisateur.firstName;
        infoSante = "Groupe: ${_donneesRecues.groupeSanguin ?? 'Inconnu'}";
      } else if (_donneesRecues is Utilisateur) {
        nom = _donneesRecues.lastName;
        prenom = _donneesRecues.firstName;
        infoSante = "Profil Patient";
      }
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(children: [
        // ── HEADER ──
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 24, left: 20, right: 20,
          ),
          child: Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: _chargement
                  ? const Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)))
                  : Center(child: Text(
                      nom.isNotEmpty ? nom[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("$prenom $nom",
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(infoSante,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ])),
          ]),
        ),

        // ── ITEMS ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _item(context, Icons.dashboard_rounded, "Tableau de bord", "/page_utilisateur"),
              _item(context, Icons.add_circle_rounded, "Prendre rendez-vous", "/rendez_vous_page"),
              _item(context, Icons.event_note_rounded, "Mes rendez-vous", "/mes_rendez_vous_page"),
              _item(context, Icons.medication_rounded, "Suivi traitements", "/suivi_traitements"),
              _item(context, Icons.local_pharmacy_rounded, "Établissements", "/recherches_services_medicaux"),
              _item(context, Icons.smart_toy_rounded, "Assistant IA", "/assistant"),
              _item(context, Icons.history_rounded, "Historique chat", "/historique_chatbot"),
              _item(context, Icons.shopping_bag_rounded, "Mes commandes", "/mes_commandes"),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppColors.borderLight),
              ),
              _item(context, Icons.account_circle_rounded, "Mon profil", "/profil_patient"),
            ],
          ),
        ),

        // ── DÉCONNEXION ──
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const Icon(Icons.power_settings_new_rounded, color: AppColors.danger),
            title: const Text("Déconnexion",
                style: TextStyle(color: AppColors.danger,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            onTap: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/login", (route) => false);
              }
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }

  Widget _item(BuildContext context, IconData icon, String titre, String route) {
    final String? routeActuelle = ModalRoute.of(context)?.settings.name;
    final bool actif = routeActuelle == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: actif ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: actif ? AppColors.primary : AppColors.textSecondary, size: 22),
        title: Text(titre, style: TextStyle(
            fontSize: 14,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? AppColors.primary : AppColors.textPrimary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          if (!actif) Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}