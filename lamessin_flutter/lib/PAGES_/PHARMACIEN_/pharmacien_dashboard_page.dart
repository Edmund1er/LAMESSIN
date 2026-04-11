import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/statistiques_pharmacien_model.dart';
import '../../MODELS_/commande_model.dart';
import '../../MODELS_/notification_model.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienDashboardPage extends StatefulWidget {
  const PharmacienDashboardPage({super.key});
  @override
  State<PharmacienDashboardPage> createState() =>
      _PharmacienDashboardPageState();
}

class _PharmacienDashboardPageState extends State<PharmacienDashboardPage> {
  StatistiquesPharmacien? _stats;
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  String _nomPharmacien = "Pharmacien";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final results = await Future.wait([
        PharmacyService.getDashboard(),
        ApiService.getNotifications(),
        ApiService.getProfil(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as StatistiquesPharmacien?;
          _notifications = results[1] as List<NotificationModel>;
          final profil = results[2];
          if (profil != null) {
            _nomPharmacien =
                "${profil.compteUtilisateur.firstName} ${profil.compteUtilisateur.lastName}";
          }
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStats(),
                          const SizedBox(height: 24),
                          _sectionTitle("Commandes récentes"),
                          const SizedBox(height: 12),
                          _buildCommandesRecentes(),
                          const SizedBox(height: 24),
                          _sectionTitle("Notifications récentes"),
                          const SizedBox(height: 12),
                          _buildNotifications(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  // ========================= HEADER =========================

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        // Badge notifications
        Stack(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {},
            ),
            if (_notifications.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${_notifications.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.primary,
          padding: const EdgeInsets.only(left: 22, bottom: 24, top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bonjour,",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$_nomPharmacien 💊",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Pharmacien",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= STATS =========================

  Widget _buildStats() {
    final s = _stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                "Commandes\nen attente",
                s?.commandesAttente ?? 0,
                Icons.shopping_bag_rounded,
                AppColors.primary,
                AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                "Total\ncommandes",
                s?.commandesTotal ?? 0,
                Icons.receipt_long_rounded,
                const Color(0xFF22863A),
                AppColors.successLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                "Alertes\nstock",
                s?.produitsAlerte ?? 0,
                Icons.warning_rounded,
                const Color(0xFFE65100),
                AppColors.warningLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCardLarge(
                "Chiffre d'affaires total",
                "${(s?.caTotal ?? 0).toStringAsFixed(0)} FCFA",
                Icons.payments_rounded,
                AppColors.primary,
                AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCardLarge(
                "Produits en rupture",
                "${s?.produitsEnRupture ?? 0}",
                Icons.inventory_2_rounded,
                const Color(0xFFB71C1C),
                const Color(0xFFFFEBEE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statCardLarge(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================= COMMANDES RECENTES =========================

  Widget _buildCommandesRecentes() {
    final commandes = _stats?.commandesRecentes ?? [];
    if (commandes.isEmpty) {
      return _buildEmpty(
        "Aucune commande récente",
        Icons.shopping_bag_outlined,
      );
    }
    return Column(
      children: commandes.take(5).map((c) => _buildCommandeCard(c)).toList(),
    );
  }

  Widget _buildCommandeCard(Commande c) {
    Color statutColor;
    Color statutBg;
    switch (c.statut.toUpperCase()) {
      case 'EN_ATTENTE':
        statutColor = const Color(0xFFE65100);
        statutBg = AppColors.warningLight;
        break;
      case 'VALIDEE':
      case 'PAYEE':
        statutColor = const Color(0xFF22863A);
        statutBg = AppColors.successLight;
        break;
      default:
        statutColor = AppColors.textSecondary;
        statutBg = AppColors.surfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.patientNom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "${c.lignes.length} produit(s) · ${c.total.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statutBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              c.statut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statutColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= NOTIFICATIONS =========================

  Widget _buildNotifications() {
    if (_notifications.isEmpty) {
      return _buildEmpty(
        "Aucune notification",
        Icons.notifications_off_outlined,
      );
    }
    return Column(
      children: _notifications
          .take(3)
          .map(
            (n) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      n.message ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ========================= DRAWER =========================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nomPharmacien,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Pharmacien",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_rounded,
                    label: "Tableau de bord",
                    actif: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.medication_rounded,
                    label: "Mes produits",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/produits');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.borderLight),
                  ),
                  _drawerItem(
                    icon: Icons.account_circle_rounded,
                    label: "Mon profil",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/Profil_medecin');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (r) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(
                      color: AppColors.dangerLight,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text(
                    "Se déconnecter",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    bool actif = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: actif ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: actif ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ========================= UTILS =========================

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildEmpty(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index, () {}),
              _navItem(
                Icons.medication_rounded,
                "Produits",
                1,
                index,
                () => Navigator.pushReplacementNamed(context, '/produits'),
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                2,
                index,
                () => Navigator.pushReplacementNamed(context, '/Profil_medecin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int idx,
    int current,
    VoidCallback onTap,
  ) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: actif ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: actif ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}