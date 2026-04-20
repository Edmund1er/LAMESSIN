import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/medicament_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_scan_ordonnance_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienAlertesStockPage extends StatefulWidget {
  const PharmacienAlertesStockPage({super.key});
  @override
  State<PharmacienAlertesStockPage> createState() => _PharmacienAlertesStockPageState();
}

class _PharmacienAlertesStockPageState extends State<PharmacienAlertesStockPage> {
  // Liste des alertes stock
  List<StockPharmacie> _alertes = [];
  // Etat du chargement
  bool _chargement = true;
  // Type d'alerte selectionne
  String _typeAlerte = "toutes"; // toutes, rupture, alerte

  @override
  void initState() {
    super.initState();
    _chargerAlertes();
  }

  // Charge les alertes stock depuis le backend
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

  // Filtre les alertes selon le type selectionne
  List<StockPharmacie> get _alertesFiltrees {
    if (_typeAlerte == "rupture") {
      return _alertes.where((a) => a.quantiteEnStock == 0).toList();
    } else if (_typeAlerte == "alerte") {
      return _alertes.where((a) => a.quantiteEnStock > 0 && a.quantiteEnStock <= 10).toList();
    }
    return _alertes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: const Text(
          "Alertes stock",
          style: TextStyle(
            color: Color(0xFF00C2CB),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF00C2CB)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_patient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.75),
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

              // Contenu
              Expanded(
                child: _chargement
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00C2CB)),
                      )
                    : _alertesFiltrees.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _chargerAlertes,
                            color: const Color(0xFF00C2CB),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _alertesFiltrees.length,
                              itemBuilder: (_, i) => _buildAlerteCard(_alertesFiltrees[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  // Filtre sous forme de chip
  Widget _filtreChip(String label, String valeur) {
    bool actif = _typeAlerte == valeur;
    return FilterChip(
      label: Text(label),
      selected: actif,
      onSelected: (_) => setState(() => _typeAlerte = valeur),
      backgroundColor: Colors.white.withOpacity(0.85),
      selectedColor: const Color(0xFF00C2CB).withOpacity(0.15),
      labelStyle: TextStyle(
        color: actif ? const Color(0xFF00C2CB) : Colors.grey,
        fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
      ),
      checkmarkColor: const Color(0xFF00C2CB),
    );
  }

  // Carte d'alerte stock
  Widget _buildAlerteCard(StockPharmacie stock) {
    final bool estRupture = stock.quantiteEnStock == 0;
    final bool estAlerte = stock.quantiteEnStock > 0 && stock.quantiteEnStock <= 10;

    Color bgColor;
    Color borderColor;
    String statutLabel;

    if (estRupture) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFB71C1C);
      statutLabel = "RUPTURE";
    } else {
      bgColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFE65100);
      statutLabel = "ALERTE";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              estRupture ? Icons.inventory_2_rounded : Icons.warning_rounded,
              color: borderColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.nomPharmacie,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stock actuel: ${stock.quantiteEnStock} unite(s)",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: borderColor,
                  ),
                ),
                if (stock.datePeremption.isNotEmpty)
                  Text(
                    "Peremption: ${stock.datePeremption}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: borderColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showReapprovisionnementDialog(stock),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C2CB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Reapprovisionner",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00C2CB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialogue pour reapprovisionner le stock
  void _showReapprovisionnementDialog(StockPharmacie stock) {
    final qteCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/fond_patient.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.white.withOpacity(0.95),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.nomPharmacie,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Stock actuel: ${stock.quantiteEnStock} unites",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: qteCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Nouvelle quantite",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.add_box_rounded,
                          color: Color(0xFF00C2CB),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: AppWidgets.primaryButton(
                      label: loading ? "Mise a jour..." : "Mettre a jour le stock",
                      icon: Icons.update_rounded,
                      onPressed: loading
                          ? () {}
                          : () async {
                              final qte = int.tryParse(qteCtrl.text);
                              if (qte == null || qte <= 0) {
                                AppWidgets.showSnack(
                                  ctx,
                                  "Veuillez entrer une quantite valide",
                                  color: AppColors.warning,
                                );
                                return;
                              }
                              setModal(() => loading = true);
                              final ok = await PharmacyService.updateStock(
                                stock.idStock,
                                qte,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (ok) {
                                _chargerAlertes();
                                AppWidgets.showSnack(
                                  context,
                                  "Stock mis a jour avec succes",
                                  color: const Color(0xFF22863A),
                                );
                              } else {
                                AppWidgets.showSnack(
                                  context,
                                  "Erreur lors de la mise a jour",
                                  color: AppColors.danger,
                                );
                              }
                            },
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

  // Message quand aucune alerte
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00C2CB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22863A),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucune alerte stock",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tous les produits sont bien approvisionnes",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Barre de navigation en bas
  Widget _buildBottomNav(int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.dashboard_rounded,
                "Accueil",
                0,
                index,
                () => Navigator.pushReplacementNamed(context, '/dashboard_pharmacien'),
              ),
              _navItem(
                Icons.shopping_bag_rounded,
                "Commandes",
                1,
                index,
                () => Navigator.pushReplacementNamed(context, '/commandes_pharmacien'),
              ),
              _navItem(
                Icons.warning_rounded,
                "Alertes",
                2,
                index,
                () {},
              ),
              _navItem(
                Icons.qr_code_scanner_rounded,
                "Scanner",
                3,
                index,
                () => Navigator.pushReplacementNamed(context, '/scan_ordonnance_pharmacien'),
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                4,
                index,
                () => Navigator.pushReplacementNamed(context, '/profil_pharmacien'),
              ),
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
          Icon(
            icon,
            color: actif ? const Color(0xFF00C2CB) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: actif ? const Color(0xFF00C2CB) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}