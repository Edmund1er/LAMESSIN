import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import 'pharmacien_commandes_page.dart';

class PharmacienDetailOrdonnancePage extends StatefulWidget {
  final Map<String, dynamic> ordonnance;
  final Map<String, dynamic> patient;
  const PharmacienDetailOrdonnancePage({
    super.key,
    required this.ordonnance,
    required this.patient,
  });

  @override
  State<PharmacienDetailOrdonnancePage> createState() => _PharmacienDetailOrdonnancePageState();
}

class _PharmacienDetailOrdonnancePageState extends State<PharmacienDetailOrdonnancePage> {
  bool _validationEnCours = false;

  final String _imageFond = "assets/images/fond_pharmacien_detail_ordonnance.jpg";

  @override
  Widget build(BuildContext context) {
    final ordonnance = widget.ordonnance;
    final patient = widget.patient;
    final lignes = ordonnance['lignes'] as List;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Detail ordonnance", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte patient
                  const Text("Informations patient", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Row(
                      children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${patient['compte_utilisateur']['first_name']} ${patient['compte_utilisateur']['last_name']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text("Ordonnance du ${ordonnance['date_prescription']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (ordonnance['medecin_nom'] != null) Text("Dr ${ordonnance['medecin_nom']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)), child: const Text("VALIDE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Section medicaments
                  const Text("Medicaments prescrits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lignes.length,
                    itemBuilder: (_, i) => _buildMedicamentCard(lignes[i]),
                  ),
                  const SizedBox(height: 20),
                  // Section code securite
                  const Text("Code de securite", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Code securite", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
                          child: Text(ordonnance['code_securite'] ?? "Non disponible", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF00ACC1))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bouton preparer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _validationEnCours ? null : _preparerMedicaments,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _validationEnCours ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Preparer les medicaments", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentCard(Map<String, dynamic> ligne) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication_rounded, color: Color(0xFF00ACC1), size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ligne['nom_medicament'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text("Quantite: ${ligne['quantite_boites']} boite(s)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (ligne['posologie_specifique'] != null && ligne['posologie_specifique'].isNotEmpty)
                  Text("Posologie: ${ligne['posologie_specifique']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (ligne['duree_traitement_jours'] != null && ligne['duree_traitement_jours'] > 0)
                  Text("Duree: ${ligne['duree_traitement_jours']} jours", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _preparerMedicaments() async {
    setState(() => _validationEnCours = true);
    try {
      final resultat = await PharmacyService.validerOrdonnance(widget.ordonnance['id']);
      if (mounted) {
        setState(() => _validationEnCours = false);
        if (resultat != null && resultat['success'] == true) {
          AppWidgets.showSnack(context, "Medicaments prepares avec succes", color: const Color(0xFF4CAF50));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
        } else {
          final stockManquant = resultat?['stock_manquant'];
          if (stockManquant != null && stockManquant.isNotEmpty) {
            _showStockManquantDialog(stockManquant);
          } else {
            AppWidgets.showSnack(context, resultat?['message'] ?? "Erreur lors de la preparation", color: Colors.red);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validationEnCours = false);
        AppWidgets.showSnack(context, "Erreur de connexion au serveur", color: Colors.red);
      }
    }
  }

  void _showStockManquantDialog(List<dynamic> stockManquant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Stock insuffisant", style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Les medicaments suivants sont en rupture:"),
            const SizedBox(height: 8),
            ...stockManquant.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• ${s['medicament']}: ${s['disponible']} disponible(s), ${s['requis']} requis", style: const TextStyle(fontSize: 13)),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}