import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
<<<<<<< HEAD
  // Contrôleurs communs
=======
  // --- Contrôleurs pour récupérer le texte ---
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
<<<<<<< HEAD

  // Contrôleurs spécifiques
  final TextEditingController _specialite = TextEditingController();
  DateTime? _dateNaissance;
  String _roleChoisi = "patient";

  // Fonction pour choisir la date
=======
  
  // Contrôleurs spécifiques aux rôles
  final TextEditingController _specialite = TextEditingController();
  final TextEditingController _licence = TextEditingController(); 
  
  DateTime? _dateNaissance; 
  String _roleChoisi = "patient"; // Rôle par défaut

  // Fonction simple pour choisir la date de naissance
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
  Future<void> _selectionnerDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  // Fonction qui envoie les données à Django
  void _lancerInscription() async {
<<<<<<< HEAD
    // On prépare le colis dynamiquement
=======
    // Préparation du dictionnaire (JSON) pour l'API
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
    Map<String, dynamic> monColis = {
      "username": _telephone.text,
      "numero_telephone": _telephone.text,
      "email": _email.text,
      "password": _password.text,
      "first_name": _prenom.text,
      "last_name": _nom.text,
      "type_compte": _roleChoisi,
    };

<<<<<<< HEAD
    // Ajout des données selon le rôle
    if (_roleChoisi == "patient") {
      monColis["date_naissance"] =
          _dateNaissance?.toIso8601String().split('T')[0] ?? "2000-01-01";
    } else {
=======
    // Ajout des données selon le rôle choisi
    if (_roleChoisi == "patient") {
      monColis["date_naissance"] = _dateNaissance?.toIso8601String().split('T')[0] ?? "2000-01-01";
    } else if (_roleChoisi == "medecin") {
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
      monColis["specialite_medicale"] = _specialite.text;
      monColis["numero_licence"] = _licence.text;
    } else if (_roleChoisi == "pharmacien") {
      monColis["numero_licence"] = _licence.text;
    }

    // Envoi au service API
    bool succes = await ApiService.inscription(monColis);

    if (succes) {
      Navigator.pushReplacementNamed(context, "/login");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inscription réussie ! Connectez-vous.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
        const SnackBar(
          content: Text("Échec de l'inscription. Vérifiez vos infos."),
        ),
=======
        const SnackBar(content: Text("Échec. Vérifiez vos informations.")),
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte LAMESSIN")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
<<<<<<< HEAD
            // Sélecteur de rôle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'patient',
                  label: Text('Patient'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment(
                  value: 'medecin',
                  label: Text('Médecin'),
                  icon: Icon(Icons.medical_services),
                ),
=======
            // 1. Sélecteur de rôle (3 choix)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'patient', label: Text('Patient'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'medecin', label: Text('Médecin'), icon: Icon(Icons.medical_services)),
                ButtonSegment(value: 'pharmacien', label: Text('Pharma'), icon: Icon(Icons.local_pharmacy)),
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
              ],
              selected: {_roleChoisi},
              onSelectionChanged: (newSelection) {
                setState(() => _roleChoisi = newSelection.first);
              },
            ),
            const SizedBox(height: 25),

<<<<<<< HEAD
            // Champs communs
            TextField(
              controller: _nom,
              decoration: const InputDecoration(
                labelText: "Nom",
                border: OutlineInputBorder(),
              ),
            ),
=======
            // 2. Champs communs à tout le monde
            TextField(controller: _nom, decoration: const InputDecoration(labelText: "Nom", border: OutlineInputBorder())),
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
            const SizedBox(height: 15),
            TextField(
              controller: _prenom,
              decoration: const InputDecoration(
                labelText: "Prénom",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _telephone,
              decoration: const InputDecoration(
                labelText: "N° Téléphone",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
<<<<<<< HEAD
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // --- CHAMPS DYNAMIQUES ---
=======
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Mot de passe", border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // 3. Champs dynamiques (S'affichent selon le rôle)
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
            if (_roleChoisi == "patient") ...[
              ListTile(
                title: Text(
                  _dateNaissance == null
                      ? "Choisir date de naissance"
                      : "Né le : ${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}",
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _selectionnerDate(context),
                tileColor: Colors.blue.withOpacity(0.1),
              ),
            ] else if (_roleChoisi == "medecin") ...[
<<<<<<< HEAD
              TextField(
                controller: _specialite,
                decoration: const InputDecoration(
                  labelText: "Spécialité (ex: Cardiologue)",
                  border: OutlineInputBorder(),
                ),
              ),
=======
              TextField(controller: _specialite, decoration: const InputDecoration(labelText: "Spécialité (ex: Gynécologue)", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _licence, decoration: const InputDecoration(labelText: "N° de Licence Médicale", border: OutlineInputBorder())),
            ] else if (_roleChoisi == "pharmacien") ...[
              TextField(controller: _licence, decoration: const InputDecoration(labelText: "N° de Licence Pharmacie", border: OutlineInputBorder())),
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
            ],

            const SizedBox(height: 30),

            // 4. Bouton final
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _lancerInscription,
<<<<<<< HEAD
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
=======
>>>>>>> 299d3890afda8f2dba663c83102986d4e9b19302
                child: const Text("S'INSCRIRE MAINTENANT"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
