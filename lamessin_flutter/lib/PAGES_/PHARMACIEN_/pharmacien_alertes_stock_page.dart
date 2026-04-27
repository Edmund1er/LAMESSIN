import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/medicament_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
// SUPPRIME: import 'pharmacien_scan_ordonnance_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienAlertesStockPage extends StatefulWidget {
  const PharmacienAlertesStockPage({super.key});

  @override
  State<PharmacienAlertesStockPage> createState() => _PharmacienAlertesStockPageState();
}

class _PharmacienAlertesStockPageState extends State<PharmacienAlertesStockPage> {
  List<StockPharmacie> _alertes = [];
  bool _chargement = true;
  String _typeAlerte = "toutes";

  final String _imageFond = "assets/images/fond_pharmacien_alertes.jpg";

  @override
  void initState() {
    super.initState();
    _chargerAlertes();
  }

  Future<void> _chargerAlertes() async {
    setState(() => _chargement = true);
    try {
      final alertes = await PharmacyService.getAlertesStock();
      if (mounted) {
        setState(() {
          _alertes = alertes;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<StockPharmacie> get _alertesFiltrees {
    if (_typeAlerte == "rupture") {
      return _alertes.where((a) => a.quantiteEnStock == 0).toList();
    } else if (_typeAlerte == "alerte") {
      return _alertes.where((a) => a.quantiteEnStock > 0 && a.quantiteEnStock <= 10).toList();
    }
    return _alertes;
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
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
        title: const Text("Alertes stock", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerAlertes),
        ],
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
                // Filtres
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _filtreChip("Toutes", "toutes"),
                      const SizedBox(width: 8),
                      _filtreChip("Rupture", "rupture"),
                      const SizedBox(width: 8),
                      _filtreChip("Alerte", "alerte"),
                    ],
                  ),
                ),
                Expanded(
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                      : _alertesFiltrees.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _chargerAlertes,
                              color: const Color(0xFF00ACC1),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _alertesFiltrees.length,
                                itemBuilder: (_, i) => _buildAlerteCard(_alertesFiltrees[i]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  Widget _filtreChip(String label, String valeur) {
    bool actif = _typeAlerte == valeur;
    return FilterChip(
      label: Text(label),
      selected: actif,
      onSelected: (_) => setState(() => _typeAlerte = valeur),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF00ACC1).withOpacity(0.1),
      labelStyle: TextStyle(color: actif ? const Color(0xFF00ACC1) : Colors.grey, fontWeight: actif ? FontWeight.w600 : FontWeight.normal),
      checkmarkColor: const Color(0xFF00ACC1),
    );
  }

  Widget _buildAlerteCard(StockPharmacie stock) {
    final bool estRupture = stock.quantiteEnStock == 0;
    Color bgColor;
    Color borderColor;
    String statutLabel;
    if (estRupture) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
      statutLabel = "RUPTURE";
    } else {
      bgColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFF57C00);
      statutLabel = "ALERTE";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)), child: Icon(estRupture ? Icons.inventory_2_rounded : Icons.warning_rounded, color: borderColor, size: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.nomPharmacie, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text("Stock actuel: ${stock.quantiteEnStock} unite(s)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: borderColor)),
                if (stock.datePeremption.isNotEmpty) Text("Peremption: ${stock.datePeremption}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(statutLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: borderColor))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showReapprovisionnementDialog(stock),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF00ACC1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text("Reapprovisionner", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00ACC1)))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReapprovisionnementDialog(StockPharmacie stock) {
    final qteCtrl = TextEditingController();
    bool loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/fond_patient.jpg"), fit: BoxFit.cover)),
          child: Container(
            color: Colors.white.withOpacity(0.95),
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.nomPharmacie, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("Stock actuel: ${stock.quantiteEnStock} unites", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                    child: TextField(
                      controller: qteCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: "Nouvelle quantite",
                        prefixIcon: Icon(Icons.add_box_rounded, color: Color(0xFF00ACC1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        final qte = int.tryParse(qteCtrl.text);
                        if (qte == null || qte <= 0) {
                          AppWidgets.showSnack(ctx, "Veuillez entrer une quantite valide", color: Colors.orange);
                          return;
                        }
                        setModal(() => loading = true);
                        final ok = await PharmacyService.updateStock(stock.idStock, qte);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok) {
                          _chargerAlertes();
                          AppWidgets.showSnack(context, "Stock mis a jour avec succes", color: const Color(0xFF4CAF50));
                        } else {
                          AppWidgets.showSnack(context, "Erreur lors de la mise a jour", color: Colors.red);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Mettre a jour le stock", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 36)),
          const SizedBox(height: 16),
          const Text("Aucune alerte stock", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 6),
          const Text("Tous les produits sont bien approvisionnes", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
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
              _navItem(Icons.warning_rounded, "Alertes", 2, index),
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