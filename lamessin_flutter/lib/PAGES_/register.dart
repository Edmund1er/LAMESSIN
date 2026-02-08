
import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';


class Register extends StatefulWidget {
  const Register({super.key});


  @override
  State<Register> createState() => _RegisterState();
}


class _RegisterState extends State<Register> {
  
//  on recupère le texte tapé
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

// fonction qui s'exécute quand on clique sur le bouton s'inscrire
  void _lancerInscription() async {
    

    Map<String, dynamic> monColis = {
      "username": _telephone.text, 
      "numero_telephone": _telephone.text,
      "email": _email.text,
      "password": _password.text,
      "first_name": _nom.text,
      "last_name": _prenom.text,
      "type_compte": "patient", 
      "date_naissance": "2000-01-01" 
    };


    bool succes = await ApiService.inscription(monColis);


    if (succes) {

      Navigator.pushReplacementNamed(context, "/login");
      

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inscription réussie ! Connectez-vous.")),
      );
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'inscription. Vérifiez vos infos.")),
      );
    }
  }

// fonction qui dessine l'interface sur l'écran du téléphone
  @override
  Widget build(BuildContext context) {
    return Scaffold(
// Barre de titre en haut de l'écran
      appBar: AppBar(title: const Text("Créer un compte")),
      
// Corps de la page
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(controller: _nom, decoration: const InputDecoration(labelText: "Nom")),
            

            TextField(controller: _prenom, decoration: const InputDecoration(labelText: "Prénom")),
            

            TextField(controller: _telephone, decoration: const InputDecoration(labelText: "N° Téléphone")),
            

            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            

            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Mot de passe")),
            

            const SizedBox(height: 30),
            

            ElevatedButton(
              onPressed: _lancerInscription, 
              child: const Text("S'INSCRIRE MAINTENANT"),
            ),
          ],
        ),
      ),
    );
  }
}