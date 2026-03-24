class Medicament {
  final int id;
  final String nomCommercial;
  final String description;
  final String posologieStandard;
  final double prixVente;
  final String? imageProduit;
  final List<StockPharmacie> stocksDisponibles;

  Medicament({
    required this.id,
    required this.nomCommercial,
    required this.description,
    required this.posologieStandard,
    required this.prixVente,
    this.imageProduit,
    required this.stocksDisponibles,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    var stocksList = json['stocks_disponibles'];
    List<StockPharmacie> stocks = [];
    if (stocksList != null) {
      stocks = (stocksList as List)
          .map((i) => StockPharmacie.fromJson(i))
          .toList();
    }

    return Medicament(
      id: json['id'],
      nomCommercial: json['nom_commercial'] ?? 'Inconnu',
      description: json['description'] ?? '',
      posologieStandard: json['posologie_standard'] ?? '',
      prixVente: double.parse((json['prix_vente'] ?? 0).toString()),
      imageProduit: json['image_produit'],
      stocksDisponibles: stocks,
    );
  }
}

class StockPharmacie {
  final int idStock;
  final int idPharmacie;
  final String nomPharmacie;
  final String adressePharmacie;
  final int quantiteEnStock;
  final String datePeremption;
  final double latitude;
  final double longitude;

  StockPharmacie({
    required this.idStock,
    required this.idPharmacie,
    required this.nomPharmacie,
    required this.adressePharmacie,
    required this.quantiteEnStock,
    required this.datePeremption,
    required this.latitude,
    required this.longitude,
  });

  factory StockPharmacie.fromJson(Map<String, dynamic> json) {
    return StockPharmacie(
      idStock: json['id_pharmacie'], // CORRECTION ICI : clé JSON correcte
      idPharmacie: json['id_pharmacie'] ?? 0,
      nomPharmacie: json['nom_pharmacie'] ?? 'Pharmacie inconnue',
      adressePharmacie: json['adresse_pharmacie'] ?? '',
      quantiteEnStock: json['quantite_actuelle_en_stock'] ?? 0,
      datePeremption: json['date_peremption'] ?? '',
      latitude: (json['latitude'] != null)
          ? double.parse(json['latitude'].toString())
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.parse(json['longitude'].toString())
          : 0.0,
    );
  }
}
