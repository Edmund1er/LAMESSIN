import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/commande_model.dart';
import 'pharmacien_commandes_page.dart';

class PharmacienDetailCommandePage extends StatefulWidget {
  final Commande commande;
  const PharmacienDetailCommandePage({super.key, required this.commande});

  @override
  State<PharmacienDetailCommandePage> createState() => _PharmacienDetailCommandePageState();
}

class _PharmacienDetailCommandePageState extends State<PharmacienDetailCommandePage> {
  bool _validationEnCours = false;

  final String _imageFond = "assets/images/fond_pharmacien_detail_commande.jpg";

  Map<String, dynamic> _getStatutStyle(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE': return {'label': 'En attente', 'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0)};
      case 'PAYE': return {'label': 'Payee', 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9)};
      case 'LIVRE': return {'label': 'Livree', 'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD)};
      default: return {'label': statut, 'color': Colors.grey, 'bg': Colors.grey[100]!};
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final bool estEnAttente = c.statut.toUpperCase() == 'EN_ATTENTE';
    final bool estPayee = c.statut.toUpperCase() == 'PAYE';
    final bool estLivree = c.statut.toUpperCase() == 'LIVRE';
    final style = _getStatutStyle(c.statut);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage())),
        ),
        title: Text("Commande #${c.id}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                  // Carte client
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
                              Text(c.patientNom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text("Commande du ${c.dateCreation.substring(0, 10)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(20)), child: Text(style['label'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: style['color']))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Section articles
                  const Text("Articles commandes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: c.lignes.length,
                    itemBuilder: (_, i) => _buildArticleCard(c.lignes[i]),
                  ),
                  const SizedBox(height: 20),
                  // Section total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total a payer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        Text("${c.total.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00ACC1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bouton action - Valider la commande (EN_ATTENTE -> PAYE)
                  if (estEnAttente)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _validationEnCours ? null : _validerCommande,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _validationEnCours ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Valider la commande", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  // Bouton action - Marquer comme livree (PAYE -> LIVRE)
                  if (estPayee && !estLivree)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _validationEnCours ? null : _marquerLivree,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _validationEnCours ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Marquer comme livree", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (estLivree)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2196F3), size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text("Commande deja livree", style: TextStyle(fontSize: 13, color: Color(0xFF2196F3)))),
                        ],
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

  Widget _buildArticleCard(LigneCommande ligne) {
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
                Text(ligne.nomMedicament, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text("Quantite: ${ligne.quantite} x ${ligne.prixUnitaire.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text("${(ligne.quantite * ligne.prixUnitaire).toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF00ACC1))),
        ],
      ),
    );
  }

  // Valide la commande (EN_ATTENTE -> PAYE)
  Future<void> _validerCommande() async {
    setState(() => _validationEnCours = true);
    final ok = await PharmacyService.validerCommande(widget.commande.id);
    setState(() => _validationEnCours = false);
    if (ok) {
      AppWidgets.showSnack(context, "Commande validee avec succes", color: const Color(0xFF4CAF50));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
    } else {
      AppWidgets.showSnack(context, "Erreur lors de la validation", color: Colors.red);
    }
  }

  // Marque la commande comme livree (PAYE -> LIVRE)
  Future<void> _marquerLivree() async {
    setState(() => _validationEnCours = true);
    final ok = await PharmacyService.marquerCommandeLivree(widget.commande.id);
    setState(() => _validationEnCours = false);
    if (ok) {
      AppWidgets.showSnack(context, "Commande marquee comme livree", color: const Color(0xFF4CAF50));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
    } else {
      AppWidgets.showSnack(context, "Erreur lors de l'operation", color: Colors.red);
    }
  }
}