import 'package:flutter/material.dart';
import '../../MODELS_/medicament_model.dart';
import '../../THEME_/app_theme.dart';

class DetailProduitPage extends StatelessWidget {
  final Medicament medicament;
  const DetailProduitPage({super.key, required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar(medicament.nomCommercial),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image placeholder
              Center(
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.medication_rounded,
                      size: 60, color: AppColors.primary),
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
                decoration: BoxDecoration(color: AppColors.surface,
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
                decoration: BoxDecoration(color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.sell_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text("Prix unitaire :", style: TextStyle(
                      fontSize: 14, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text("${medicament.prixVente.toInt()} FCFA",
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
        ),

        // Bouton ajout panier
        Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: const BoxDecoration(color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight))),
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
    );
  }
}
