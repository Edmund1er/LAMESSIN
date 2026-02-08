
import 'package:flutter/material.dart';
import '../SERVICES_/api_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _telephone = TextEditingController();
  final _password = TextEditingController();

  void _clicConnexion() async 
  {
    String tel = _telephone.text.trim();
    String pass = _password.text.trim();

    String? token = await ApiService.login(tel, pass);

    if (token != null) {
       Navigator.pushReplacementNamed(context, "/home_page");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro ou mot de passe incorrect")),
      );
    }
  }

     


  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion LAMESSIN")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _telephone,
              decoration: const InputDecoration(
                labelText: "N° Téléphone",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _clicConnexion,
                child: const Text("SE CONNECTER"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/register"),
              child: const Text("Pas encore de compte ? Inscrivez-vous"),
            )
          ],
        ),
      ),
    );
  }
}