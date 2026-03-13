import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _telephone = TextEditingController();
  final _password = TextEditingController();
  bool _chargement = false; // Pour éviter les doubles clics

  void _clicConnexion() async {
    if (_telephone.text.isEmpty || _password.text.isEmpty) {
      _afficherMessage("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _chargement = true);

    try {
      String tel = _telephone.text;
      String pass = _password.text;

      // Appel au serveur
      String? token = await ApiService.login(tel, pass);

      // CRUCIAL : On vérifie si l'écran est toujours affiché après l'attente
      if (!mounted) return;

      if (token != null) {
        Navigator.pushReplacementNamed(context, "/page_utilisateur");
      } else {
        _afficherMessage("Numéro ou mot de passe incorrect");
      }
    } catch (e) {
      if (!mounted) return;
      _afficherMessage("Erreur de connexion au serveur");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _afficherMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion LAMESSIN")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                TextField(
                  controller: _telephone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Téléphone",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 30),
                _chargement
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _clicConnexion,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("SE CONNECTER"),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/register");
                  },
                  child: const Text("Pas encore de compte ? S'inscrire"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}