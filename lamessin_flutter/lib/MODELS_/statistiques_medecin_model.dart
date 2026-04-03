import 'rendezvous_model.dart';

class StatistiquesMedecin {
  final int rdvAujourdhui;
  final int rdvAVenir;
  final int consultationsTotal;
  final int patientsUniques;
  final List<RendezVous> prochainsRdv;
  final List<Map<String, dynamic>> consultationsParMois;
  final List<Map<String, dynamic>> topMedicaments;

  StatistiquesMedecin({
    required this.rdvAujourdhui,
    required this.rdvAVenir,
    required this.consultationsTotal,
    required this.patientsUniques,
    required this.prochainsRdv,
    required this.consultationsParMois,
    required this.topMedicaments,
  });

  factory StatistiquesMedecin.fromJson(Map<String, dynamic> json) {
    return StatistiquesMedecin(
      rdvAujourdhui: json['rdv_aujourdhui'] ?? 0,
      rdvAVenir: json['rdv_a_venir'] ?? 0,
      consultationsTotal: json['consultations_total'] ?? 0,
      patientsUniques: json['patients_uniques'] ?? 0,
      prochainsRdv: (json['prochains_rdv'] as List?)
          ?.map((e) => RendezVous.fromJson(e))
          .toList() ?? [],
      consultationsParMois: (json['consultations_par_mois'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      topMedicaments: (json['top_medicaments'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
    );
  }
}
