import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
// --- Contrôleurs communs ---

  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

// --- Contrôleurs spécifiques aux rôles ---

  final TextEditingController _specialite = TextEditingController();
  final TextEditingController _licence = TextEditingController(); 

// Pour stocker A+, B-, etc.

  String? _groupeSanguinChoisi;

  final List<String> _groupes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  DateTime? _dateNaissance; 

// Rôle par défaut
  
  String _roleChoisi = "patient"; 

// Fonction pour choisir la date de naissance

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

// Préparation du dictionnaire (JSON) pour l'API

    Map<String, dynamic> monColis = {
      "username": _telephone.text,
      "numero_telephone": _telephone.text,
      "email": _email.text,
      "password": _password.text,
      "first_name": _prenom.text,
      "last_name": _nom.text,
      "type_compte": _roleChoisi,
    };

// Ajout des données selon le rôle choisi

    if (_roleChoisi == "patient") 
      {
        monColis["date_naissance"] = _dateNaissance?.toIso8601String().split('T')[0] ?? "2000-01-01";
    
        monColis["groupe_sanguin"] = _groupeSanguinChoisi; 
      } 
    else if (_roleChoisi == "medecin") 
      {
        monColis["specialite_medicale"] = _specialite.text;

        monColis["numero_licence"] = _licence.text;
      } 
    else if (_roleChoisi == "pharmacien") 
      {
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
        const SnackBar(content: Text("Échec de l'inscription. Vérifiez vos informations.")),
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
// 1. Sélecteur de rôle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'patient', label: Text('Patient'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'medecin', label: Text('Médecin'), icon: Icon(Icons.medical_services)),
                ButtonSegment(value: 'pharmacien', label: Text('Pharma'), icon: Icon(Icons.local_pharmacy)),
              ],
              selected: {_roleChoisi},
              onSelectionChanged: (newSelection) {
                setState(() => _roleChoisi = newSelection.first);
              },
            ),
            const SizedBox(height: 25),

// 2. Champs communs
            TextField(controller: _nom, decoration: const InputDecoration(labelText: "Nom", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _prenom, decoration: const InputDecoration(labelText: "Prénom", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _telephone, decoration: const InputDecoration(labelText: "N° Téléphone", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Mot de passe", border: OutlineInputBorder())),
            const SizedBox(height: 20),

// 3. Champs dynamiques
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
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Groupe Sanguin",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.opacity, color: Colors.red),
                ),
                value: _groupeSanguinChoisi,
                items: _groupes.map((String g) {
                  return DropdownMenuItem<String>(
                    value: g,
                    child: Text(g),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _groupeSanguinChoisi = val;
                  });
                },
              ),

            ] else if (_roleChoisi == "medecin") ...[
              TextField(controller: _specialite, decoration: const InputDecoration(labelText: "Spécialité (ex: Gynécologue)", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _licence, decoration: const InputDecoration(labelText: "N° de Licence Médicale", border: OutlineInputBorder())),
            ] else if (_roleChoisi == "pharmacien") ...[
              TextField(controller: _licence, decoration: const InputDecoration(labelText: "N° de Licence Pharmacie", border: OutlineInputBorder())),
            ],

            const SizedBox(height: 30),

// 4. Bouton final
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _lancerInscription,
                child: const Text("S'INSCRIRE MAINTENANT"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}