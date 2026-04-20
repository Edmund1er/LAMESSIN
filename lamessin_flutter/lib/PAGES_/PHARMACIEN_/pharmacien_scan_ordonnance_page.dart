import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import 'pharmacien_detail_ordonnance_page.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
import 'pharmacien_profil_page.dart';

class PharmacienScanOrdonnancePage extends StatefulWidget {
  const PharmacienScanOrdonnancePage({super.key});
  @override
  State<PharmacienScanOrdonnancePage> createState() => _PharmacienScanOrdonnancePageState();
}

class _PharmacienScanOrdonnancePageState extends State<PharmacienScanOrdonnancePage> {
  // Controleur pour le code de securite
  final TextEditingController _codeController = TextEditingController();
  // Etat du chargement
  bool _chargement = false;
  // Resultat du scan
  Map<String, dynamic>? _resultatScan;
  // Erreur eventuelle
  String? _erreur;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Lance la recherche de l'ordonnance
  Future<void> _scannerOrdonnance() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _erreur = "Veuillez entrer un code de securite");
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
      _resultatScan = null;
    });

    try {
      final resultat = await PharmacyService.scannerOrdonnance(code);
      if (mounted) {
        if (resultat != null && resultat['valide'] == true) {
          setState(() {
            _resultatScan = resultat;
            _chargement = false;
          });
        } else {
          setState(() {
            _erreur = resultat?['message'] ?? "Ordonnance non trouvee";
            _chargement = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = "Erreur de connexion au serveur";
          _chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: const Text(
          "Scanner ordonnance",
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
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Entrez le code de securite present sur l'ordonnance du patient pour la valider et preparer les medicaments.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Champ code
                _sectionTitle("Code de securite"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ex: 1234567890",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF00C2CB),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton scanner
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _scannerOrdonnance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C2CB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _chargement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Verifier l'ordonnance",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                // Message d'erreur
                if (_erreur != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _erreur!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Resultat du scan (ordonnance trouvee)
                if (_resultatScan != null) ...[
                  const SizedBox(height: 24),
                  _buildResultatCard(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(4),
    );
  }

  // Carte affichant le resultat du scan
  Widget _buildResultatCard() {
    final ordonnance = _resultatScan!['ordonnance'];
    final patient = _resultatScan!['patient'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Ordonnance trouvee"),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient
              Row(
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
                          patient['compte_utilisateur']['first_name'] + " " + patient['compte_utilisateur']['last_name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "Patient",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

              const Divider(height: 24),

              // Details ordonnance
              Text(
                "Ordonnance du ${ordonnance['date_prescription']}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Liste des medicaments
              ...(ordonnance['lignes'] as List).map((ligne) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C2CB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${ligne['nom_medicament']} - ${ligne['quantite_boites']} boite(s)",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),

              const SizedBox(height: 16),

              // Bouton valider
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => _validerOrdonnance(ordonnance['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22863A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Preparer les medicaments",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Valide l'ordonnance et prepare les medicaments
  Future<void> _validerOrdonnance(int ordonnanceId) async {
    setState(() => _chargement = true);

    try {
      final resultat = await PharmacyService.validerOrdonnance(ordonnanceId);
      if (mounted) {
        setState(() => _chargement = false);

        if (resultat != null && resultat['success'] == true) {
          // Afficher succes et rediriger
          AppWidgets.showSnack(
            context,
            "Ordonnance validee ! Commande creee avec succes",
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
              resultat?['message'] ?? "Erreur lors de la validation",
              color: AppColors.danger,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _chargement = false);
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
                () {},
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