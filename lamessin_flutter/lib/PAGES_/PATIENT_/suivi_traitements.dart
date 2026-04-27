import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/patient_service.dart';
import '../../MODELS_/traitement_model.dart';
import '../../MODELS_/consultation_model.dart';
import '../../THEME_/app_theme.dart';
import 'mon_profil.dart';

class SuiviTraitementsPage extends StatefulWidget {
  const SuiviTraitementsPage({super.key});

  @override
  State<SuiviTraitementsPage> createState() => _SuiviTraitementsPageState();
}

class _SuiviTraitementsPageState extends State<SuiviTraitementsPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  List<dynamic> _donnees = [];
  bool _chargement = true;
  int _selectedIndex = 1;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    final traitements = await PatientService.getTraitements();
    final consultations = await PatientService.getMesConsultations();
    if (mounted) {
      setState(() {
        _donnees = [...consultations, ...traitements];
        _chargement = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/page_utilisateur'),
        ),
        title: const Text("Mon dossier medical", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                : RefreshIndicator(
                    onRefresh: _chargerDonnees,
                    color: _brandColor,
                    child: _donnees.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _donnees.length,
                            itemBuilder: (_, index) {
                              final item = _donnees[index];
                              if (item is Consultation) return _buildConsultationCard(item);
                              if (item is Traitement) return _buildTraitementCard(item);
                              return const SizedBox.shrink();
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildConsultationCard(Consultation s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.description_rounded, color: _brandColor, size: 20),
          ),
          title: Text(s.diagnostic, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
          subtitle: Text("Le ${s.dateConsultation}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Notes du medecin :", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(s.notesMedecin ?? "Aucune note.", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (s.documentJoint != null && s.documentJoint!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      String fullUrl = '${ApiService.mediaBaseUrl}${s.documentJoint}';
                      _ouvrirFichier(fullUrl);
                    },
                    icon: const Icon(Icons.file_present_rounded, size: 18),
                    label: const Text("Voir le document joint"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor.withOpacity(0.15),
                      foregroundColor: _brandColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitementCard(Traitement t) {
    List<PriseMedicament> prises = t.prises;
    final int total = prises.length;
    final int faites = prises.where((p) => p.priseEffectuee).length;
    final double progress = total > 0 ? faites / total : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.medication_rounded, color: Color(0xFF4CAF50), size: 20),
          ),
          title: Text(t.nomDuTraitement, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Fin le ${t.dateFin}", style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[100], color: _brandColor, minHeight: 5),
            ),
            const SizedBox(height: 2),
            Text("$faites/$total prises effectuees", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: prises.map(_buildPrise).toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrise(PriseMedicament p) {
    bool done = p.priseEffectuee;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: done ? null : () async {
          bool ok = await PatientService.validerPriseMedicament(p.id);
          if (ok) _chargerDonnees();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done ? AppColors.successLight : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: done ? const Color(0xFFC0DDBA) : Colors.grey[200]!),
          ),
          child: Row(children: [
            Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: done ? const Color(0xFF4CAF50) : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text("A ${p.heurePrisePrevue}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: done ? const Color(0xFF4CAF50) : Colors.black87, decoration: done ? TextDecoration.lineThrough : null))),
            if (!done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(8)),
                child: const Text("Valider", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _ouvrirFichier(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Icon(Icons.folder_open_rounded, size: 36, color: _brandColor)),
        const SizedBox(height: 16),
        const Text("Aucune donnee medicale", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, currentIndex),
              _navItem(Icons.medication_rounded, "Traitements", 1, currentIndex),
              _navItem(Icons.calendar_month_rounded, "RDV", 2, currentIndex),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, currentIndex),
              _navItem(Icons.person_rounded, "Profil", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: () => _onItemTapped(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}