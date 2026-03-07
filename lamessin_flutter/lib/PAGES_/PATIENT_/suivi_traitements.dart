import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Suivi des Traitements"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _traitements.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _traitements.length,
                  itemBuilder: (context, index) {
                    final t = _traitements[index];
                    return _buildTraitementCard(t);
                  },
                ),
    );
  }

  Widget _buildTraitementCard(dynamic t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t['nom_du_traitement'] ?? "Médicament",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Icon(Icons.medication, color: Colors.green),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.timer, "Posologie", t['posologie_traitement'] ?? "Selon ordonnance"),
            _infoRow(Icons.calendar_today, "Fin prévue", t['date_fin_traitement'] ?? "Non définie"),
            
            // Référence à l'ordonnance (selon ton modèle Django)
            if (t['ordonnance_associee'] != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 16, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      "Ordonnance n°${t['ordonnance_associee']}",
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Aucun traitement actif enregistré.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}