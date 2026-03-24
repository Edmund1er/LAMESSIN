class Commande {
  final int id;
  final String patientNom;
  final String dateCreation;
  final String statut;
  final String methodeRetrait;
  final List<LigneCommande> lignes;
  final double total;
  final String? estimationRetrait;
  final String? transactionId;

  Commande({
    required this.id,
    required this.patientNom,
    required this.dateCreation,
    required this.statut,
    required this.methodeRetrait,
    required this.lignes,
    required this.total,
    this.estimationRetrait,
    this.transactionId,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    var lignesList = json['lignes'];
    List<LigneCommande> lignes = [];
    if (lignesList != null) {
      lignes = (lignesList as List).map((i) => LigneCommande.fromJson(i)).toList();
    }

    return Commande(
      id: json['id'],
      patientNom: json['patient_nom'] ?? 'Patient',
      dateCreation: json['date_creation'] ?? '',
      statut: json['statut'] ?? 'INCONNU',
      methodeRetrait: json['methode_retrait'] ?? 'RETRAIT',
      lignes: lignes,
      total: double.parse((json['total'] ?? 0).toString()),
      estimationRetrait: json['estimation_retrait'],
      transactionId: json['transaction_id'],
    );
  }
}

class LigneCommande {
  final int id;
  final String nomMedicament;
  final int quantite;
  final double prixUnitaire;
  final String? imageProduit;
  final String pharmacieNom;

  LigneCommande({
    required this.id,
    required this.nomMedicament,
    required this.quantite,
    required this.prixUnitaire,
    this.imageProduit,
    required this.pharmacieNom,
  });

  factory LigneCommande.fromJson(Map<String, dynamic> json) {
    return LigneCommande(
      id: json['id'],
      nomMedicament: json['nom_medicament'] ?? 'Médicament',
      quantite: json['quantite'] ?? 0,
      prixUnitaire: double.parse((json['prix_unitaire'] ?? 0).toString()),
      imageProduit: json['image_produit'],
      pharmacieNom: json['pharmacie_nom'] ?? 'Pharmacie',
    );
  }
}