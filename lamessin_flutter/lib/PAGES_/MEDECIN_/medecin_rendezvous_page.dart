import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/rendezvous_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_profil_page.dart';

class MedecinRendezVousPage extends StatefulWidget {
  const MedecinRendezVousPage({super.key});
  @override
  State<MedecinRendezVousPage> createState() => _MedecinRendezVousPageState();
}

class _MedecinRendezVousPageState extends State<MedecinRendezVousPage> {
  List<RendezVous> _tousRdv = [];
  bool _chargement = true;
  String _filtre = "Tous";

  final List<String> _filtres = ["Tous", "En attente", "Confirmés", "Annulés"];

  @override
  void initState() {
    super.initState();
    _chargerRdv();
  }

  Future<void> _chargerRdv() async {
    setState(() => _chargement = true);
    try {
      final data = await DoctorService.getMesRendezVousMedecin();
      if (mounted)
        setState(() {
          _tousRdv = data;
          _chargement = false;
        });
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _confirmerRdv(int id) async {
    final ok = await DoctorService.updateRendezVousStatut(id, 'confirme');
    if (ok) {
      AppWidgets.showSnack(
        context,
        "Rendez-vous confirmé ✓",
        color: AppColors.success,
      );
      _chargerRdv();
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de la confirmation",
        color: AppColors.danger,
      );
    }
  }

  Future<void> _refuserRdv(int id) async {
    final ok = await DoctorService.updateRendezVousStatut(id, 'annule');
    if (ok) {
      AppWidgets.showSnack(
        context,
        "Rendez-vous refusé",
        color: AppColors.warning,
      );
      _chargerRdv();
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors du refus",
        color: AppColors.danger,
      );
    }
  }

  List<RendezVous> get _rdvFiltres {
    if (_filtre == "Tous") return _tousRdv;
    if (_filtre == "En attente")
      return _tousRdv.where((r) => r.statutActuelRdv == 'en_attente').toList();
    if (_filtre == "Confirmés")
      return _tousRdv
          .where(
            (r) =>
                r.statutActuelRdv == 'confirme' ||
                r.statutActuelRdv == 'validé',
          )
          .toList();
    if (_filtre == "Annulés")
      return _tousRdv.where((r) => r.statutActuelRdv == 'annulé').toList();
    return _tousRdv;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Mes rendez-vous",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _chargerRdv,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filtres.map((f) {
                  bool sel = _filtre == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filtre = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: _chargement
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _chargerRdv,
                    color: AppColors.primary,
                    child: _rdvFiltres.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _rdvFiltres.length,
                            itemBuilder: (_, i) =>
                                _buildRdvCard(_rdvFiltres[i]),
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  Widget _buildRdvCard(RendezVous rdv) {
    final nomPatient =
        rdv.patientDemandeur?.compteUtilisateur.firstName ?? "Patient";
    final prenomPatient =
        rdv.patientDemandeur?.compteUtilisateur.lastName ?? "";
    final enAttente = rdv.statutActuelRdv == 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enAttente
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.borderLight,
          width: enAttente ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Infos patient
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$nomPatient $prenomPatient",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        rdv.motifConsultation ?? "Consultation générale",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppWidgets.statusBadge(rdv.statutActuelRdv),
              ],
            ),

            const SizedBox(height: 12),

            // Date/Heure
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rdv.dateRdv,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rdv.heureRdv,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Boutons (seulement si en attente)
            if (enAttente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmerDialog(rdv.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF22863A),
                        side: const BorderSide(
                          color: Color(0xFF22863A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text(
                        "Confirmer",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _refusDialog(rdv.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        "Refuser",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmerDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer ce rendez-vous ?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text("Le patient sera notifié de la confirmation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22863A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmerRdv(id);
            },
            child: const Text(
              "Confirmer",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refusDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Refuser ce rendez-vous ?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _refuserRdv(id);
            },
            child: const Text(
              "Refuser",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun rendez-vous",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Filtre actuel : $_filtre",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.dashboard_rounded,
                "Accueil",
                0,
                index,
                () => Navigator.pushReplacementNamed(
                  context,
                  '/dashboard_medecin',
                ),
              ),
              _navItem(
                Icons.calendar_month_rounded,
                "Rendez-vous",
                1,
                index,
                () {},
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                2,
                index,
                () =>
                    Navigator.pushReplacementNamed(context, '/medecin_profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int idx,
    int current,
    VoidCallback onTap,
  ) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: actif ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: actif ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
