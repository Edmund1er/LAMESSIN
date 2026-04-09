import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/notification_model.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_profil_page.dart';

class MedecinDashboardPage extends StatefulWidget {
  const MedecinDashboardPage({super.key});
  @override
  State<MedecinDashboardPage> createState() => _MedecinDashboardPageState();
}

class _MedecinDashboardPageState extends State<MedecinDashboardPage> {
  String _nomMedecin = "Docteur";
  String _specialite = "";
  List<RendezVous> _rdv = [];
  List<NotificationModel> _notifications = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final profil = await ApiService.getProfil();
      final notifs = await DoctorService.getNotifications();
      final rdvData = await DoctorService.getMesRendezVousMedecin();

      if (mounted) {
        setState(() {
          if (profil is Medecin) {
            _nomMedecin =
                "${profil.compteUtilisateur.firstName} ${profil.compteUtilisateur.lastName}";
            _specialite = profil.specialiteMedicale;
          }
          _rdv = rdvData;
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // Stats calculées
  int get _rdvAujourdhui {
    final today = DateTime.now();
    return _rdv.where((r) {
      final d = DateTime.tryParse(r.dateRdv);
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
  }

  int get _rdvEnAttente =>
      _rdv.where((r) => r.statutActuelRdv == 'en_attente').length;

  List<RendezVous> get _prochains =>
      _rdv.where((r) => r.statutActuelRdv != 'annulé').take(5).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStats(),
                          const SizedBox(height: 24),
                          _sectionTitle("Prochains rendez-vous"),
                          const SizedBox(height: 12),
                          _prochains.isEmpty
                              ? _buildEmpty(
                                  "Aucun rendez-vous à venir",
                                  Icons.event_busy_rounded,
                                )
                              : Column(
                                  children: _prochains
                                      .map((r) => _buildRdvCard(r))
                                      .toList(),
                                ),
                          const SizedBox(height: 24),
                          _sectionTitle("Notifications récentes"),
                          const SizedBox(height: 12),
                          _notifications.isEmpty
                              ? _buildEmpty(
                                  "Aucune notification",
                                  Icons.notifications_off_outlined,
                                )
                              : Column(
                                  children: _notifications
                                      .take(3)
                                      .map((n) => _buildNotifCard(n))
                                      .toList(),
                                ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () async {
            await ApiService.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (r) => false,
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.primary,
          padding: const EdgeInsets.only(left: 22, bottom: 24, top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bonjour,",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Dr $_nomMedecin 👨‍⚕️",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_specialite.isNotEmpty)
                Text(
                  _specialite,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Aujourd'hui",
            _rdvAujourdhui,
            Icons.today_rounded,
            AppColors.primary,
            AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "En attente",
            _rdvEnAttente,
            Icons.hourglass_empty_rounded,
            const Color(0xFFE65100),
            AppColors.warningLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Total",
            _rdv.length,
            Icons.calendar_month_rounded,
            const Color(0xFF22863A),
            AppColors.successLight,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRdvCard(RendezVous rdv) {
    final nomPatient =
        rdv.patientDemandeur?.compteUtilisateur.firstName ?? "Patient";
    final prenomPatient =
        rdv.patientDemandeur?.compteUtilisateur.lastName ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 22,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "${rdv.dateRdv} · ${rdv.heureRdv}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppWidgets.statusBadge(rdv.statutActuelRdv),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              n.message ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildEmpty(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
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
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index, () {}),
              _navItem(
                Icons.calendar_month_rounded,
                "Rendez-vous",
                1,
                index,
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedecinRendezVousPage(),
                  ),
                ),
              ),
              _navItem(
                Icons.account_circle_rounded,
                "Profil",
                2,
                index,
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MedecinProfilPage()),
                ),
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
