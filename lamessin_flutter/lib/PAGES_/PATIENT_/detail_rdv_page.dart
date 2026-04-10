import 'package:flutter/material.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../THEME_/app_theme.dart';

class DetailRdvPage extends StatelessWidget {
  static const Color _brandColor = Color(0xFF00C2CB);
  final RendezVous rendezVous;

  const DetailRdvPage({super.key, required this.rendezVous});

  @override
  Widget build(BuildContext context) {
    final nomMedecin = rendezVous.medecinConcerne?.compteUtilisateur.lastName ?? "Médecin";
    final prenomMedecin = rendezVous.medecinConcerne?.compteUtilisateur.firstName ?? "";
    final specialite = rendezVous.medecinConcerne?.specialiteMedicale ?? "Généraliste";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: const Text("Détail du rendez-vous", 
            style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _brandColor),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/rdv.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.75),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte médecin
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: _brandColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded,
                            color: _brandColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dr $nomMedecin $prenomMedecin",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _brandColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialite,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Informations du rendez-vous
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informations du rendez-vous",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        Icons.calendar_today_rounded,
                        "Date",
                        rendezVous.dateRdv,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.access_time_rounded,
                        "Heure",
                        rendezVous.heureRdv,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.description_rounded,
                        "Motif",
                        rendezVous.motifConsultation,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.info_outline_rounded,
                        "Statut",
                        _getStatutText(rendezVous.statutActuelRdv),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Bouton retour
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _brandColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Retour",
                      style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente de confirmation';
      case 'confirme': return 'Confirmé';
      case 'annulé': return 'Annulé';
      case 'termine': return 'Terminé';
      default: return statut;
    }
  }
}