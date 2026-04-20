import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/commande_model.dart';

class PharmacienDetailCommandePage extends StatefulWidget {
  final Commande commande;
  const PharmacienDetailCommandePage({super.key, required this.commande});

  @override
  State<PharmacienDetailCommandePage> createState() => _PharmacienDetailCommandePageState();
}

class _PharmacienDetailCommandePageState extends State<PharmacienDetailCommandePage> {
  // Etat du chargement pour la validation
  bool _validationEnCours = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final bool estPayee = c.statut.toUpperCase() == 'PAYE';
    final bool estEnAttente = c.statut.toUpperCase() == 'EN_ATTENTE';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: Text(
          "Commande #${c.id}",
          style: const TextStyle(
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
                // Carte client
                _sectionTitle("Informations client"),
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
                              c.patientNom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Commande du ${c.dateCreation.substring(0, 10)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatutBadge(c.statut),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section articles
                _sectionTitle("Articles commandes"),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: c.lignes.length,
                  itemBuilder: (_, i) => _buildArticleCard(c.lignes[i]),
                ),

                const SizedBox(height: 20),

                // Section total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C2CB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00C2CB).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total à payer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${c.total.toStringAsFixed(0)} FCFA",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C2CB),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton action (valider / preparer)
                if (estEnAttente)
                  _buildBoutonPreparer(),
                if (estPayee)
                  _buildBoutonMarquerLivree(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Badge de statut
  Widget _buildStatutBadge(String statut) {
    Color color;
    Color bgColor;
    String label;

    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        color = const Color(0xFFE65100);
        bgColor = AppColors.warningLight;
        label = "En attente";
        break;
      case 'PAYE':
        color = const Color(0xFF22863A);
        bgColor = AppColors.successLight;
        label = "Payee";
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey[100]!;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // Carte d'un article (medicament)
  Widget _buildArticleCard(LigneCommande ligne) {
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
                  ligne.nomMedicament,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Quantite: ${ligne.quantite} x ${ligne.prixUnitaire.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${(ligne.quantite * ligne.prixUnitaire).toStringAsFixed(0)} FCFA",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00C2CB),
            ),
          ),
        ],
      ),
    );
  }

  // Bouton pour preparer la commande (valider)
  Widget _buildBoutonPreparer() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _validationEnCours ? null : _validerCommande,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C2CB),
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
                "Valider la commande (preparer)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Bouton pour marquer comme livree
  Widget _buildBoutonMarquerLivree() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _validationEnCours ? null : _marquerLivree,
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
                "Marquer comme livree",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Valide la commande (preparation terminee)
  Future<void> _validerCommande() async {
    setState(() => _validationEnCours = true);
    final ok = await PharmacyService.validerCommande(widget.commande.id);
    setState(() => _validationEnCours = false);

    if (ok) {
      AppWidgets.showSnack(
        context,
        "Commande validee avec succes",
        color: const Color(0xFF22863A),
      );
      Navigator.pop(context, true);
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de la validation",
        color: AppColors.danger,
      );
    }
  }

  // Marque la commande comme livree
  Future<void> _marquerLivree() async {
    setState(() => _validationEnCours = true);
    // Note: endpoint specifique pour marquer livree si besoin
    // Sinon on utilise la meme methode
    final ok = await PharmacyService.validerCommande(widget.commande.id);
    setState(() => _validationEnCours = false);

    if (ok) {
      AppWidgets.showSnack(
        context,
        "Commande marquee comme livree",
        color: const Color(0xFF22863A),
      );
      Navigator.pop(context, true);
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de l'operation",
        color: AppColors.danger,
      );
    }
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
  Widget _buildBottomNav() {
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
              _navItem(Icons.dashboard_rounded, "Accueil", () => Navigator.pushReplacementNamed(context, '/dashboard_pharmacien')),
              _navItem(Icons.shopping_bag_rounded, "Commandes", () => Navigator.pop(context)),
              _navItem(Icons.medication_rounded, "Produits", () => Navigator.pushReplacementNamed(context, '/produits_pharmacien')),
              _navItem(Icons.account_circle_rounded, "Profil", () => Navigator.pushReplacementNamed(context, '/profil_pharmacien')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}