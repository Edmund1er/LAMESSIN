import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'edit_profil_page.dart';

class ProfilPatientPage extends StatefulWidget {
  const ProfilPatientPage({super.key});

  @override
  State<ProfilPatientPage> createState() => _ProfilPatientPageState();
}

class _ProfilPatientPageState extends State<ProfilPatientPage> {
  dynamic _user;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final data = await ApiService.getProfil();
    if (mounted) {
      setState(() {
        _user = data;
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text("Erreur de chargement")));

    String nom = "";
    String prenom = "";
    String tel = "";
    String email = "";
    String infoSante = "";

    if (_user is Patient) {
      final p = _user as Patient;
      nom = p.compteUtilisateur.lastName;
      prenom = p.compteUtilisateur.firstName;
      tel = p.compteUtilisateur.numeroTelephone ?? "Non renseigné";
      
      // CORRECTION ICI : On ne vérifie pas le null, mais le vide (.isEmpty)
      String rawEmail = p.compteUtilisateur.email ?? "";
      email = rawEmail.isEmpty ? "Non renseigné" : rawEmail;
      
      infoSante = "Groupe: ${p.groupeSanguin ?? 'Inconnu'}";
    } else if (_user is Utilisateur) {
      final u = _user as Utilisateur;
      nom = u.lastName;
      prenom = u.firstName;
      tel = u.numeroTelephone;
      email = u.email.isEmpty ? "Non renseigné" : u.email;
      infoSante = "Compte Utilisateur";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(30), 
                    decoration: const BoxDecoration(
                      color: Colors.blue, 
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
                    ), 
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue)), 
                        const SizedBox(height: 15), 
                        Text("$prenom $nom", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), 
                        Text(tel, style: const TextStyle(color: Colors.white70))
                      ]
                    )
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInfoTile(Icons.email, "Email", email),
                  _buildInfoTile(Icons.phone, "Téléphone", tel),
                  _buildInfoTile(Icons.info_outline, "Statut", infoSante),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius:10, offset: Offset(0,-5))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_user is Patient) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilPage(patient: _user))).then((_) => _chargerProfil());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modification disponible pour le profil patient complet")));
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("MODIFIER MON PROFIL"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueGrey), 
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 14)), 
      subtitle: Text(value, style: const TextStyle(fontSize: 15))
    );
  }
}