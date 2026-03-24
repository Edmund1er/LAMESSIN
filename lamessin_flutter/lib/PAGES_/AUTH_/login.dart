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
  bool _chargement = false;

  void _clicConnexion() async {
    if (_telephone.text.isEmpty || _password.text.isEmpty) {
      _afficherMessage("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _chargement = true);

    try {
      String tel = _telephone.text.trim();
      String pass = _password.text;
      
      String? token = await ApiService.login(tel, pass);

      if (!mounted) return;

      if (token != null) {
        Navigator.pushReplacementNamed(context, "/page_utilisateur");
      } else {
        _afficherMessage("Numéro ou mot de passe incorrect");
      }
    } catch (e) {
      _afficherMessage("Erreur de connexion au serveur");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _afficherMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bienvenue",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3E50)),
              ),
              const SizedBox(height: 10),
              Text(
                "Connectez-vous à votre espace LAMESSIN",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration("Téléphone", Icons.phone_outlined),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: _decoration("Mot de passe", Icons.lock_outline),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _chargement ? null : _clicConnexion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _chargement
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("SE CONNECTER", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas encore de compte ? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/register"),
                    child: const Text("S'inscrire", style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}