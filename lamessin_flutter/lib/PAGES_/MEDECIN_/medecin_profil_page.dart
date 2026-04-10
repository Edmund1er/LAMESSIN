import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';

class MedecinProfilPage extends StatefulWidget {
  const MedecinProfilPage({super.key});
  @override
  State<MedecinProfilPage> createState() => _MedecinProfilPageState();
}

class _MedecinProfilPageState extends State<MedecinProfilPage> {
  dynamic _user;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final data = await DoctorService.getProfil();
    if (mounted) setState(() { _user = data; _chargement = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    String nom = "", prenom = "", tel = "", email = "", specialite = "";
    if (_user is Medecin) {
      final m = _user as Medecin;
      nom       = m.compteUtilisateur.lastName;
      prenom    = m.compteUtilisateur.firstName;
      tel       = m.compteUtilisateur.numeroTelephone ?? "Non renseigné";
      email     = m.compteUtilisateur.email ?? "Non renseigné";
      specialite = m.specialiteMedicale;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _chargerProfil,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── HEADER ──
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primary,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Container(
                        width: 84, height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text("Dr $prenom $nom",
                          style: const TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      if (specialite.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(specialite,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── CONTENU ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  _sectionLabel("Informations de contact"),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight)),
                    child: Column(children: [
                      _infoRow(Icons.phone_rounded, "Téléphone", tel, false),
                      _infoRow(Icons.email_rounded, "Email", email, false),
                      _infoRow(Icons.medical_services_rounded,
                          "Spécialité", specialite, true),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel("Mes disponibilités"),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight)),
                    child: Column(children: [
                      _disponibiliteRow("Lundi", "08:00 – 17:00", true),
                      _disponibiliteRow("Mardi", "08:00 – 17:00", true),
                      _disponibiliteRow("Mercredi", "08:00 – 12:00", true),
                      _disponibiliteRow("Jeudi", "08:00 – 17:00", true),
                      _disponibiliteRow("Vendredi", "08:00 – 15:00", true),
                      _disponibiliteRow("Samedi", "Indisponible", false),
                      _disponibiliteRow("Dimanche", "Indisponible", false),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  AppWidgets.primaryButton(
                    label: "Modifier mon profil",
                    icon: Icons.edit_rounded,
                    onPressed: () {
                      AppWidgets.showSnack(context,
                          "Modification disponible prochainement",
                          color: AppColors.primary);
                    },
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ApiService.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (r) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                            color: AppColors.dangerLight, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded,
                          size: 18),
                      label: const Text("Se déconnecter",
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
  );

  Widget _infoRow(IconData icon, String label, String value, bool isLast) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          ])),
        ]),
      ),
      if (!isLast) const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.borderLight),
      ),
    ]);
  }

  Widget _disponibiliteRow(String jour, String horaire, bool dispo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: dispo ? const Color(0xFF22863A) : AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(jour,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: dispo
                    ? AppColors.textPrimary
                    : AppColors.textSecondary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: dispo ? AppColors.successLight : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(horaire,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: dispo
                      ? const Color(0xFF22863A)
                      : AppColors.textSecondary)),
        ),
      ]),
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
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index,
                  () => Navigator.pushReplacementNamed(context, '/dashboard_medecin')),
              _navItem(Icons.calendar_month_rounded, "Rendez-vous", 1, index,
                  () => Navigator.pushReplacementNamed(context, '/medecin_rendezvous')),
              _navItem(Icons.account_circle_rounded, "Profil", 2, index, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current,
      VoidCallback onTap) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            color: actif ? AppColors.primary : AppColors.textSecondary,
            size: 24),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: actif ? AppColors.primary : AppColors.textSecondary)),
      ]),
    );
  }
}