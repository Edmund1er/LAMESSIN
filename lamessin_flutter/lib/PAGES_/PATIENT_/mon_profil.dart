import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';
import 'edit_profil_page.dart';

class ProfilPatientPage extends StatefulWidget {
  const ProfilPatientPage({super.key});
  @override
  State<ProfilPatientPage> createState() => _ProfilPatientPageState();
}

class _ProfilPatientPageState extends State<ProfilPatientPage> {
  dynamic _user;
  bool _chargement = true;

  @override
  void initState() { super.initState(); _chargerProfil(); }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _chargerProfil(); }

  Future<void> _chargerProfil() async {
    final data = await ApiService.getProfil();
    if (mounted) setState(() { _user = data; _chargement = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00C2CB))));
    if (_user == null) return const Scaffold(
        body: Center(child: Text("Erreur de chargement")));

    String nom = "", prenom = "", tel = "", email = "", infoSante = "";

    if (_user is Patient) {
      final p = _user as Patient;
      nom    = p.compteUtilisateur.lastName;
      prenom = p.compteUtilisateur.firstName;
      tel    = p.compteUtilisateur.numeroTelephone ?? "Non renseigné";
      final rawEmail = p.compteUtilisateur.email ?? "";
      email  = rawEmail.isEmpty ? "Non renseigné" : rawEmail;
      infoSante = p.groupeSanguin ?? "Inconnu";
    } else if (_user is Utilisateur) {
      final u = _user as Utilisateur;
      nom    = u.lastName;
      prenom = u.firstName;
      tel    = u.numeroTelephone;
      email  = u.email.isEmpty ? "Non renseigné" : u.email;
      infoSante = "Compte Utilisateur";
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_patient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _chargerProfil,
          color: const Color(0xFF00C2CB),
          child: CustomScrollView(
            slivers: [
              // ── HEADER ──
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: const Color(0xFF00C2CB),
                iconTheme: const IconThemeData(color: Colors.white),
                // actions supprimé - plus d'icône settings
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF00C2CB),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        Container(
                          width: 78, height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text("$prenom $nom", style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(tel, style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Patient", style: TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── CONTENU TRANSPARENT ──
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white.withOpacity(0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      // Infos personnelles
                      _sectionLabel("Informations personnelles"),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight)),
                        child: Column(children: [
                          _infoRow(Icons.phone_rounded, "Téléphone", tel, false),
                          _infoRow(Icons.email_rounded, "Email", email, true),
                        ]),
                      ),
                      const SizedBox(height: 18),

                      // Dossier médical
                      _sectionLabel("Dossier médical"),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(11)),
                              child: const Icon(Icons.water_drop_rounded,
                                  color: AppColors.danger, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Groupe sanguin", style: TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary)),
                                Text("Non modifiable", style: TextStyle(
                                    fontSize: 11, color: AppColors.textHint)),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(infoSante, style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900,
                                  color: AppColors.danger)),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 28),

                      AppWidgets.primaryButton(
                        label: "Modifier mes informations",
                        icon: Icons.edit_rounded,
                        onPressed: () {
                          if (_user is Patient) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => EditProfilPage(patient: _user),
                            )).then((_) => _chargerProfil());
                          } else {
                            AppWidgets.showSnack(context,
                                "Modification disponible pour le profil patient complet");
                          }
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
                            side: const BorderSide(color: AppColors.dangerLight, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                          label: const Text("Se déconnecter",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: const TextStyle(fontSize: 15,
        fontWeight: FontWeight.w800, color: Color(0xFF00C2CB))),
  );

  Widget _infoRow(IconData icon, String label, String value, bool isLast) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFF00C2CB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF00C2CB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ])),
        ]),
      ),
      if (!isLast) const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.borderLight),
      ),
    ]);
  }
}