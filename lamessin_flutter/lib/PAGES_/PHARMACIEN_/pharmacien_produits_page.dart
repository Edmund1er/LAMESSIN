import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/medicament_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienProduitsPage extends StatefulWidget {
  const PharmacienProduitsPage({super.key});
  @override
  State<PharmacienProduitsPage> createState() => _PharmacienProduitsPageState();
}

class _PharmacienProduitsPageState extends State<PharmacienProduitsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medicament> _medicaments = [];
  List<StockPharmacie> _stocks = [];
  bool _chargement = true;
  String _recherche = "";

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
    }
  }

  List<Medicament> get _medicamentsFiltres => _medicaments
      .where(
        (m) => m.nomCommercial.toLowerCase().contains(_recherche.toLowerCase()),
      )
      .toList();

  List<StockPharmacie> get _stocksFiltres => _stocks
      .where(
        (s) => s.nomPharmacie.toLowerCase().contains(_recherche.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 56,
                  top: 50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Mes Produits",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAjouterProduitDialog(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        "Ajouter",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: "Catalogue"),
                Tab(text: "Stocks"),
              ],
            ),
          ),
        ],
        body: _chargement
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _recherche = v),
                        decoration: const InputDecoration(
                          hintText: "Rechercher un produit...",
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildCatalogue(), _buildStocks()],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAjouterProduitDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // ========================= CATALOGUE =========================

  Widget _buildCatalogue() {
    if (_medicamentsFiltres.isEmpty) {
      return _buildEmpty("Aucun produit trouvé", Icons.medication_outlined);
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _medicamentsFiltres.length,
        itemBuilder: (_, i) => _buildMedicamentCard(_medicamentsFiltres[i]),
      ),
    );
  }

  Widget _buildMedicamentCard(Medicament m) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nomCommercial,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (m.description.isNotEmpty)
                  Text(
                    m.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  "${m.prixVente.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showModifierProduitDialog(m),
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ========================= STOCKS =========================

  Widget _buildStocks() {
    if (_stocksFiltres.isEmpty) {
      return _buildEmpty("Aucun stock enregistré", Icons.inventory_2_outlined);
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stocksFiltres.length,
        itemBuilder: (_, i) => _buildStockCard(_stocksFiltres[i]),
      ),
    );
  }

  Widget _buildStockCard(StockPharmacie s) {
    // Correction: utilisation des vrais noms des champs
    final bool enRupture = s.quantiteEnStock == 0;
    final bool enAlerte =
        s.quantiteEnStock > 0 && s.quantiteEnStock <= 10; // Seuil fixe à 10

    Color statusColor;
    Color statusBg;
    String statusLabel;

    if (enRupture) {
      statusColor = const Color(0xFFB71C1C);
      statusBg = const Color(0xFFFFEBEE);
      statusLabel = "Rupture";
    } else if (enAlerte) {
      statusColor = const Color(0xFFE65100);
      statusBg = AppColors.warningLight;
      statusLabel = "Alerte";
    } else {
      statusColor = const Color(0xFF22863A);
      statusBg = AppColors.successLight;
      statusLabel = "En stock";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enRupture ? const Color(0xFFFFCDD2) : AppColors.borderLight,
          width: enRupture ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nomPharmacie,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Qté: ${s.quantiteEnStock}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (s.datePeremption.isNotEmpty)
                  Text(
                    "Péremption: ${s.datePeremption}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showUpdateStockDialog(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Modifier",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  // ========================= DIALOGS =========================

  void _showAjouterProduitDialog() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
              const Text(
                "Ajouter un produit",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _inputField(nomCtrl, "Nom du produit", Icons.medication_rounded),
              const SizedBox(height: 12),
              _inputField(descCtrl, "Description", Icons.description_rounded),
              const SizedBox(height: 12),
              _inputField(posCtrl, "Posologie standard", Icons.info_rounded),
              const SizedBox(height: 12),
              _inputField(
                prixCtrl,
                "Prix de vente (FCFA)",
                Icons.payments_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppWidgets.primaryButton(
                  label: loading ? "Ajout en cours..." : "Ajouter le produit",
                  icon: Icons.add_rounded,
                  onPressed: loading
                      ? () {}
                      : () async {
                          if (nomCtrl.text.isEmpty || prixCtrl.text.isEmpty)
                            return;
                          setModal(() => loading = true);
                          final result =
                              await PharmacyService.ajouterMedicament(
                                nom: nomCtrl.text,
                                description: descCtrl.text,
                                posologie: posCtrl.text,
                                prix: double.tryParse(prixCtrl.text) ?? 0,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (result != null) {
                            _chargerDonnees();
                            AppWidgets.showSnack(
                              context,
                              "Produit ajouté avec succès",
                              color: const Color(0xFF22863A),
                            );
                          } else {
                            AppWidgets.showSnack(
                              context,
                              "Erreur lors de l'ajout",
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
    );
  }

  void _showModifierProduitDialog(Medicament m) {
    final nomCtrl = TextEditingController(text: m.nomCommercial);
    final descCtrl = TextEditingController(text: m.description);
    final prixCtrl = TextEditingController(
      text: m.prixVente.toStringAsFixed(0),
    );
    final posCtrl = TextEditingController(text: m.posologieStandard);
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
              const Text(
                "Modifier le produit",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _inputField(nomCtrl, "Nom commercial", Icons.medication_rounded),
              const SizedBox(height: 12),
              _inputField(descCtrl, "Description", Icons.description_rounded),
              const SizedBox(height: 12),
              _inputField(posCtrl, "Posologie standard", Icons.info_rounded),
              const SizedBox(height: 12),
              _inputField(
                prixCtrl,
                "Prix de vente (FCFA)",
                Icons.payments_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppWidgets.primaryButton(
                  label: loading ? "Modification..." : "Enregistrer",
                  icon: Icons.save_rounded,
                  onPressed: loading
                      ? () {}
                      : () async {
                          setModal(() => loading = true);
                          final result =
                              await PharmacyService.modifierMedicament(
                                medicamentId: m.id,
                                nom: nomCtrl.text,
                                description: descCtrl.text,
                                posologie: posCtrl.text,
                                prix: double.tryParse(prixCtrl.text),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (result != null) {
                            _chargerDonnees();
                            AppWidgets.showSnack(
                              context,
                              "Produit modifié",
                              color: const Color(0xFF22863A),
                            );
                          } else {
                            AppWidgets.showSnack(
                              context,
                              "Erreur lors de la modification",
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
    );
  }

  void _showUpdateStockDialog(StockPharmacie s) {
    final qteCtrl = TextEditingController(text: s.quantiteEnStock.toString());
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
                s.nomPharmacie,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Stock actuel: ${s.quantiteEnStock} unités",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _inputField(
                qteCtrl,
                "Nouvelle quantité",
                Icons.inventory_2_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppWidgets.primaryButton(
                  label: loading ? "Mise à jour..." : "Mettre à jour le stock",
                  icon: Icons.update_rounded,
                  onPressed: loading
                      ? () {}
                      : () async {
                          final qte = int.tryParse(qteCtrl.text);
                          if (qte == null) return;
                          setModal(() => loading = true);
                          final ok = await PharmacyService.updateStock(
                            s.idStock,
                            qte,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (ok) {
                            _chargerDonnees();
                            AppWidgets.showSnack(
                              context,
                              "Stock mis à jour",
                              color: const Color(0xFF22863A),
                            );
                          } else {
                            AppWidgets.showSnack(
                              context,
                              "Erreur mise à jour stock",
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
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmpty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
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
              _navItem(
                Icons.dashboard_rounded,
                "Accueil",
                0,
                index,
                () => Navigator.pushReplacementNamed(context, '/dashboard_pharmacien'),
              ),
              _navItem(Icons.medication_rounded, "Produits", 1, index, () {}),
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