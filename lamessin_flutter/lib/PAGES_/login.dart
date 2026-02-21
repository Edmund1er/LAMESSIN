import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
// Les boîtes pour lire ce que l'utilisateur écrit
  final _telephone = TextEditingController();
  final _password = TextEditingController();

// La fonction qui se lance quand on clique sur le bouton
  void _clicConnexion() async {
    // 1. On récupère le texte tapé
    String tel = _telephone.text;
    String pass = _password.text;

//On demande au serveur Django si c'est bon
    String? token = await ApiService.login(tel, pass);

//  On vérifie le résultat
    if (token != null) {
//  On va à la page d'accueil du patient si ca marche
      Navigator.pushReplacementNamed(context, "/dashboard_patient");
    } else {
// On affiche un petit message d'erreur en bas si il ya erreur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro ou mot de passe incorrect")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion LAMESSIN")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50),
// Case pour le téléphone
            TextField(
              controller: _telephone,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
            const SizedBox(height: 20),
// Case pour le mot de passe
            TextField(
              controller: _password,
              obscureText: true, 
              decoration: const InputDecoration(labelText: "Mot de passe"),
            ),
            const SizedBox(height: 30),
// Le bouton
            ElevatedButton(
              onPressed: _clicConnexion, 
              child: const Text("SE CONNECTER"),
            ),
// Lien pour aller s'inscrire si on n'a pas de compte
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/register");
              },
              child: const Text("Pas encore de compte ? S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}