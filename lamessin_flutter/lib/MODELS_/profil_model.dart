class PatientProfil {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String groupeSanguin;
  final String? photo;

  PatientProfil({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    required this.groupeSanguin,
    this.photo,
  });

  factory PatientProfil.fromJson(Map<String, dynamic> json) {
    final compte = json['compte_utilisateur'] ?? {};
    return PatientProfil(
      id: json['id'] ?? 0,
      firstName: compte['first_name'] ?? '',
      lastName: compte['last_name'] ?? '',
      email: compte['email'] ?? '',
      telephone: compte['numero_telephone'] ?? '',
      groupeSanguin: json['groupe_sanguin'] ?? 'Inconnu',
      photo: json['photo_profil'],
    );
  }
}