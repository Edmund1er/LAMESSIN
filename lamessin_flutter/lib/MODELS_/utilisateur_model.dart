class Utilisateur {
  final int id;
  final String username;
  final String email;
  final String numeroTelephone;
  final String firstName;
  final String lastName;
  final bool estUnComptePatient;
  final bool estUnCompteMedecin;
  final bool estUnComptePharmacien;
  final String? fcmToken;

  Utilisateur({
    required this.id,
    required this.username,
    required this.email,
    required this.numeroTelephone,
    required this.firstName,
    required this.lastName,
    required this.estUnComptePatient,
    required this.estUnCompteMedecin,
    required this.estUnComptePharmacien,
    this.fcmToken,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'],
      username: json['username'],
      email: (json['email'] as String?) ?? '',
      numeroTelephone: (json['numero_telephone'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      estUnComptePatient: json['est_un_compte_patient'] ?? false,
      estUnCompteMedecin: json['est_un_compte_medecin'] ?? false,
      estUnComptePharmacien: json['est_un_compte_pharmacien'] ?? false,
      fcmToken: json['fcm_token'],
    );
  }
}

class Patient {
  final Utilisateur compteUtilisateur;
  final String? dateNaissance;
  final String? groupeSanguin;
  final String? photoProfil;

  Patient({
    required this.compteUtilisateur,
    this.dateNaissance,
    this.groupeSanguin,
    this.photoProfil,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      compteUtilisateur: Utilisateur.fromJson(json['compte_utilisateur']),
      dateNaissance: json['date_naissance'],
      groupeSanguin: json['groupe_sanguin'] ?? 'Inconnu',
      photoProfil: json['photo_profil'],
    );
  }
}

class Medecin {
  final Utilisateur compteUtilisateur;
  final String specialiteMedicale;
  final String numeroLicence;
  final String? photoProfil;

  Medecin({
    required this.compteUtilisateur,
    required this.specialiteMedicale,
    required this.numeroLicence,
    this.photoProfil,
  });

  factory Medecin.fromJson(Map<String, dynamic> json) {
    return Medecin(
      compteUtilisateur: Utilisateur.fromJson(json['compte_utilisateur']),
      specialiteMedicale: (json['specialite_medicale'] as String?) ?? 'Generaliste',
      numeroLicence: (json['numero_licence'] as String?) ?? '0000',
      photoProfil: json['photo_profil'],
    );
  }
}

class Pharmacien {
  final Utilisateur compteUtilisateur;
  final String nomPharmacie;
  final String adressePharmacie;
  final String numeroPharmacie;

  Pharmacien({
    required this.compteUtilisateur,
    required this.nomPharmacie,
    required this.adressePharmacie,
    required this.numeroPharmacie,
  });

  factory Pharmacien.fromJson(Map<String, dynamic> json) {
    return Pharmacien(
      compteUtilisateur: Utilisateur.fromJson(json['compte_utilisateur']),
      nomPharmacie: json['nom_pharmacie'] ?? "Non renseigne",
      adressePharmacie: json['adresse_pharmacie'] ?? "",
      numeroPharmacie: json['numero_pharmacie'] ?? "",
    );
  }
}