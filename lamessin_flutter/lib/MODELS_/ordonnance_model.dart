class Ordonnance {
  final int id;
  final String datePrescription;
  final String medecinNom;
  final String? codeSecurite;
  final String? fichierOrdonnance;
  final List<DetailOrdonnance> lignes;

  Ordonnance({
    required this.id,
    required this.datePrescription,
    required this.medecinNom,
    this.codeSecurite,
    this.fichierOrdonnance,
    required this.lignes,
  });

  factory Ordonnance.fromJson(Map<String, dynamic> json) {
    var lignesList = json['lignes'];
    List<DetailOrdonnance> lignes = [];
    if (lignesList != null) {
      lignes = (lignesList as List).map((i) => DetailOrdonnance.fromJson(i)).toList();
    }

    return Ordonnance(
      id: json['id'],
      datePrescription: json['date_prescription'] ?? '',
      medecinNom: json['medecin_nom'] ?? 'Dr Inconnu',
      codeSecurite: json['code_securite'],
      fichierOrdonnance: json['fichier_ordonnance'],
      lignes: lignes,
    );
  }
}

class DetailOrdonnance {
  final int id;
  final int medicamentId;
  final String nomMedicament;
  final int quantiteBoites;
  final String posologieSpecifique;
  final int dureeTraitementJours;

  DetailOrdonnance({
    required this.id,
    required this.medicamentId,
    required this.nomMedicament,
    required this.quantiteBoites,
    required this.posologieSpecifique,
    required this.dureeTraitementJours,
  });

  factory DetailOrdonnance.fromJson(Map<String, dynamic> json) {
    return DetailOrdonnance(
      id: json['id'],
      medicamentId: json['medicament'],
      nomMedicament: json['nom_medicament'] ?? 'Médicament',
      quantiteBoites: json['quantite_boites'] ?? 0,
      posologieSpecifique: json['posologie_specifique'] ?? '',
      dureeTraitementJours: json['duree_traitement_jours'] ?? 0,
    );
  }
}