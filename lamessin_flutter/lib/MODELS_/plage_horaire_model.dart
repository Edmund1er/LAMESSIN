
class PlageHoraire {
  final int id;
  final int medecinId;
  final String date;
  final String heureDebut;
  final String heureFin;
  final int dureeConsultation;

  PlageHoraire({
    required this.id,
    required this.medecinId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.dureeConsultation,
  });

  factory PlageHoraire.fromJson(Map<String, dynamic> json) {
    return PlageHoraire(
      id: json['id'],
      medecinId: json['medecin'],
      date: json['date'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      heureFin: json['heure_fin'] ?? '',
      dureeConsultation: json['duree_consultation'] ?? 60,
    );
  }
}


// statistiques_pharmacien_model.dart
