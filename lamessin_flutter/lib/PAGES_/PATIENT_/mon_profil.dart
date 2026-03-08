import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'edit_profil_page.dart'; 

class ProfilPatientPage extends StatefulWidget {
  const ProfilPatientPage({super.key});

  @override
  State<ProfilPatientPage> createState() => _ProfilPatientPageState();
}

class _ProfilPatientPageState extends State<ProfilPatientPage> {
  Map<String, dynamic>? _profil;
  bool _chargement = true;

  // Définition des couleurs pour l'harmonie
  final Color couleurVerte = const Color.fromARGB(255, 83, 241, 115);
  final Color couleurBleue = const Color.fromARGB(255, 22, 132, 230);
  final Color couleurFond = const Color.fromARGB(255, 159, 209, 233);

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final data = await ApiService.getProfil();
    if (mounted) {
      setState(() {
        _profil = data;
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compte = _profil?['compte_utilisateur'] ?? {};
    final prenom = compte['first_name'] ?? "Patient";
    final nom = compte['last_name'] ?? "";
    final email = compte['email'] ?? "Email non renseigné";
    final telephone = compte['numero_telephone'] ?? "Téléphone non renseigné";
    final groupeSanguin = _profil?['groupe_sanguin'] ?? "Inconnu";

    return Scaffold(
      backgroundColor: couleurFond,
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: couleurBleue,
        elevation: 1,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerProfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
// --- HEADER AVEC DÉGRADÉ HARMONIEUX ---
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            couleurVerte.withOpacity(0.8),
                            couleurBleue,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 60, color: Color(0xFF0056b3)),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "$prenom $nom",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            email,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

// --- CONTENU PRINCIPAL ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
// 1. INFORMATIONS PERSONNELLES
                          _buildCardInfo([
                            _buildInfoTile(Icons.phone_android_rounded, "Téléphone", telephone),
                            _buildInfoTile(Icons.alternate_email_rounded, "Email", email),
                          ]),

                          const SizedBox(height: 20),

// 2. DOSSIER MÉDICAL (Non modifiable)
                          _buildCardInfo([
                            Row(
                              children: [
                                Icon(Icons.opacity_rounded, color: Colors.red, size: 28),
                                const SizedBox(width: 15),
                                const Text("Groupe Sanguin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: couleurVerte.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    groupeSanguin,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ]),

                          const SizedBox(height: 35),

// --- BOUTON MODIFIER (Premium) ---
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditProfilPage(profilActuel: _profil!)),
                                );
                                if (updated == true) _chargerProfil();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 78, 192, 17), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 3,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text("MODIFIER MES INFORMATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget pour créer les cartes blanches avec ombres
  Widget _buildCardInfo(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: couleurBleue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: couleurBleue),
          title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
      ],
    );
  }
}