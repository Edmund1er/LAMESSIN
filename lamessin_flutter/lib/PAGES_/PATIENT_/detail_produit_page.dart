import 'package:flutter/material.dart';
import '../../MODELS_/medicament_model.dart';
import '../../THEME_/app_theme.dart';

class DetailProduitPage extends StatelessWidget {
  static const Color _brandColor = Color(0xFF00C2CB);
  final Medicament medicament;
  const DetailProduitPage({super.key, required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: Text(medicament.nomCommercial, style: const TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _brandColor),
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
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: _brandColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.medication_rounded,
                          size: 60, color: _brandColor),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(medicament.nomCommercial, style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text("Disponible en pharmacie",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: Color(0xFF22863A))),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Description", style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(medicament.description, style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _brandColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _brandColor.withOpacity(0.2))),
                    child: Row(children: [
                      Icon(Icons.sell_rounded, color: _brandColor, size: 20),
                      const SizedBox(width: 10),
                      const Text("Prix unitaire :", style: TextStyle(
                          fontSize: 14, color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text("${medicament.prixVente.toInt()} FCFA",
                          style: TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w900, color: _brandColor)),
                    ]),
                  ),
                ]),
              ),
            ),

            Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                border: const Border(top: BorderSide(color: AppColors.borderLight))
              ),
              child: AppWidgets.darkButton(
                label: "AJOUTER AU PANIER",
                icon: Icons.shopping_cart_checkout_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          "Veuillez sélectionner une pharmacie dans la recherche pour ajouter au panier."),
                      backgroundColor: AppColors.textPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}