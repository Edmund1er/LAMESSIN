import 'utilisateur_model.dart';

class RendezVous {
  final int id;
  final Patient? patientDemandeur;
  final Medecin? medecinConcerne;
  final String dateRdv;
  final String heureRdv;
  final String motifConsultation;
  final String statutActuelRdv;

  RendezVous({
    required this.id,
    this.patientDemandeur,
    this.medecinConcerne,
    required this.dateRdv,
    required this.heureRdv,
    required this.motifConsultation,
    required this.statutActuelRdv,
  });

  factory RendezVous.fromJson(Map<String, dynamic> json) {
    return RendezVous(
      id: json['id'],
      patientDemandeur: json['patient_demandeur'] != null ? Patient.fromJson(json['patient_demandeur']) : null,
      medecinConcerne: json['medecin_concerne'] != null ? Medecin.fromJson(json['medecin_concerne']) : null,
      dateRdv: json['date_rdv'] ?? '',
      heureRdv: json['heure_rdv'] ?? '',
      motifConsultation: json['motif_consultation'] ?? '',
      statutActuelRdv: json['statut_actuel_rdv'] ?? 'inconnu',
    );
  }
}