import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/statistiques_pharmacien_model.dart';
import '../../MODELS_/commande_model.dart';
import '../../MODELS_/notification_model.dart';

// Import de toutes les pages pharmacien
import 'pharmacien_produits_page.dart';
import 'pharmacien_profil_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_scan_ordonnance_page.dart';
import 'pharmacien_alertes_stock_page.dart';

class PharmacienDashboardPage extends StatefulWidget {
  const PharmacienDashboardPage({super.key});
  @override
  State<PharmacienDashboardPage> createState() =>
      _PharmacienDashboardPageState();
}

class _PharmacienDashboardPageState extends State<PharmacienDashboardPage> {
  // Statistiques du pharmacien
  StatistiquesPharmacien? _stats;
  // Liste des notifications
  List<NotificationModel> _notifications = [];
  // Etat du chargement
  bool _chargement = true;
  // Nom du pharmacien
  String _nomPharmacien = "Pharmacien";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  // Charge toutes les donnees
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
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_pharmacien_dashboard.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: _chargement
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C2CB)),
              )
            : RefreshIndicator(
                onRefresh: _chargerDonnees,
                color: const Color(0xFF00C2CB),
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white.withOpacity(0.75),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStats(),
                              const SizedBox(height: 24),
                              _sectionTitle("Acces rapide"),
                              const SizedBox(height: 12),
                              _buildAccesRapide(),
                              const SizedBox(height: 24),
                              _sectionTitle("Commandes recentes"),
                              const SizedBox(height: 12),
                              _buildCommandesRecentes(),
                              const SizedBox(height: 24),
                              _sectionTitle("Alertes stock"),
                              const SizedBox(height: 12),
                              _buildAlerteStock(),
                              const SizedBox(height: 24),
                              _sectionTitle("Notifications"),
                              const SizedBox(height: 12),
                              _buildNotifications(),
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
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  // ========================= HEADER =========================

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
              onPressed: () => Navigator.pushNamed(
                context,
                '/historique_notifications',
              ),
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
          color: const Color(0xFF00C2CB),
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

  // ========================= ACCES RAPIDE =========================

  Widget _buildAccesRapide() {
    final actions = [
      {"icon": Icons.qr_code_scanner_rounded, "label": "Scanner", "route": "/scan_ordonnance_pharmacien", "color": const Color(0xFF00C2CB)},
      {"icon": Icons.shopping_bag_rounded, "label": "Commandes", "route": "/commandes_pharmacien", "color": const Color(0xFF00C2CB)},
      {"icon": Icons.warning_rounded, "label": "Alertes", "route": "/alertes_stock_pharmacien", "color": const Color(0xFFE65100)},
      {"icon": Icons.add_box_rounded, "label": "Ajouter", "route": "/produits_pharmacien", "color": const Color(0xFF00C2CB)},
      {"icon": Icons.medication_rounded, "label": "Stocks", "route": "/produits_pharmacien", "color": const Color(0xFF00C2CB)},
      {"icon": Icons.person_rounded, "label": "Profil", "route": "/profil_pharmacien", "color": const Color(0xFF00C2CB)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, a['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  a['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========================= STATISTIQUES =========================

  Widget _buildStats() {
    final s = _stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                "En attente",
                s?.commandesAttente ?? 0,
                Icons.hourglass_empty_rounded,
                const Color(0xFFE65100),
                AppColors.warningLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                "Total",
                s?.commandesTotal ?? 0,
                Icons.receipt_long_rounded,
                const Color(0xFF22863A),
                AppColors.successLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                "Alertes",
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
                "CA total",
                "${(s?.caTotal ?? 0).toStringAsFixed(0)} FCFA",
                Icons.payments_rounded,
                const Color(0xFF00C2CB),
                const Color(0xFF00C2CB).withOpacity(0.15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCardLarge(
                "Rupture",
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

  Widget _statCard(String label, int value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text("$value", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _statCardLarge(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================= ALERTES STOCK =========================

  Widget _buildAlerteStock() {
    final alertes = _stats?.produitsAlerte ?? 0;
    if (alertes == 0) {
      return _buildEmpty("Aucune alerte stock", Icons.check_circle_rounded);
    }
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/alertes_stock_pharmacien'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB71C1C)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFB71C1C), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$alertes produit(s) en alerte",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                  const Text(
                    "Voir les produits en rupture ou stock faible",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ========================= COMMANDES RECENTES =========================

  Widget _buildCommandesRecentes() {
    final commandes = _stats?.commandesRecentes ?? [];
    if (commandes.isEmpty) {
      return _buildEmpty("Aucune commande", Icons.shopping_bag_outlined);
    }
    return Column(
      children: commandes.take(5).map((c) => _buildCommandeCard(c)).toList(),
    );
  }

  Widget _buildCommandeCard(Commande c) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/commandes_pharmacien'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF00C2CB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF00C2CB), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientNom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text("${c.lignes.length} produit(s) · ${c.total.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            _buildStatutBadge(c.statut),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    Color bgColor;
    String label;

    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        color = const Color(0xFFE65100);
        bgColor = AppColors.warningLight;
        label = "Attente";
        break;
      case 'PAYE':
        color = const Color(0xFF22863A);
        bgColor = AppColors.successLight;
        label = "Payee";
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey[100]!;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ========================= NOTIFICATIONS =========================

  Widget _buildNotifications() {
    if (_notifications.isEmpty) {
      return _buildEmpty("Aucune notification", Icons.notifications_off_outlined);
    }
    return Column(
      children: _notifications.take(3).map((n) => _buildNotifCard(n)).toList(),
    );
  }

  Widget _buildNotifCard(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: const Color(0xFF00C2CB), width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded, color: Color(0xFF00C2CB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              n.message ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= DRAWER =========================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: const Color(0xFF00C2CB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(_nomPharmacien, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Pharmacien", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _drawerItem(Icons.dashboard_rounded, "Dashboard", true, () => Navigator.pop(context)),
                  _drawerItem(Icons.shopping_bag_rounded, "Commandes", false, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/commandes_pharmacien');
                  }),
                  _drawerItem(Icons.medication_rounded, "Produits & Stocks", false, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/produits_pharmacien');
                  }),
                  _drawerItem(Icons.qr_code_scanner_rounded, "Scanner ordonnance", false, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/scan_ordonnance_pharmacien');
                  }),
                  _drawerItem(Icons.warning_rounded, "Alertes stock", false, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/alertes_stock_pharmacien');
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.grey),
                  ),
                  _drawerItem(Icons.account_circle_rounded, "Mon profil", false, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profil_pharmacien');
                  }),
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
                    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.dangerLight, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text("Se deconnecter", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, bool actif, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: actif ? const Color(0xFF00C2CB).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: actif ? const Color(0xFF00C2CB) : Colors.grey, size: 22),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: actif ? const Color(0xFF00C2CB) : AppColors.textPrimary)),
      ),
    );
  }

  // ========================= UTILS =========================

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

  Widget _buildEmpty(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [Icon(icon, color: Colors.grey, size: 32), const SizedBox(height: 8), Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13))]),
    );
  }

  // ========================= BOTTOM NAV =========================

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index, () => Navigator.pushReplacementNamed(context, '/dashboard_pharmacien')),
              _navItem(Icons.shopping_bag_rounded, "Commandes", 1, index, () => Navigator.pushReplacementNamed(context, '/commandes_pharmacien')),
              _navItem(Icons.medication_rounded, "Produits", 2, index, () => Navigator.pushReplacementNamed(context, '/produits_pharmacien')),
              _navItem(Icons.qr_code_scanner_rounded, "Scanner", 3, index, () => Navigator.pushReplacementNamed(context, '/scan_ordonnance_pharmacien')),
              _navItem(Icons.account_circle_rounded, "Profil", 4, index, () => Navigator.pushReplacementNamed(context, '/profil_pharmacien')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current, VoidCallback onTap) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actif ? const Color(0xFF00C2CB) : Colors.grey, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: actif ? const Color(0xFF00C2CB) : Colors.grey)),
        ],
      ),
    );
  }
}