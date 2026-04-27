import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/plage_horaire_model.dart';
import 'GererPlagesHorairesPage.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';

class MedecinProfilPage extends StatefulWidget {
  const MedecinProfilPage({super.key});

  @override
  State<MedecinProfilPage> createState() => _MedecinProfilPageState();
}

class _MedecinProfilPageState extends State<MedecinProfilPage> {
  Medecin? _user;
  List<PlageHoraire> _disponibilites = [];
  bool _chargement = true;

  final String _imageFond = "assets/images/fond_medecin_profil.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final profil = await DoctorService.getProfil();
      final plages = await DoctorService.getPlagesHoraires();
      if (mounted) {
        setState(() {
          if (profil is Medecin) {
            _user = profil;
          }
          _disponibilites = plages;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateStr);
      const months = ['janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin', 'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'];
      const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinRendezVousPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()));
    } else if (index == 3) {
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
        body: Center(child: Text("Erreur de chargement du profil")),
      );
    }
    final nom = _user!.compteUtilisateur.lastName;
    final prenom = _user!.compteUtilisateur.firstName;
    final tel = _user!.compteUtilisateur.numeroTelephone ?? "Non renseigne";
    final email = _user!.compteUtilisateur.email ?? "Non renseigne";
    final specialite = _user!.specialiteMedicale;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage())),
        ),
        title: const Text("Mon profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerDonnees),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          RefreshIndicator(
            onRefresh: _chargerDonnees,
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
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00ACC1), width: 3),
                            ),
                            child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 50),
                          ),
                          const SizedBox(height: 12),
                          Text("Dr $prenom $nom", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(specialite, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF00ACC1))),
                          ),
                          const SizedBox(height: 30),
                          const Text("Informations de contact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                _infoRow(Icons.phone_rounded, "Telephone", tel, false),
                                _infoRow(Icons.email_rounded, "Email", email, false),
                                _infoRow(Icons.medical_services_rounded, "Specialite", specialite, true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Mes disponibilites", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const GererPlagesHorairesPage()));
                                  _chargerDonnees();
                                },
                                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF00ACC1)),
                                label: const Text("Gerer", style: TextStyle(color: Color(0xFF00ACC1))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDisponibilites(),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => AppWidgets.showSnack(context, "Modification disponible prochainement", color: const Color(0xFF00ACC1)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00ACC1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Modifier mon profil", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0, 3),
                _buildNavItem(Icons.calendar_today_rounded, "Rendez-vous", 1, 3),
                _buildNavItem(Icons.history_rounded, "Consultations", 2, 3),
                _buildNavItem(Icons.person_rounded, "Profil", 3, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisponibilites() {
    if (_disponibilites.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text("Aucune disponibilite", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const GererPlagesHorairesPage()));
                _chargerDonnees();
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00ACC1)),
              label: const Text("Ajouter une plage", style: TextStyle(color: Color(0xFF00ACC1))),
            ),
          ],
        ),
      );
    }
    final List<PlageHoraire> plagesAAfficher = _disponibilites.take(5).toList();
    final bool hasMore = _disponibilites.length > 5;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          ...plagesAAfficher.asMap().entries.map((MapEntry<int, PlageHoraire> entry) {
            final PlageHoraire dispo = entry.value;
            final bool isLast = entry.key == plagesAAfficher.length - 1 && !hasMore;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(dispo.date),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${dispo.heureDebut} - ${dispo.heureFin}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF00ACC1)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, indent: 38, color: Colors.grey),
              ],
            );
          }).toList(),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const GererPlagesHorairesPage()));
                  _chargerDonnees();
                },
                child: Text("Voir les ${_disponibilites.length} disponibilites", style: const TextStyle(color: Color(0xFF00ACC1))),
              ),
            ),
        ],
      ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
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

  Widget _buildNavItem(IconData icon, String label, int index, int currentIndex) {
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