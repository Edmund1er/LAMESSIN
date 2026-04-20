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

class _PharmacienCommandesPageState extends State<PharmacienCommandesPage>
    with SingleTickerProviderStateMixin {
  // Controleur des onglets
  late TabController _tabController;
  // Liste des commandes
  List<Commande> _commandes = [];
  // Etat du chargement
  bool _chargement = true;
  // Texte de recherche
  String _recherche = "";

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

  // Charge toutes les commandes
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

  // Filtre les commandes par recherche
  List<Commande> get _commandesFiltrees => _commandes
      .where(
        (c) => c.patientNom.toLowerCase().contains(_recherche.toLowerCase()),
      )
      .toList();

  // Commandes en attente
  List<Commande> get _commandesEnAttente => _commandesFiltrees
      .where((c) => c.statut.toUpperCase() == 'EN_ATTENTE')
      .toList();

  // Commandes payees
  List<Commande> get _commandesPayees => _commandesFiltrees
      .where((c) => c.statut.toUpperCase() == 'PAYE')
      .toList();

  // Commandes livrees
  List<Commande> get _commandesLivrees => _commandesFiltrees
      .where((c) => c.statut.toUpperCase() == 'LIVRE')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_patient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white.withOpacity(0.85),
              elevation: 0,
              automaticallyImplyLeading: false,
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white.withOpacity(0.85),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 56,
                    top: 50,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Commandes",
                        style: TextStyle(
                          color: Color(0xFF00C2CB),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00C2CB),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00C2CB),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: "En attente"),
                  Tab(text: "Payees"),
                  Tab(text: "Livrees"),
                ],
              ),
            ),
          ],
          body: Container(
            color: Colors.white.withOpacity(0.75),
            child: _chargement
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C2CB)),
                  )
                : Column(
                    children: [
                      // Barre de recherche
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _recherche = v),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: "Rechercher un patient...",
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  // Affiche la liste des commandes
  Widget _buildListeCommandes(List<Commande> commandes, String type) {
    if (commandes.isEmpty) {
      return _buildEmpty(type);
    }
    return RefreshIndicator(
      onRefresh: _chargerCommandes,
      color: const Color(0xFF00C2CB),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: commandes.length,
        itemBuilder: (_, i) => _buildCommandeCard(commandes[i]),
      ),
    );
  }

  // Carte d'une commande
  Widget _buildCommandeCard(Commande c) {
    Color statutColor;
    Color statutBg;
    String statutLabel;

    switch (c.statut.toUpperCase()) {
      case 'EN_ATTENTE':
        statutColor = const Color(0xFFE65100);
        statutBg = AppColors.warningLight;
        statutLabel = "A preparer";
        break;
      case 'PAYE':
        statutColor = const Color(0xFF22863A);
        statutBg = AppColors.successLight;
        statutLabel = "A livrer / retrait";
        break;
      default:
        statutColor = AppColors.textSecondary;
        statutBg = AppColors.surfaceVariant;
        statutLabel = c.statut;
    }

    return GestureDetector(
      onTap: () => _voirDetails(c),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00C2CB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Color(0xFF00C2CB),
                size: 24,
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
                  const SizedBox(height: 4),
                  Text(
                    "${c.lignes.length} produit(s) · ${c.total.toStringAsFixed(0)} FCFA",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    c.dateCreation.substring(0, 10),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
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
                statutLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statutColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation vers le detail de la commande
  void _voirDetails(Commande commande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PharmacienDetailCommandePage(commande: commande),
      ),
    ).then((_) => _chargerCommandes());
  }

  // Message quand liste vide
  Widget _buildEmpty(String type) {
    String message;
    IconData icon;

    switch (type) {
      case "en_attente":
        message = "Aucune commande en attente";
        icon = Icons.hourglass_empty_rounded;
        break;
      case "payee":
        message = "Aucune commande payee";
        icon = Icons.payments_rounded;
        break;
      default:
        message = "Aucune commande livree";
        icon = Icons.check_circle_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
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
                () => Navigator.pushReplacementNamed(
                  context,
                  '/dashboard_pharmacien',
                ),
              ),
              _navItem(
                Icons.shopping_bag_rounded,
                "Commandes",
                1,
                index,
                () {},
              ),
              _navItem(
                Icons.medication_rounded,
                "Produits",
                2,
                index,
                () => Navigator.pushReplacementNamed(
                  context,
                  '/produits_pharmacien',
                ),
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                3,
                index,
                () => Navigator.pushReplacementNamed(
                  context,
                  '/profil_pharmacien',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Element de la barre de navigation
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