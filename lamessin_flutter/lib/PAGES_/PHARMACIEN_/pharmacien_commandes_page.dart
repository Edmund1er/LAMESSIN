import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/commande_model.dart';
import 'pharmacien_detail_commande_page.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienCommandesPage extends StatefulWidget {
  const PharmacienCommandesPage({super.key});

  @override
  State<PharmacienCommandesPage> createState() => _PharmacienCommandesPageState();
}

class _PharmacienCommandesPageState extends State<PharmacienCommandesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Commande> _commandes = [];
  bool _chargement = true;
  String _recherche = "";

  final String _imageFond = "assets/images/fond_pharmacien_commandes.jpg";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerCommandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerCommandes() async {
    setState(() => _chargement = true);
    try {
      final commandes = await PharmacyService.getCommandes(filtre: 'toutes');
      if (mounted) {
        setState(() {
          _commandes = commandes;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Commande> get _commandesFiltrees => _commandes.where((c) => c.patientNom.toLowerCase().contains(_recherche.toLowerCase())).toList();

  List<Commande> get _commandesEnAttente => _commandesFiltrees.where((c) => c.statut.toUpperCase() == 'EN_ATTENTE').toList();
  List<Commande> get _commandesPayees => _commandesFiltrees.where((c) => c.statut.toUpperCase() == 'PAYE').toList();
  List<Commande> get _commandesLivrees => _commandesFiltrees.where((c) => c.statut.toUpperCase() == 'LIVRE').toList();

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage()));
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProduitsPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProfilPage()));
    }
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
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage())),
        ),
        title: const Text("Commandes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: "En attente"),
            Tab(text: "Payees"),
            Tab(text: "Livrees"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                    child: TextField(
                      onChanged: (v) => setState(() => _recherche = v),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Rechercher un patient...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildListeCommandes(_commandesEnAttente, "en_attente"),
                            _buildListeCommandes(_commandesPayees, "payee"),
                            _buildListeCommandes(_commandesLivrees, "livree"),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  Widget _buildListeCommandes(List<Commande> commandes, String type) {
    if (commandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(type), size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_getEmptyMessage(type), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerCommandes,
      color: const Color(0xFF00ACC1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commandes.length,
        itemBuilder: (_, i) => _buildCommandeCard(commandes[i]),
      ),
    );
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case "en_attente": return "Aucune commande en attente";
      case "payee": return "Aucune commande payee";
      default: return "Aucune commande livree";
    }
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case "en_attente": return Icons.hourglass_empty_rounded;
      case "payee": return Icons.payments_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  Widget _buildCommandeCard(Commande c) {
    Map<String, dynamic> style = _getStatutStyle(c.statut);
    return GestureDetector(
      onTap: () => _voirDetails(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(15)), child: Icon(Icons.shopping_bag_rounded, color: style['color'], size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientNom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("${c.lignes.length} produit(s)  ${c.total.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(c.dateCreation.substring(0, 10), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(20)), child: Text(style['label'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: style['color']))),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatutStyle(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE': return {'label': 'En attente', 'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0)};
      case 'PAYE': return {'label': 'Payee', 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9)};
      case 'LIVRE': return {'label': 'Livree', 'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD)};
      default: return {'label': statut, 'color': Colors.grey, 'bg': Colors.grey[100]!};
    }
  }

  void _voirDetails(Commande commande) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => PharmacienDetailCommandePage(commande: commande))).then((_) => _chargerCommandes());
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