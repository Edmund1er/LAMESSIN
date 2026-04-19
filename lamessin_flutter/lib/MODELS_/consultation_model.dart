import 'ordonnance_model.dart';

class Consultation {
  final int id;
  final int rdvId;
  final String diagnostic;
  final String actesEffectues;
  final String? notesMedecin;
  final String dateConsultation;
  final String? documentJoint; 
  final List<Ordonnance> ordonnances;

  Consultation({
    required this.id,
    required this.rdvId,
    required this.diagnostic,
    required this.actesEffectues,
    this.notesMedecin,
    required this.dateConsultation,
    this.documentJoint, 
    required this.ordonnances,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    
    var ordsList = json['ordonnances'];
    List<Ordonnance> ords = [];
    if (ordsList != null) {
      ords = (ordsList as List).map((i) => Ordonnance.fromJson(i)).toList();
    }

    return Consultation(
      id: json['id'],
      rdvId: json['rdv'],
      diagnostic: json['diagnostic'] ?? "Non précisé",
      actesEffectues: json['actes_effectues'] ?? "",
      notesMedecin: json['notes_medecin'],
      dateConsultation: json['date_consultation'] ?? "",
      documentJoint: json['document_joint'], 
      ordonnances: ords,
    );
  }
}