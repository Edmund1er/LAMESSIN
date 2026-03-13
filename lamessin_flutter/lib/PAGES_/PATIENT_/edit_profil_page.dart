import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class EditProfilPage extends StatefulWidget {
  final Map<String, dynamic> profilActuel;
  const EditProfilPage({super.key, required this.profilActuel});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _telController;
  bool _enChargement = false;

  final Color couleurVerte = const Color.fromARGB(255, 78, 192, 17);
  final Color couleurBleue = const Color(0xFF0056b3);

  @override
  void initState() {
    super.initState();
    final compte = widget.profilActuel['compte_utilisateur'] ?? {};
    _prenomController = TextEditingController(text: compte['first_name']);
    _nomController = TextEditingController(text: compte['last_name']);
    _telController = TextEditingController(text: compte['numero_telephone']);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  void _sauvegarder() async {
// Validation
    if (_prenomController.text.isEmpty || _nomController.text.isEmpty || _telController.text.isEmpty) {
      _afficherMessage("Veuillez remplir tous les champs obligatoires", Colors.red);
      return;
    }

    setState(() => _enChargement = true);
    
// Le groupe sanguin n'est PAS inclus ici
    Map<String, dynamic> data = {
      "first_name": _prenomController.text,
      "last_name": _nomController.text,
      "numero_telephone": _telController.text,
    };

    bool succes = await ApiService.updateProfil(data);

    if (mounted) {
      setState(() => _enChargement = false);
      if (succes) {
        Navigator.pop(context, true); // Succès : retourne true
      } else {
        _afficherMessage("Erreur lors de la mise à jour des données", Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text("Modifier Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: couleurBleue,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
// --- HEADER DECORATIF DEGRADÉ ---
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [couleurVerte.withOpacity(0.8), couleurBleue],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text("Vos coordonnées", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 30),

// --- FORMULAIRE STYLISÉ ---
                  _buildPremiumField(_prenomController, "Prénom", Icons.person_outline_rounded),
                  const SizedBox(height: 15),
                  _buildPremiumField(_nomController, "Nom", Icons.person_outline_rounded),
                  const SizedBox(height: 15),
                  _buildPremiumField(_telController, "Numéro de téléphone", Icons.phone_android_rounded, keyboard: TextInputType.phone),

                  const SizedBox(height: 45),

// --- BOUTON ENREGISTRER  ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _enChargement ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 78, 192, 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                      ),
                      child: _enChargement 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("SAUVEGARDER LES MODIFICATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Widget pour des champs de saisie 

  Widget _buildPremiumField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: couleurBleue.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: couleurBleue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: couleurBleue, width: 1.5)),
        ),
      ),
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur, behavior: SnackBarBehavior.floating));
  }
}