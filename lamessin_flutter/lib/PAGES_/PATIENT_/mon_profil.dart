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
  int _selectedIndex = 4;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final data = await ApiService.getProfil();
    if (mounted) setState(() {
      _user = data;
      _chargement = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1))),
      );
    }
    if (_user == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text("Erreur de chargement")),
      );
    }

    String nom = "", prenom = "", tel = "", email = "", infoSante = "";

    if (_user is Patient) {
      final p = _user as Patient;
      nom = p.compteUtilisateur.lastName;
      prenom = p.compteUtilisateur.firstName;
      tel = p.compteUtilisateur.numeroTelephone ?? "Non renseigne";
      final rawEmail = p.compteUtilisateur.email ?? "";
      email = rawEmail.isEmpty ? "Non renseigne" : rawEmail;
      infoSante = p.groupeSanguin ?? "Inconnu";
    } else if (_user is Utilisateur) {
      final u = _user as Utilisateur;
      nom = u.lastName;
      prenom = u.firstName;
      tel = u.numeroTelephone;
      email = u.email.isEmpty ? "Non renseigne" : u.email;
      infoSante = "Compte Utilisateur";
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/page_utilisateur'),
        ),
        title: const Text("Mon profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          RefreshIndicator(
            onRefresh: _chargerProfil,
            color: const Color(0xFF00ACC1),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white.withOpacity(0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: const Color(0xFFE0F7FA), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00ACC1), width: 3)),
                            child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 50),
                          ),
                          const SizedBox(height: 16),
                          Text("$prenom $nom", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(20)),
                            child: const Text("Patient", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF00ACC1))),
                          ),
                          const SizedBox(height: 30),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Informations personnelles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                            child: Column(
                              children: [
                                _infoRow(Icons.phone_rounded, "Telephone", tel, false),
                                _infoRow(Icons.email_rounded, "Email", email, true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Dossier medical", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.water_drop_rounded, color: AppColors.danger, size: 20)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Groupe sanguin", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text("Non modifiable", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)),
                                    child: Text(infoSante, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_user is Patient) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilPage(patient: _user))).then((_) => _chargerProfil());
                                } else {
                                  AppWidgets.showSnack(context, "Modification disponible pour le profil patient complet");
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text("Modifier mes informations", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ApiService.logout();
                                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                              icon: const Icon(Icons.logout_rounded, size: 20),
                              label: const Text("Se deconnecter", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF00ACC1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 68, color: Colors.grey),
      ],
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
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, currentIndex),
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
          Icon(icon, color: actif ? const Color(0xFF00ACC1) : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? const Color(0xFF00ACC1) : Colors.grey)),
        ],
      ),
    );
  }
}