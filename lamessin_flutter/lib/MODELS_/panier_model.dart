class PanierItem {
  final int idMedoc;
  final int idPharmacie;
  final String nom;
  final String nomPharmacie; 
  final double prix;
  int quantite;

  PanierItem({
    required this.idMedoc,
    required this.idPharmacie,
    required this.nom,
    required this.nomPharmacie,
    required this.prix,
    required this.quantite,
  });


  double get prixTotalItem => prix * quantite;


  Map<String, dynamic> toLigneCommandeJson() {
    return {
      'medicament_ajoute': idMedoc,
      'pharmacie_vendeuse': idPharmacie,
      'quantite_commandee': quantite,
      'prix_unitaire': prix,
    };
  }
}