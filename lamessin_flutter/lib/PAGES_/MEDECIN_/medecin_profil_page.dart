import 'package:flutter/material.dart';
import 'package:lamessin_flutter/SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/plage_horaire_model.dart';

class MedecinProfilPage extends StatefulWidget {
  const MedecinProfilPage({super.key});
  @override
  State<MedecinProfilPage> createState() => _MedecinProfilPageState();
}

class _MedecinProfilPageState extends State<MedecinProfilPage> {
  dynamic _user;
  List<PlageHoraire> _disponibilites = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final results = await Future.wait([
        DoctorService.getProfil(),
        DoctorService.getPlagesHoraires(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0];
          _disponibilites = results[1] as List<PlageHoraire>;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    String nom = "", prenom = "", tel = "", email = "", specialite = "";
    if (_user is Medecin) {
      final m = _user as Medecin;
      nom = m.compteUtilisateur.lastName;
      prenom = m.compteUtilisateur.firstName;
      tel = m.compteUtilisateur.numeroTelephone ?? "Non renseigné";
      email = m.compteUtilisateur.email ?? "Non renseigné";
      specialite = m.specialiteMedicale;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _chargerDonnees,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
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
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Dr $prenom $nom",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (specialite.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            specialite,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _sectionLabel("Informations de contact"),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.phone_rounded,
                            "Téléphone",
                            tel,
                            false,
                          ),
                          _infoRow(Icons.email_rounded, "Email", email, false),
                          _infoRow(
                            Icons.medical_services_rounded,
                            "Spécialité",
                            specialite,
                            true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Section disponibilités avec bouton "Gérer"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel("Mes disponibilités"),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/GererPlages');
                            // Recharge les données après retour
                            _chargerDonnees();
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("Gérer"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDisponibilites(),
                    const SizedBox(height: 24),

                    AppWidgets.primaryButton(
                      label: "Modifier mon profil",
                      icon: Icons.edit_rounded,
                      onPressed: () {
                        AppWidgets.showSnack(
                          context,
                          "Modification disponible prochainement",
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(
                            color: AppColors.dangerLight,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          "Se déconnecter",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  Widget _buildDisponibilites() {
    if (_disponibilites.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              "Aucune disponibilité enregistrée",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/GererPlages');
                _chargerDonnees();
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text("Ajouter une plage horaire"),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    // Afficher seulement les 5 premières plages
    final plagesAAfficher = _disponibilites.take(5).toList();
    final bool hasMore = _disponibilites.length > 5;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          ...plagesAAfficher.asMap().entries.map((entry) {
            final dispo = entry.value;
            final isLast = entry.key == plagesAAfficher.length - 1 && !hasMore;

            final bool hasHoraire =
                dispo.heureDebut.isNotEmpty && dispo.heureFin.isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasHoraire
                              ? const Color(0xFF22863A)
                              : AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dispo.date.isNotEmpty
                              ? _formatDate(dispo.date)
                              : 'Date non définie',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasHoraire
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: hasHoraire
                              ? AppColors.successLight
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasHoraire
                              ? '${dispo.heureDebut} - ${dispo.heureFin}'
                              : "Indisponible",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasHoraire
                                ? const Color(0xFF22863A)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),
              ],
            );
          }),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/GererPlages');
                  _chargerDonnees();
                },
                child: Text(
                  "Voir les ${_disponibilites.length} disponibilités",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];
      final days = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];
      return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
      ],
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
                () => Navigator.pushReplacementNamed(
                  context,
                  '/medecin_rendezvous',
                ),
              ),
              _navItem(Icons.account_circle_rounded, "Profil", 2, index, () {}),
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
