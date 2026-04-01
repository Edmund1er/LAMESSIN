import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart'; // CORRECTION
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';

class MesRendezVousPage extends StatefulWidget {
  const MesRendezVousPage({super.key});
  @override
  State<MesRendezVousPage> createState() => _MesRendezVousPageState();
}

class _MesRendezVousPageState extends State<MesRendezVousPage> {
  List<RendezVous> _tousMesRDV = [];
  bool _chargement = true;

  @override
  void initState() { super.initState(); _recupererRendezVous(); }

  Future<void> _recupererRendezVous() async {
    setState(() => _chargement = true);
    try {
      final List<RendezVous> data = await PatientService.getMesRendezVous(); // CORRECTION
      setState(() { _tousMesRDV = data; _chargement = false; });
    } catch (e) {
      setState(() => _chargement = false);
      _msg("Erreur de récupération", AppColors.danger);
    }
  }

  Future<void> _annulerRDV(int id) async {
    bool succes = await PatientService.annulerRendezVous(id); // CORRECTION
    if (succes) { _msg("Rendez-vous annulé", AppColors.warning); _recupererRendezVous(); }
    else _msg("Erreur lors de l'annulation", AppColors.danger);
  }

  List<RendezVous> get _rdvFuturs {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime d = DateTime.parse(rdv.dateRdv);
      return d.isAfter(now.subtract(const Duration(days: 1))) && rdv.statutActuelRdv != 'annulé';
    }).toList();
  }

  List<RendezVous> get _rdvPassesOuAnnules {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime d = DateTime.parse(rdv.dateRdv);
      return d.isBefore(now) || rdv.statutActuelRdv == 'annulé';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const MenuNavigation(),
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: const Text("Mes rendez-vous",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.borderLight,
            tabs: const [
              Tab(text: "À venir"),
              Tab(text: "Historique"),
            ],
          ),
        ),
        body: _chargement
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(children: [
                _buildListe(_rdvFuturs, estAncien: false),
                _buildListe(_rdvPassesOuAnnules, estAncien: true),
              ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/rendez_vous_page'),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          label: const Text("Prendre rendez-vous",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildListe(List<RendezVous> liste, {required bool estAncien}) {
    if (liste.isEmpty) return _buildEmpty(estAncien);
    return RefreshIndicator(
      onRefresh: _recupererRendezVous,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100),
        itemCount: liste.length,
        itemBuilder: (_, i) => _buildCard(liste[i], grise: estAncien),
      ),
    );
  }

  Widget _buildCard(RendezVous rdv, {bool grise = false}) {
    final String nomMedecin = rdv.medecinConcerne?.compteUtilisateur.lastName ?? "Médecin";
    final String specialite = rdv.medecinConcerne?.specialiteMedicale ?? "Généraliste";
    final bool estAVenir = !grise && rdv.statutActuelRdv != 'annulé';

    return Opacity(
      opacity: grise ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: estAVenir ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: estAVenir ? null
              : Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: estAVenir
                      ? Colors.white.withOpacity(0.2) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded,
                    color: estAVenir ? Colors.white : AppColors.primary,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr $nomMedecin",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                          color: estAVenir ? Colors.white : AppColors.textPrimary)),
                  Text(specialite, style: TextStyle(fontSize: 12,
                      color: estAVenir
                          ? Colors.white.withOpacity(0.7) : AppColors.textSecondary)),
                ],
              )),
              AppWidgets.statusBadge(rdv.statutActuelRdv),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: estAVenir
                    ? Colors.white.withOpacity(0.12) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 13,
                    color: estAVenir
                        ? Colors.white.withOpacity(0.7) : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(rdv.dateRdv, style: TextStyle(fontSize: 12,
                    color: estAVenir
                        ? Colors.white.withOpacity(0.85) : AppColors.textSecondary)),
                const SizedBox(width: 14),
                Icon(Icons.access_time_rounded, size: 13,
                    color: estAVenir
                        ? Colors.white.withOpacity(0.7) : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(rdv.heureRdv, style: TextStyle(fontSize: 12,
                    color: estAVenir
                        ? Colors.white.withOpacity(0.85) : AppColors.textSecondary)),
              ]),
            ),
            if (estAVenir) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmerAnnulation(rdv.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text("Annuler",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text("Check in",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool estAncien) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(estAncien ? Icons.folder_open_rounded : Icons.event_busy_rounded,
              size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(estAncien ? "Historique vide" : "Aucun rendez-vous à venir",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(estAncien ? "Vos anciens RDV apparaîtront ici"
            : "Prenez un RDV dès maintenant",
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }

  void _confirmerAnnulation(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Annuler le rendez-vous ?",
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text("Retour",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () { Navigator.pop(ctx); _annulerRDV(id); },
            child: const Text("Confirmer",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _msg(String msg, Color c) {
    AppWidgets.showSnack(context, msg, color: c);
  }
}