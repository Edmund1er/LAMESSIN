import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/pharmacy_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_produits_page.dart';

class PharmacienProfilPage extends StatefulWidget {
  const PharmacienProfilPage({super.key});
  @override
  State<PharmacienProfilPage> createState() => _PharmacienProfilPageState();
}

class _PharmacienProfilPageState extends State<PharmacienProfilPage> {
  dynamic _profil;
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
      if (mounted) {
        setState(() {
          _profil = profil;
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

    String nom = "", prenom = "", tel = "", email = "", nomPharmacie = "";

    if (_profil is Pharmacien) {
      final p = _profil as Pharmacien;
      nom = p.compteUtilisateur.lastName;
      prenom = p.compteUtilisateur.firstName;
      tel = p.compteUtilisateur.numeroTelephone ?? "Non renseigné";
      email = p.compteUtilisateur.email ?? "Non renseigné";
      nomPharmacie = p.nomPharmacie ?? "";
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
                          Icons.local_pharmacy_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "$prenom $nom",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                          nomPharmacie.isNotEmpty ? nomPharmacie : "Pharmacien",
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
                            Icons.local_pharmacy_rounded,
                            "Pharmacie",
                            nomPharmacie.isNotEmpty
                                ? nomPharmacie
                                : "Non renseigné",
                            true,
                          ),
                        ],
                      ),
                    ),
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
                  '/dashboard_pharmacien',
                ),
              ),
              _navItem(
                Icons.medication_rounded,
                "Produits",
                1,
                index,
                () => Navigator.pushReplacementNamed(context, '/produits'),
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
