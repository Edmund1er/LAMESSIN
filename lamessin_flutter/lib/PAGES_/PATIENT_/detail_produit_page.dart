import 'package:flutter/material.dart';
import '../../MODELS_/medicament_model.dart';
import '../../THEME_/app_theme.dart';

class DetailProduitPage extends StatefulWidget {
  final Medicament medicament;
  const DetailProduitPage({super.key, required this.medicament});

  @override
  State<DetailProduitPage> createState() => _DetailProduitPageState();
}

class _DetailProduitPageState extends State<DetailProduitPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 1;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: Text(widget.medicament.nomCommercial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
                            child: Icon(Icons.medication_rounded, size: 60, color: _brandColor),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(widget.medicament.nomCommercial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                          child: const Text("Disponible en pharmacie", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Text(widget.medicament.description, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            Icon(Icons.sell_rounded, color: _brandColor, size: 20),
                            const SizedBox(width: 10),
                            const Text("Prix unitaire :", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                            const Spacer(),
                            Text("${widget.medicament.prixVente.toInt()} FCFA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _brandColor)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).padding.bottom + 14),
                  decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: Colors.grey))),
                  child: AppWidgets.darkButton(
                    label: "AJOUTER AU PANIER",
                    icon: Icons.shopping_cart_checkout_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Veuillez selectionner une pharmacie dans la recherche pour ajouter au panier."),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
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