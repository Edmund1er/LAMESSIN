import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/traitement_model.dart';
import '../../MODELS_/consultation_model.dart';
import '../../THEME_/app_theme.dart';

class SuiviTraitementsPage extends StatefulWidget {
  const SuiviTraitementsPage({super.key});
  @override
  State<SuiviTraitementsPage> createState() => _SuiviTraitementsPageState();
}

class _SuiviTraitementsPageState extends State<SuiviTraitementsPage> {
  List<dynamic> _donnees = [];
  bool _chargement = true;

  @override
  void initState() { super.initState(); _chargerDonnees(); }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    final traitements   = await ApiService.getTraitements();
    final consultations = await ApiService.getMesConsultations();
    if (mounted) setState(() {
      _donnees = [...consultations, ...traitements];
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar("Mon dossier médical"),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              color: AppColors.primary,
              child: _donnees.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _donnees.length,
                      itemBuilder: (_, index) {
                        final item = _donnees[index];
                        if (item is Consultation) return _buildConsultationCard(item);
                        if (item is Traitement)   return _buildTraitementCard(item);
                        return const SizedBox.shrink();
                      },
                    ),
            ),
    );
  }

  Widget _buildConsultationCard(Consultation s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primary, size: 20),
          ),
          title: Text(s.diagnostic, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          subtitle: Text("Le ${s.dateConsultation}",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Notes du médecin :",
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(s.notesMedecin ?? "Aucune note.",
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
    final int total  = prises.length;
    final int faites = prises.where((p) => p.priseEffectuee).length;
    final double progress = total > 0 ? faites / total : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.successLight,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.medication_rounded,
                color: Color(0xFF22863A), size: 20),
          ),
          title: Text(t.nomDuTraitement, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Fin le ${t.dateFin}",
                style: const TextStyle(fontSize: 12, color: Color(0xFF22863A))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress, backgroundColor: AppColors.background,
                color: AppColors.primary, minHeight: 5),
            ),
            const SizedBox(height: 2),
            Text("$faites/$total prises effectuées",
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
          bool ok = await ApiService.validerPriseMedicament(p.id);
          if (ok) _chargerDonnees();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done ? AppColors.successLight : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done ? const Color(0xFFC0DDBA) : AppColors.borderLight)),
          child: Row(children: [
            Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: done ? const Color(0xFF22863A) : AppColors.textSecondary,
                size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text("À ${p.heurePrisePrevue}",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: done ? const Color(0xFF22863A) : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null))),
            if (!done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text("Valider", style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700)),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.primary)),
      const SizedBox(height: 16),
      const Text("Aucune donnée médicale",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    ]));
  }
}
