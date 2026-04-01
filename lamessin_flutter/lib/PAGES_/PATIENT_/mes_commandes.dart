import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/patient_service.dart'; // CORRECTION
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/commande_model.dart';
import '../../THEME_/app_theme.dart';

class MesCommandesPage extends StatefulWidget {
  const MesCommandesPage({super.key});
  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage>
    with WidgetsBindingObserver {
  List<Commande> _commandes = [];
  bool _chargement = true;

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
    final data = await PatientService.getMesCommandes(); // CORRECTION
    if (mounted) setState(() { _commandes = data; _chargement = false; });
  }

  Future<void> _relancerPaiement(int commandeId) async {
    AppWidgets.showSnack(context, "Ouverture du portail de paiement Togo...");
    final resultat = await PatientService.obtenirLienPaiement(commandeId); // CORRECTION
    if (resultat != null && resultat['payment_url'] != null) {
      final Uri uri = Uri.parse(resultat['payment_url']);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      AppWidgets.showSnack(context,
          "Impossible de générer le lien de paiement.", color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const MenuNavigation(),
      appBar: AppWidgets.appBar("Mes commandes"),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _chargerCommandes,
              color: AppColors.primary,
              child: _commandes.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _commandes.length,
                      itemBuilder: (_, index) => _buildCommandeCard(_commandes[index]),
                    ),
            ),
    );
  }

  Widget _buildCommandeCard(Commande c) {
    bool estPaye = c.statut == 'PAYE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: estPaye ? const Color(0xFFC0DDBA) : AppColors.borderLight,
          width: estPaye ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: estPaye ? AppColors.successLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                estPaye ? Icons.check_circle_rounded : Icons.shopping_bag_rounded,
                color: estPaye ? const Color(0xFF22863A) : const Color(0xFFE65100),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Commande #${c.id}", style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
              Text("${c.total.toInt()} FCFA",
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: estPaye ? AppColors.successLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                estPaye ? "PAYÉ" : "EN ATTENTE",
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: estPaye ? const Color(0xFF22863A) : const Color(0xFFE65100),
                ),
              ),
            ),
          ]),
          if (!estPaye) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _relancerPaiement(c.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                ),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text("PAYER (TMONEY / FLOOZ)",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.shopping_bag_rounded,
              size: 36, color: AppColors.primary)),
      const SizedBox(height: 16),
      const Text("Aucune commande", style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text("Vos commandes apparaîtront ici",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}