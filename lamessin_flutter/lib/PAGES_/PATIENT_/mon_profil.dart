import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class ProfilPatientPage extends StatefulWidget {
  const ProfilPatientPage({super.key});

  @override
  State<ProfilPatientPage> createState() => _ProfilPatientPageState();
}

class _ProfilPatientPageState extends State<ProfilPatientPage> {
  Map<String, dynamic>? _profil;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final data = await ApiService.getProfil();
    setState(() {
      _profil = data;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extraction simplifiée des données
    final compte = _profil?['compte_utilisateur'] ?? {};
    final prenom = compte['first_name'] ?? "Prénom";
    final nom = compte['last_name'] ?? "Nom";
    final email = compte['email'] ?? "Non renseigné";
    final telephone = compte['numero_telephone'] ?? "Non renseigné";
    final groupeSanguin = _profil?['groupe_sanguin'] ?? "Inconnu";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- HEADER PROFIL ---
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF0056b3),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "$prenom $nom",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 30),

                  // --- INFOS PERSONNELLES ---
                  _buildSectionTitle("Informations Personnelles"),
                  _buildInfoTile(Icons.phone, "Téléphone", telephone),
                  _buildInfoTile(Icons.email, "Email", email),

                  const SizedBox(height: 25),

                  // --- DOSSIER MÉDICAL RAPIDE ---
                  _buildSectionTitle("Dossier Médical"),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.opacity, color: Colors.red),
                        const SizedBox(width: 15),
                        const Text("Groupe Sanguin", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          groupeSanguin,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- BOUTON MODIFIER ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action pour modifier le profil plus tard
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Modifier mes informations", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056b3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0056b3)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
      contentPadding: EdgeInsets.zero,
    );
  }
}