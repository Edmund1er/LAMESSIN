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
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Mon Dossier Médical", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _chargerTraitements,
              child: _traitements.isEmpty 
                ? _buildEmptyState() 
                : _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _traitements.length,
      itemBuilder: (context, index) {
        final t = _traitements[index];
        bool estUnSoin = t.containsKey('diagnostic');
        return estUnSoin ? _buildSoinCard(t) : _buildTraitementCard(t);
      },
    );
  }

  Widget _buildSoinCard(dynamic s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
          child: const Icon(Icons.description_rounded, color: Colors.blue),
        ),
        title: Text(s['diagnostic'] ?? "Consultation", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: Text("Consultation du ${s['date_consultation']}", style: TextStyle(color: Colors.grey[600])),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(Icons.medical_services, "Actes", s['actes_effectues'] ?? "Examen clinique"),
                const SizedBox(height: 8),
                const Text("Notes du médecin :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(s['notes_medecin'] ?? "Pas de notes particulières.", style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTraitementCard(dynamic t) {
    List<dynamic> prises = t['prises'] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF0FDF4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[100]!),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
          child: const Icon(Icons.medication_liquid, color: Colors.green),
        ),
        title: Text(t['nom_du_traitement'] ?? "Traitement", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Jusqu'au ${t['date_fin_traitement']}", style: TextStyle(color: Colors.green[700], fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Suivi des prises", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                ...prises.map((p) => _buildPriseRow(p)).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriseRow(dynamic p) {
    bool done = p['prise_effectuee'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: done ? null : () async {
          bool ok = await ApiService.validerPriseMedicament(p['id']);
          if (ok) _chargerTraitements();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: done ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: done ? Colors.green[200]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? Colors.green : Colors.grey),
              const SizedBox(width: 12),
              Text("Prise de ${p['heure_prise_prevue']}", style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
              const Spacer(),
              if (!done) const Text("Cocher", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Aucune donnée médicale", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}