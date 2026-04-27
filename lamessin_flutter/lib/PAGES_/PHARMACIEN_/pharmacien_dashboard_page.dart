import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/statistiques_pharmacien_model.dart';
import '../../MODELS_/commande_model.dart';
import '../../MODELS_/notification_model.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_profil_page.dart';
import 'pharmacien_alertes_stock_page.dart';
import 'pharmacien_notifications_page.dart';

class PharmacienDashboardPage extends StatefulWidget {
  const PharmacienDashboardPage({super.key});

  @override
  State<PharmacienDashboardPage> createState() => _PharmacienDashboardPageState();
}

class _PharmacienDashboardPageState extends State<PharmacienDashboardPage> {
  StatistiquesPharmacien? _stats;
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  String _nomPharmacien = "Pharmacien";

  final String _imageFond = "assets/images/fond_pharmacien_dashboard.jpg";

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
          if (profil != null && profil is Pharmacien) {
            _nomPharmacien = "${profil.compteUtilisateur.firstName} ${profil.compteUtilisateur.lastName}";
          }
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProduitsPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProfilPage()));
    }
  }

  void _openNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacienNotificationsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              color: const Color(0xFF00ACC1),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
                  ),
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 160,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: _openNotifications,
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF00ACC1).withOpacity(0.85),
                                  const Color(0xFF00ACC1).withOpacity(0.7),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Builder(
                                  builder: (context) => GestureDetector(
                                    onTap: () => Scaffold.of(context).openDrawer(),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ),
                                const Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white.withOpacity(0.92),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStats(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Commandes recentes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage())),
                                      child: const Text("Voir tout", style: TextStyle(color: Color(0xFF00ACC1))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildCommandesRecentes(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Alertes stock", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienAlertesStockPage())),
                                      child: const Text("Voir tout", style: TextStyle(color: Color(0xFF00ACC1))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildAlerteStock(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Notifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    TextButton(
                                      onPressed: _openNotifications,
                                      child: const Text("Voir tout", style: TextStyle(color: Color(0xFF00ACC1))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildNotifications(),
                                const SizedBox(height: 30),
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

  Widget _buildStats() {
    final s = _stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard("En attente", s?.commandesAttente ?? 0, Icons.hourglass_empty_rounded, const Color(0xFFF57C00), const Color(0xFFFFF3E0))),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Total", s?.commandesTotal ?? 0, Icons.receipt_long_rounded, const Color(0xFF4CAF50), const Color(0xFFE8F5E9))),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Alertes", s?.produitsAlerte ?? 0, Icons.warning_rounded, const Color(0xFFF57C00), const Color(0xFFFFF3E0))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCardLarge("CA total", "${(s?.caTotal ?? 0).toStringAsFixed(0)} FCFA", Icons.payments_rounded, const Color(0xFF00ACC1), const Color(0xFFE0F7FA))),
            const SizedBox(width: 12),
            Expanded(child: _statCardLarge("Rupture", "${s?.produitsEnRupture ?? 0}", Icons.inventory_2_rounded, const Color(0xFFEF5350), const Color(0xFFFFEBEE))),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 6),
          Text("$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _statCardLarge(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandesRecentes() {
    final commandes = _stats?.commandesRecentes ?? [];
    if (commandes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text("Aucune commande", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return Column(children: commandes.take(3).map((c) => _buildCommandeCard(c)).toList());
  }

  Widget _buildCommandeCard(Commande c) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientNom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text("${c.lignes.length} produit(s)  ${c.total.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
    Map<String, dynamic> style = _getStatutStyle(statut);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(20)), child: Text(style['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: style['color'])));
  }

  Map<String, dynamic> _getStatutStyle(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE': return {'label': 'En attente', 'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0)};
      case 'PAYE': return {'label': 'Payee', 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9)};
      case 'LIVRE': return {'label': 'Livree', 'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD)};
      default: return {'label': statut, 'color': Colors.grey, 'bg': Colors.grey[100]!};
    }
  }

  Widget _buildAlerteStock() {
    final alertes = _stats?.produitsAlerte ?? 0;
    if (alertes == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text("Aucune alerte stock", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienAlertesStockPage())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEF5350))),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFEF5350), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$alertes produit(s) en alerte", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF5350))),
                  const Text("Voir les produits en rupture ou stock faible", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    if (_notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text("Aucune notification", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return Column(children: _notifications.take(3).map((n) => _buildNotifCard(n)).toList());
  }

  Widget _buildNotifCard(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded, color: Color(0xFF00ACC1), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(n.message ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF00ACC1), const Color(0xFF00ACC1).withOpacity(0.8)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 12),
                  Text(_nomPharmacien, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Text("Pharmacien", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _drawerItem(Icons.dashboard_rounded, "Dashboard", true, () => Navigator.pop(context)),
                  _drawerItem(Icons.shopping_bag_rounded, "Commandes", false, () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage())); }),
                  _drawerItem(Icons.medication_rounded, "Produits & Stocks", false, () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProduitsPage())); }),
                  _drawerItem(Icons.warning_rounded, "Alertes stock", false, () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienAlertesStockPage())); }),
                  const Divider(),
                  _drawerItem(Icons.account_circle_rounded, "Mon profil", false, () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProfilPage())); }),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("Se deconnecter", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
      decoration: BoxDecoration(color: actif ? const Color(0xFF00ACC1).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: actif ? const Color(0xFF00ACC1) : Colors.grey, size: 20),
        title: Text(label, style: TextStyle(fontSize: 13, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: actif ? const Color(0xFF00ACC1) : Colors.black87)),
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
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index),
              _navItem(Icons.shopping_bag_rounded, "Commandes", 1, index),
              _navItem(Icons.medication_rounded, "Produits", 2, index),
              _navItem(Icons.person_rounded, "Profil", 3, index),
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
          Icon(icon, color: actif ? const Color(0xFF00ACC1) : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? const Color(0xFF00ACC1) : Colors.grey)),
        ],
      ),
    );
  }
}