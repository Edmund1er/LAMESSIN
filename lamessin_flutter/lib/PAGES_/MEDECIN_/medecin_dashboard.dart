import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/notification_model.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_profil_page.dart';
import 'medecin_notifications_page.dart';

class MedecinDashboardPage extends StatefulWidget {
  const MedecinDashboardPage({super.key});

  @override
  State<MedecinDashboardPage> createState() => _MedecinDashboardPageState();
}

class _MedecinDashboardPageState extends State<MedecinDashboardPage> {
  String _nomMedecin = "Docteur";
  String _prenomMedecin = "";
  String _specialite = "";
  Map<String, dynamic>? _dashboardData;
  List<RendezVous> _rdv = [];
  List<NotificationModel> _notifications = [];
  bool _chargement = true;

  final String _imageFond = "assets/images/fond_medecin_dashboard.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final profil = await DoctorService.getProfil();
      final dashboard = await DoctorService.getDashboard();
      final rdvData = await DoctorService.getMesRendezVousMedecin();
      final notifs = await ApiService.getNotifications();

      if (mounted) {
        setState(() {
          if (profil is Medecin) {
            _prenomMedecin = profil.compteUtilisateur.firstName;
            _nomMedecin = profil.compteUtilisateur.lastName;
            _specialite = profil.specialiteMedicale;
          }
          _dashboardData = dashboard;
          _rdv = rdvData;
          _notifications = notifs;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  int get _rdvAujourdhui => _dashboardData?['rdv_aujourdhui'] ?? 0;
  int get _rdvEnAttente =>
      _rdv.where((r) => r.statutActuelRdv == 'en_attente').length;
  int get _consultationsTotal => _dashboardData?['consultations_total'] ?? 0;

  List<RendezVous> get _prochains =>
      _rdv.where((r) => r.statutActuelRdv != 'annule').take(5).toList();

  void _onItemTapped(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinRendezVousPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinProfilPage()),
      );
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedecinNotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00ACC1)),
            )
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              color: const Color(0xFF00ACC1),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _imageFond,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[100]),
                    ),
                  ),
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 180,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            onPressed: _openNotifications,
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => _confirmerDeconnexion(context),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF00ACC1).withOpacity(0.85),
                                  const Color(0xFF00ACC1).withOpacity(0.7),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 50,
                              bottom: 16,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bonjour,",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Dr $_prenomMedecin $_nomMedecin",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_specialite.isNotEmpty)
                                  Text(
                                    _specialite,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white.withOpacity(0.92),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        "Aujourd'hui",
                                        _rdvAujourdhui,
                                        Icons.today_rounded,
                                        const Color(0xFF00ACC1),
                                        Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        "En attente",
                                        _rdvEnAttente,
                                        Icons.hourglass_empty_rounded,
                                        const Color(0xFFF57C00),
                                        Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        "Consultations",
                                        _consultationsTotal,
                                        Icons.medical_services_rounded,
                                        const Color(0xFF4CAF50),
                                        Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Prochains rendez-vous",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _prochains.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(40),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.event_busy_rounded,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Aucun rendez-vous a venir",
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: _prochains
                                            .map((r) => _buildRdvCard(r))
                                            .toList(),
                                      ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Notifications recentes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _openNotifications,
                                      child: const Text(
                                        "Voir tout",
                                        style: TextStyle(
                                          color: Color(0xFF00ACC1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _notifications.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(40),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.notifications_off_outlined,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Aucune notification",
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: _notifications
                                            .take(3)
                                            .map((n) => _buildNotifCard(n))
                                            .toList(),
                                      ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0, 0),
                _buildNavItem(
                  Icons.calendar_today_rounded,
                  "Rendez-vous",
                  1,
                  0,
                ),
                _buildNavItem(Icons.history_rounded, "Consultations", 2, 0),
                _buildNavItem(Icons.person_rounded, "Profil", 3, 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF00ACC1),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${rdv.dateRdv} à ${rdv.heureRdv}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(rdv.statutActuelRdv).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(rdv.statutActuelRdv),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(rdv.statutActuelRdv),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_rounded,
            color: const Color(0xFF00ACC1),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              n.message ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return const Color(0xFFF57C00);
      case 'confirme':
        return const Color(0xFF00ACC1);
      case 'termine':
        return const Color(0xFF4CAF50);
      case 'annule':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente':
        return "En attente";
      case 'confirme':
        return "Confirme";
      case 'termine':
        return "Termine";
      case 'annule':
        return "Annule";
      default:
        return statut;
    }
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Deconnexion",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text("Voulez-vous vraiment vous deconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Se deconnecter"),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00ACC1) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF00ACC1) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
