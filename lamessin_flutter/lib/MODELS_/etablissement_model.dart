class EtablissementSante {
  final int id;
  final String nom;
  final String adresse;
  final String contact;
  final double latitude;
  final double longitude;
  final String plageHoraire;
  final String? imageEtablissement;
  final bool? pharmacieEstGarde; 
  final String? typeUrgences;    

  EtablissementSante({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.contact,
    required this.latitude,
    required this.longitude,
    required this.plageHoraire,
    this.imageEtablissement,
    this.pharmacieEstGarde,
    this.typeUrgences,
  });

  factory EtablissementSante.fromJson(Map<String, dynamic> json) {
    return EtablissementSante(
      id: json['id'],
      nom: json['nom'] ?? 'Sans nom',
      adresse: json['adresse'] ?? '',
      contact: json['contact'] ?? '',
      // Sécurité anti-crash
      latitude: (json['coordonnee_latitude_gps'] != null) 
          ? double.parse(json['coordonnee_latitude_gps'].toString()) 
          : 0.0,
      longitude: (json['coordonnee_longitude_gps'] != null) 
          ? double.parse(json['coordonnee_longitude_gps'].toString()) 
          : 0.0,
      plageHoraire: json['plage_horaire_ouverture'] ?? '',
      imageEtablissement: json['image_etablissement'],
      pharmacieEstGarde: json['pharmacie_est_garde'],
      typeUrgences: json['type_urgences'],
    );
  }
}