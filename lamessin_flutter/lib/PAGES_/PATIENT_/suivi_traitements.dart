import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/traitement_model.dart';
import '../../MODELS_/consultation_model.dart'; // Assure-toi que ce modèle existe
import 'package:url_launcher/url_launcher.dart';

class SuiviTraitementsPage extends StatefulWidget {
  const SuiviTraitementsPage({super.key});

  @override
  State<SuiviTraitementsPage> createState() => _SuiviTraitementsPageState();
}

class _SuiviTraitementsPageState extends State<SuiviTraitementsPage> {
  // On crée une liste dynamique qui peut contenir des Traitement OU des Consultation
  List<dynamic> _donnees = []; 
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    
    // On récupère les deux listes
    final traitements = await ApiService.getTraitements();
    final consultations = await ApiService.getMesConsultations();

    if (mounted) {
      setState(() {
        // On fusionne les deux listes dans une seule liste 'dynamic'
        _donnees = [...consultations, ...traitements];
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Suivi Médical", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              child: _donnees.isEmpty 
                  ? _buildEmptyState() 
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _donnees.length,
                      itemBuilder: (context, index) {
                        final item = _donnees[index];
                        
                        // CORRECTION ICI : On vérifie le TYPE de l'objet au lieu de faire containsKey sur un objet
                        if (item is Consultation) {
                          return _buildConsultationCard(item);
                        } else if (item is Traitement) {
                          return _buildTraitementCard(item);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
    );
  }

  Widget _buildConsultationCard(Consultation s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: const Icon(Icons.assignment_ind, color: Colors.blue),
        title: Text(s.diagnostic, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Le ${s.dateConsultation}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Notes du médecin :", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(s.notesMedecin ?? "Aucune note."),
                
                // CORRECTION ICI : On utilise maintenant _ouvrirFichier
                if (s.documentJoint != null && s.documentJoint!.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      // On construit l'URL complète car le backend renvoie un chemin relatif
                      String fullUrl = '${ApiService.mediaBaseUrl}${s.documentJoint}';
                      _ouvrirFichier(fullUrl);
                    },
                    icon: const Icon(Icons.file_present),
                    label: const Text("Voir le document joint"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTraitementCard(Traitement t) {
    List<PriseMedicament> prises = t.prises;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.green[100]!)),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.medication, color: Colors.green),
        title: Text(t.nomDuTraitement, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Fin le ${t.dateFin}", style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: prises.map((p) => _buildPriseItem(p)).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriseItem(PriseMedicament p) {
    bool done = p.priseEffectuee;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.grey),
      title: Text("À ${p.heurePrisePrevue}"),
      trailing: done 
          ? const Text("Pris", style: TextStyle(color: Colors.green)) 
          : ElevatedButton(
              onPressed: () async {
                bool ok = await ApiService.validerPriseMedicament(p.id);
                if (ok) _chargerDonnees();
              },
              child: const Text("Valider"),
            ),
    );
  }

  Future<void> _ouvrirFichier(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Aucun dossier médical trouvé."));
  }
}