import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_scan_ordonnance_page.dart';
import 'pharmacien_profil_page.dart';

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
  // Etat du chargement pour la validation
  bool _validationEnCours = false;

  @override
  Widget build(BuildContext context) {
    final ordonnance = widget.ordonnance;
    final patient = widget.patient;
    final lignes = ordonnance['lignes'] as List;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: const Text(
          "Detail ordonnance",
          style: TextStyle(
            color: Color(0xFF00C2CB),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF00C2CB)),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte patient
                _sectionTitle("Informations patient"),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2CB).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF00C2CB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${patient['compte_utilisateur']['first_name']} ${patient['compte_utilisateur']['last_name']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Ordonnance du ${ordonnance['date_prescription']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (ordonnance['medecin_nom'] != null)
                              Text(
                                "Dr ${ordonnance['medecin_nom']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "VALIDE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section medicaments prescrits
                _sectionTitle("Medicaments prescrits"),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lignes.length,
                  itemBuilder: (_, i) => _buildMedicamentCard(lignes[i]),
                ),

                const SizedBox(height: 20),

                // Section code de securite
                _sectionTitle("Code de securite"),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Code securite",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2CB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ordonnance['code_securite'] ?? "Non disponible",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00C2CB),
                          ),
                        ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22863A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _validationEnCours
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Preparer les medicaments",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(3),
    );
  }

  // Carte d'un medicament prescrit
  Widget _buildMedicamentCard(Map<String, dynamic> ligne) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00C2CB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Color(0xFF00C2CB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne['nom_medicament'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Quantite: ${ligne['quantite_boites']} boite(s)",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (ligne['posologie_specifique'] != null && ligne['posologie_specifique'].isNotEmpty)
                  Text(
                    "Posologie: ${ligne['posologie_specifique']}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                if (ligne['duree_traitement_jours'] != null && ligne['duree_traitement_jours'] > 0)
                  Text(
                    "Duree: ${ligne['duree_traitement_jours']} jours",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Prepare les medicaments de l'ordonnance
  Future<void> _preparerMedicaments() async {
    setState(() => _validationEnCours = true);

    try {
      final resultat = await PharmacyService.validerOrdonnance(widget.ordonnance['id']);
      if (mounted) {
        setState(() => _validationEnCours = false);

        if (resultat != null && resultat['success'] == true) {
          AppWidgets.showSnack(
            context,
            "Medicaments prepares avec succes",
            color: const Color(0xFF22863A),
          );
          Navigator.pushReplacementNamed(context, '/commandes_pharmacien');
        } else {
          final stockManquant = resultat?['stock_manquant'];
          if (stockManquant != null && stockManquant.isNotEmpty) {
            _showStockManquantDialog(stockManquant);
          } else {
            AppWidgets.showSnack(
              context,
              resultat?['message'] ?? "Erreur lors de la preparation",
              color: AppColors.danger,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validationEnCours = false);
        AppWidgets.showSnack(
          context,
          "Erreur de connexion au serveur",
          color: AppColors.danger,
        );
      }
    }
  }

  // Dialogue pour stock manquant
  void _showStockManquantDialog(List<dynamic> stockManquant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Stock insuffisant",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Les medicaments suivants sont en rupture:"),
            const SizedBox(height: 8),
            ...stockManquant.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "• ${s['medicament']}: ${s['disponible']} disponible(s), ${s['requis']} requis",
                style: const TextStyle(fontSize: 13),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Titre de section
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
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
                () => Navigator.pushReplacementNamed(context, '/dashboard_pharmacien'),
              ),
              _navItem(
                Icons.shopping_bag_rounded,
                "Commandes",
                1,
                index,
                () => Navigator.pushReplacementNamed(context, '/commandes_pharmacien'),
              ),
              _navItem(
                Icons.medication_rounded,
                "Produits",
                2,
                index,
                () => Navigator.pushReplacementNamed(context, '/produits_pharmacien'),
              ),
              _navItem(
                Icons.qr_code_scanner_rounded,
                "Scanner",
                3,
                index,
                () => Navigator.pushReplacementNamed(context, '/scan_ordonnance_pharmacien'),
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                4,
                index,
                () => Navigator.pushReplacementNamed(context, '/profil_pharmacien'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current, VoidCallback onTap) {
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