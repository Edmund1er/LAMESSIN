import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../THEME_/app_theme.dart';

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
  double get total =>
      widget.items.fold(0, (sum, item) => sum + (item.prix * item.quantite));

  Future<void> _validerCommandeComplete() async {
    if (widget.items.isEmpty) return;

    List<Map<String, dynamic>> articlesJson = widget.items.map((item) => {
      'id': item.idMedoc,
      'qte': item.quantite,
      'pharmacie_id': item.idPharmacie,
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final resultat = await ApiService.creerCommandeMultiple(articlesJson);
      if (!mounted) return;
      Navigator.pop(context);

      if (resultat != null && resultat['payment_url'] != null) {
        final Uri url = Uri.parse(resultat['payment_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          setState(() => widget.items.clear());
          AppWidgets.showSnack(context,
              "Commande créée ! Redirection vers le paiement...",
              color: AppColors.success);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        AppWidgets.showSnack(context,
            "Impossible de générer le lien de paiement.", color: AppColors.danger);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppWidgets.showSnack(context,
          "Erreur de connexion au serveur.", color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar("Mon panier"),
      body: widget.items.isEmpty
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
    );
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.medication_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nom, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text("${item.prix.toStringAsFixed(0)} FCFA / unité",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Row(children: [
          _roundBtn(Icons.remove_rounded, AppColors.dangerLight, AppColors.danger, () {
            setState(() {
              if (item.quantite > 1) item.quantite--;
              else widget.items.removeAt(index);
            });
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text("${item.quantite}", style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
          ),
          _roundBtn(Icons.add_rounded, AppColors.successLight,
              const Color(0xFF22863A), () => setState(() => item.quantite++)),
        ]),
      ]),
    );
  }

  Widget _roundBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 16),
      ),
    );
  }

  Widget _buildRecap() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Total à payer :", style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text("${total.toInt()} FCFA", style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ]),
        const SizedBox(height: 14),
        AppWidgets.darkButton(
          label: "VALIDER ET PAYER",
          onPressed: _validerCommandeComplete,
          icon: Icons.payment_rounded,
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.shopping_cart_outlined,
              size: 36, color: AppColors.primary)),
      const SizedBox(height: 16),
      const Text("Votre panier est vide", style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]));
  }
}
