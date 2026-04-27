import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart';
import '../../THEME_/app_theme.dart';
import 'paiement_page.dart';

class PanierItem {
  final int idMedoc;
  final int idPharmacie;
  final String nom;
  final double prix;
  int quantite;

  PanierItem({
    required this.idMedoc,
    required this.idPharmacie,
    required this.nom,
    required this.prix,
    this.quantite = 1,
  });
}

class PanierPage extends StatefulWidget {
  final List<PanierItem> items;
  const PanierPage({super.key, required this.items});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 1;

  double get total => widget.items.fold(0, (sum, item) => sum + (item.prix * item.quantite));

  final String _imageFond = "assets/images/fond_patient.jpg";

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  Future<void> _validerCommandeComplete() async {
    if (widget.items.isEmpty) return;

    List<Map<String, dynamic>> articlesJson = widget.items.map((item) => {
      'id': item.idMedoc,
      'pharmacie_id': item.idPharmacie,
      'qte': item.quantite,
    }).toList();

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1))));

    try {
      final resultat = await PatientService.creerCommandeMultiple(articlesJson);

      if (!mounted) return;
      Navigator.pop(context);

      if (resultat != null && resultat['success'] == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaiementPage(commandeId: resultat['commande_id'], montant: resultat['total'].toDouble())));
        setState(() => widget.items.clear());
      } else {
        AppWidgets.showSnack(context, resultat?['error'] ?? "Erreur lors de la creation de la commande", color: AppColors.danger);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppWidgets.showSnack(context, "Erreur de connexion au serveur.", color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: const Text("Mon panier", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: widget.items.isEmpty
                ? _buildEmpty()
                : Column(children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.items.length,
                        itemBuilder: (_, index) => _buildItem(index),
                      ),
                    ),
                    _buildRecap(),
                  ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.medication_rounded, color: _brandColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          Text("${item.prix.toStringAsFixed(0)} FCFA / unite", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        Row(children: [
          _roundBtn(Icons.remove_rounded, AppColors.dangerLight, AppColors.danger, () {
            setState(() {
              if (item.quantite > 1) item.quantite--;
              else widget.items.removeAt(index);
            });
          }),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("${item.quantite}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87))),
          _roundBtn(Icons.add_rounded, AppColors.successLight, const Color(0xFF4CAF50), () => setState(() => item.quantite++)),
        ]),
      ]),
    );
  }

  Widget _roundBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 30, height: 30, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: fg, size: 16)),
    );
  }

  Widget _buildRecap() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: Colors.grey))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Total a payer :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          Text("${total.toInt()} FCFA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _brandColor)),
        ]),
        const SizedBox(height: 14),
        AppWidgets.darkButton(label: "VALIDER ET PAYER", onPressed: _validerCommandeComplete, icon: Icons.payment_rounded),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Icon(Icons.shopping_cart_outlined, size: 36, color: _brandColor)),
        const SizedBox(height: 16),
        const Text("Votre panier est vide", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
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
              _navItem(Icons.calendar_month_rounded, "RDV", 2, currentIndex),
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