import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_ordonnances_page.dart';
import 'medecin_profil_page.dart';
import 'medecin_dossier_patient_page.dart';

class MedecinPatientsPage extends StatefulWidget {
  const MedecinPatientsPage({super.key});

  @override
  State<MedecinPatientsPage> createState() => _MedecinPatientsPageState();
}

class _MedecinPatientsPageState extends State<MedecinPatientsPage> {
  List<Patient> _patients = [];
  bool _chargement = true;
  String _recherche = "";

  final String _imageFond = "assets/images/fond_medecin_patients.jpg";

  @override
  void initState() {
    super.initState();
    _chargerPatients();
  }

  Future<void> _chargerPatients() async {
    setState(() => _chargement = true);
    try {
      final data = await DoctorService.getMesPatients();
      final patients = data.map((item) => Patient.fromJson(item)).toList();
      if (mounted) {
        setState(() {
          _patients = patients;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Patient> get _patientsFiltres {
    if (_recherche.isEmpty) return _patients;
    return _patients.where((p) {
      final nom = p.compteUtilisateur.lastName.toLowerCase();
      final prenom = p.compteUtilisateur.firstName.toLowerCase();
      final telephone = p.compteUtilisateur.numeroTelephone?.toLowerCase() ?? "";
      final search = _recherche.toLowerCase();
      return nom.contains(search) || prenom.contains(search) || telephone.contains(search);
    }).toList();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinRendezVousPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinProfilPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Mes patients", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerPatients),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _recherche = value),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Rechercher un patient...",
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          _chargement
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
              : Container(
                  color: Colors.white.withOpacity(0.92),
                  child: RefreshIndicator(
                    onRefresh: _chargerPatients,
                    color: const Color(0xFF00ACC1),
                    child: _patientsFiltres.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text("Aucun patient", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _patientsFiltres.length,
                            itemBuilder: (_, i) {
                              final patient = _patientsFiltres[i];
                              final nom = patient.compteUtilisateur.lastName;
                              final prenom = patient.compteUtilisateur.firstName;
                              final telephone = patient.compteUtilisateur.numeroTelephone ?? "Non renseigne";
                              final email = patient.compteUtilisateur.email ?? "";
                              final groupeSanguin = patient.groupeSanguin ?? "Inconnu";
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MedecinDossierPatientPage(patientId: patient.compteUtilisateur.id)),
                                  ).then((_) => _chargerPatients());
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F7FA),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 26),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$prenom $nom",
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_rounded, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(telephone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(width: 12),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF5350).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    groupeSanguin,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFEF5350)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0),
                _buildNavItem(Icons.calendar_today_rounded, "Rendez-vous", 1),
                _buildNavItem(Icons.history_rounded, "Consultations", 2),
                _buildNavItem(Icons.person_rounded, "Profil", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}