class Traitement {
  final int id;
  final String nomDuTraitement;
  final String dateDebut;
  final String dateFin;
  final List<PriseMedicament> prises;

  Traitement({
    required this.id,
    required this.nomDuTraitement,
    required this.dateDebut,
    required this.dateFin,
    required this.prises,
  });

  factory Traitement.fromJson(Map<String, dynamic> json) {

    var prisesList = json['prises'];
    List<PriseMedicament> prises = [];
    if (prisesList != null) {
      prises = (prisesList as List).map((i) => PriseMedicament.fromJson(i)).toList();
    }

    return Traitement(
      id: json['id'],
      nomDuTraitement: json['nom_du_traitement'] ?? 'Traitement sans nom',
      dateDebut: json['date_debut_traitement'] ?? '',
      dateFin: json['date_fin_traitement'] ?? '',
      prises: prises,
    );
  }
}

class PriseMedicament {
  final int id;
  final String heurePrisePrevue;
  final bool priseEffectuee;
  final String? datePriseReelle;

  PriseMedicament({
    required this.id,
    required this.heurePrisePrevue,
    required this.priseEffectuee,
    this.datePriseReelle,
  });

  factory PriseMedicament.fromJson(Map<String, dynamic> json) {
    return PriseMedicament(
      id: json['id'],
      heurePrisePrevue: json['heure_prise_prevue'] ?? '00:00',
      priseEffectuee: json['prise_effectuee'] ?? false,
      datePriseReelle: json['date_prise_reelle'],
    );
  }
}