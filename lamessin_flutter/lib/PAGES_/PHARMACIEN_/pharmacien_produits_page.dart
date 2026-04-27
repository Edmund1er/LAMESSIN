import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/medicament_model.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_profil_page.dart';
import 'pharmacien_alertes_stock_page.dart';

class PharmacienProduitsPage extends StatefulWidget {
  const PharmacienProduitsPage({super.key});

  @override
  State<PharmacienProduitsPage> createState() => _PharmacienProduitsPageState();
}

class _PharmacienProduitsPageState extends State<PharmacienProduitsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medicament> _medicaments = [];
  List<StockPharmacie> _stocks = [];
  bool _chargement = true;
  String _recherche = "";
  String _nomPharmacie = "Ma pharmacie";

  final String _imageFond = "assets/images/fond_pharmacien_produits.jpg";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final profil = await ApiService.getProfil();
      if (profil != null && profil is Pharmacien) {
        _nomPharmacie = profil.nomPharmacie;
      }
      final results = await Future.wait([
        PharmacyService.getCatalogueMedicaments(),
        PharmacyService.getStocks(),
      ]);
      if (mounted) {
        setState(() {
          _medicaments = results[0] as List<Medicament>;
          _stocks = results[1] as List<StockPharmacie>;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
      debugPrint("Erreur chargement: $e");
    }
  }

  List<Medicament> get _medicamentsFiltres => _medicaments.where((m) => m.nomCommercial.toLowerCase().contains(_recherche.toLowerCase())).toList();
  List<StockPharmacie> get _stocksFiltres => _stocks.toList();

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
    } else if (index == 2) {
      return;
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
        title: const Text("Mes Produits", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerDonnees),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: "Catalogue"), Tab(text: "Stocks")],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100]))),
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
                        hintText: "Rechercher un produit...",
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
                          children: [_buildCatalogue(), _buildStocks()],
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

  // ==================== CATALOGUE (Lecture seule) ====================

  Widget _buildCatalogue() {
    if (_medicamentsFiltres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucun produit dans le catalogue", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAjouterNouveauProduitDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Ajouter un produit"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: const Color(0xFF00ACC1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicamentsFiltres.length,
        itemBuilder: (_, i) => _buildMedicamentCard(_medicamentsFiltres[i]),
      ),
    );
  }

  Widget _buildMedicamentCard(Medicament m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.medication_rounded, color: Color(0xFF00ACC1), size: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nomCommercial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                if (m.description.isNotEmpty) Text(m.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("${m.prixVente.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF00ACC1))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STOCKS (Gestion complete) ====================

  Widget _buildStocks() {
    if (_stocksFiltres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucun stock enregistre", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAjouterNouveauProduitDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Ajouter un produit"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: const Color(0xFF00ACC1),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAjouterNouveauProduitDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Ajouter un produit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ACC1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stocksFiltres.length,
              itemBuilder: (_, i) => _buildStockCard(_stocksFiltres[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockPharmacie s) {
    final bool enRupture = s.quantiteEnStock == 0;
    final bool enAlerte = s.quantiteEnStock > 0 && s.quantiteEnStock <= 10;
    Color statusColor;
    Color statusBg;
    String statusLabel;
    if (enRupture) {
      statusColor = const Color(0xFFEF5350);
      statusBg = const Color(0xFFFFEBEE);
      statusLabel = "Rupture";
    } else if (enAlerte) {
      statusColor = const Color(0xFFF57C00);
      statusBg = const Color(0xFFFFF3E0);
      statusLabel = "Alerte";
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusBg = const Color(0xFFE8F5E9);
      statusLabel = "En stock";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.inventory_2_rounded, color: statusColor, size: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nomProduit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text("Quantite: ${s.quantiteEnStock}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (s.datePeremption.isNotEmpty) Text("Peremption: ${s.datePeremption}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text("Seuil alerte: 10", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)), child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showUpdateStockDialog(s),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00ACC1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("Modifier", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00ACC1)))),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmerSuppressionStock(s),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("Supprimer", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red))),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGUE AJOUT NOUVEAU PRODUIT ====================

  void _showAjouterNouveauProduitDialog() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    final qteCtrl = TextEditingController();
    DateTime? selectedDate;
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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text("Ajouter un nouveau produit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 16),
                    
                    const Text("Informations produit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    
                    _inputField(nomCtrl, "Nom du produit *", Icons.medication_rounded),
                    const SizedBox(height: 12),
                    _inputField(descCtrl, "Description", Icons.description_rounded, maxLines: 3),
                    const SizedBox(height: 12),
                    _inputField(prixCtrl, "Prix de vente (FCFA) *", Icons.payments_rounded, isNumber: true),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    const Text("Informations stock", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    
                    _inputField(qteCtrl, "Quantite initiale", Icons.inventory_2_rounded, isNumber: true),
                    const SizedBox(height: 12),
                    
                    // Date de péremption avec calendrier
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF00ACC1)),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModal(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF00ACC1), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDate != null 
                                  ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                                  : "Selectionner une date de peremption",
                                style: TextStyle(color: selectedDate != null ? Colors.black87 : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : () async {
                          if (nomCtrl.text.isEmpty) {
                            AppWidgets.showSnack(ctx, "Veuillez entrer le nom du produit", color: Colors.orange);
                            return;
                          }
                          if (prixCtrl.text.isEmpty) {
                            AppWidgets.showSnack(ctx, "Veuillez entrer le prix", color: Colors.orange);
                            return;
                          }
                          setModal(() => loading = true);
                          
                          // 1. Ajouter le médicament
                          final medicament = await PharmacyService.ajouterMedicament(
                            nom: nomCtrl.text,
                            description: descCtrl.text,
                            posologie: "",
                            prix: double.tryParse(prixCtrl.text) ?? 0,
                          );
                          
                          if (medicament != null && selectedDate != null) {
                            // 2. Ajouter le stock
                            final dateStr = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                            final ok = await PharmacyService.ajouterOuUpdateStock(
                              medicamentId: medicament.id,
                              quantite: int.tryParse(qteCtrl.text) ?? 0,
                              datePeremption: dateStr
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (ok) {
                              _chargerDonnees();
                              AppWidgets.showSnack(context, "Produit ajoute avec succes", color: const Color(0xFF4CAF50));
                            } else {
                              AppWidgets.showSnack(context, "Erreur lors de l'ajout du stock", color: Colors.red);
                            }
                          } else if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppWidgets.showSnack(context, "Erreur lors de l'ajout", color: Colors.red);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Ajouter le produit", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateStockDialog(StockPharmacie s) {
    final qteCtrl = TextEditingController(text: s.quantiteEnStock.toString());
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
                children: [
                  Text(s.nomProduit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("Stock actuel: ${s.quantiteEnStock} unites", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  _inputField(qteCtrl, "Nouvelle quantite", Icons.inventory_2_rounded, isNumber: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        final qte = int.tryParse(qteCtrl.text);
                        if (qte == null || qte < 0) {
                          AppWidgets.showSnack(ctx, "Veuillez entrer une quantite valide", color: Colors.orange);
                          return;
                        }
                        setModal(() => loading = true);
                        final ok = await PharmacyService.updateStock(s.idStock, qte);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok) {
                          _chargerDonnees();
                          AppWidgets.showSnack(context, "Stock mis a jour", color: const Color(0xFF4CAF50));
                        } else {
                          AppWidgets.showSnack(context, "Erreur mise a jour stock", color: Colors.red);
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

  void _confirmerSuppressionStock(StockPharmacie s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Supprimer ce stock ?", style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text("Voulez-vous vraiment supprimer le stock de ${s.nomProduit} ?\nLe produit restera dans le catalogue."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await PharmacyService.supprimerStock(s.idStock);
              if (ok) {
                _chargerDonnees();
                AppWidgets.showSnack(context, "Stock supprime", color: const Color(0xFF4CAF50));
              } else {
                AppWidgets.showSnack(context, "Erreur lors de la suppression", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF00ACC1), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
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