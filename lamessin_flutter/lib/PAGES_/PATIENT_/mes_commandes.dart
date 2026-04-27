import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/commande_model.dart';
import '../../THEME_/app_theme.dart';
import 'paiement_page.dart';

class MesCommandesPage extends StatefulWidget {
  const MesCommandesPage({super.key});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage> with WidgetsBindingObserver {
  static const Color _brandColor = Color(0xFF00ACC1);
  List<Commande> _commandes = [];
  bool _chargement = true;
  int _selectedIndex = 2;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chargerCommandes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _chargerCommandes();
  }

  Future<void> _chargerCommandes() async {
    setState(() => _chargement = true);
    try {
      final data = await PatientService.getMesCommandes();
      if (mounted) {
        setState(() {
          _commandes = data;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
      AppWidgets.showSnack(context, "Erreur de chargement des commandes", color: AppColors.danger);
    }
  }

  Future<void> _relancerPaiement(int commandeId, double montant) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaiementPage(commandeId: commandeId, montant: montant)),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: const Text("Mes commandes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                : RefreshIndicator(
                    onRefresh: _chargerCommandes,
                    color: _brandColor,
                    child: _commandes.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _commandes.length,
                            itemBuilder: (_, index) => _buildCommandeCard(_commandes[index]),
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildCommandeCard(Commande c) {
    bool estPaye = c.statut == 'PAYE';
    bool estLivree = c.statut == 'LIVRE';
    bool estEnAttente = c.statut == 'EN_ATTENTE';

    Map<String, dynamic> style = _getStatutStyle(c.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(12)),
              child: Icon(style['icon'], color: style['color'], size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Commande #${c.id}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
              Text("${c.total.toInt()} FCFA", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(c.dateCreation, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(8)),
              child: Text(style['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: style['color'])),
            ),
          ]),
          const SizedBox(height: 8),
          Text("${c.lignes.length} article(s)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (estEnAttente) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _relancerPaiement(c.id, c.total),
                style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 11), elevation: 0),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text("PAYER (TMONEY / FLOOZ)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
          if (estPaye && !estLivree)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Commande payee - En cours de preparation", style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)))),
                ],
              ),
            ),
          if (estLivree)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Commande livree - Merci pour votre confiance !", style: TextStyle(fontSize: 12, color: Color(0xFF2196F3)))),
                ],
              ),
            ),
        ]),
      ),
    );
  }

  Map<String, dynamic> _getStatutStyle(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return {'label': 'En attente', 'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0), 'icon': Icons.hourglass_empty_rounded};
      case 'PAYE': return {'label': 'Payee', 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9), 'icon': Icons.payments_rounded};
      case 'LIVRE': return {'label': 'Livree', 'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD), 'icon': Icons.check_circle_rounded};
      default: return {'label': statut, 'color': Colors.grey, 'bg': Colors.grey[100]!, 'icon': Icons.shopping_bag_rounded};
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Icon(Icons.shopping_bag_rounded, size: 36, color: _brandColor)),
        const SizedBox(height: 16),
        const Text("Aucune commande", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 6),
        const Text("Vos commandes apparaitront ici", style: TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, currentIndex),
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, currentIndex),
              _navItem(Icons.shopping_bag_rounded, "Commandes", 2, currentIndex),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, currentIndex),
              _navItem(Icons.person_rounded, "Profil", 4, currentIndex),
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
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}