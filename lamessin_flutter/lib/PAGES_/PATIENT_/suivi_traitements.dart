import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';

class SuiviTraitementsPage extends StatefulWidget {
  const SuiviTraitementsPage({super.key});

  @override
  State<SuiviTraitementsPage> createState() => _SuiviTraitementsPageState();
}

class _SuiviTraitementsPageState extends State<SuiviTraitementsPage> {
  List<dynamic> _traitements = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerTraitements();
  }

  Future<void> _chargerTraitements() async {
    final data = await ApiService.getTraitements();
    setState(() {
      _traitements = data;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Mon Dossier Médical"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _traitements.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _traitements.length,
                  itemBuilder: (context, index) {
                    final t = _traitements[index];
                    bool estUnSoin = t.containsKey('diagnostic');
                    return estUnSoin ? _buildSoinCard(t) : _buildTraitementCard(t);
                  },
                ),
    );
  }

  Widget _buildSoinCard(dynamic s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal[50],
          child: const Icon(Icons.health_and_safety, color: Colors.teal),
        ),
        title: Text(s['diagnostic'] ?? "Consultation", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Le ${s['date_consultation']}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Notes :", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(s['notes_medecin'] ?? "R.A.S"),
              ],
            ),
          )
        ],
      ),
    );
  }

 Widget _buildTraitementCard(dynamic t) {
  // Logique pour savoir si le traitement est fini
  bool estFini = false;
  if (t['date_fin_traitement'] != null) {
    DateTime fin = DateTime.parse(t['date_fin_traitement']);
    estFini = fin.isBefore(DateTime.now());
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t['nom_du_traitement'] ?? "Médicament", 
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              // PETIT BADGE DE STATUT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estFini ? Colors.grey[200] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estFini ? "Terminé" : "En cours",
                  style: TextStyle(color: estFini ? Colors.grey : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, "Fréquence", t['posologie_traitement'] ?? "Voir notice"),
          _infoRow(Icons.event_note, "Fin prévue", t['date_fin_traitement'] ?? "Non définie"),
        ],
      ),
    ),
  );
}
  // CORRECTION ICI : Suppression du 'const' qui causait l'erreur
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey), // Correction de slateGrey
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Historique vide."));
  }
}