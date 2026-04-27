import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../MODELS_/consultation_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_profil_page.dart';
import 'medecin_detail_consultation_page.dart';

class MedecinConsultationsPage extends StatefulWidget {
  const MedecinConsultationsPage({super.key});

  @override
  State<MedecinConsultationsPage> createState() => _MedecinConsultationsPageState();
}

class _MedecinConsultationsPageState extends State<MedecinConsultationsPage> {
  List<Consultation> _consultations = [];
  bool _chargement = true;
  String _periode = "Toutes";
  final List<String> _periodes = ["Toutes", "Ce mois", "Cette annee"];

  final String _imageFond = "assets/images/fond_medecin_consultations.jpg";

  @override
  void initState() {
    super.initState();
    _chargerConsultations();
  }

  Future<void> _chargerConsultations() async {
    setState(() => _chargement = true);
    try {
      final tousRdv = await DoctorService.getMesRendezVousMedecin();
      final rdvTermines = tousRdv.where((rdv) => rdv.statutActuelRdv == 'termine').toList();

      List<Consultation> consultations = [];
      for (var rdv in rdvTermines) {
        try {
          final data = await DoctorService.getConsultationByRdv(rdv.id);
          if (data != null) {
            consultations.add(Consultation.fromJson(data));
          }
        } catch (e) {
          debugPrint("Erreur: $e");
        }
      }

      if (mounted) {
        setState(() {
          _consultations = consultations;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Consultation> get _consultationsFiltrees {
    final now = DateTime.now();
    switch (_periode) {
      case "Ce mois":
        final debutMois = DateTime(now.year, now.month, 1);
        final finMois = DateTime(now.year, now.month + 1, 0);
        return _consultations.where((c) {
          final date = DateTime.tryParse(c.dateConsultation);
          if (date == null) return false;
          return date.isAfter(debutMois.subtract(const Duration(days: 1))) && date.isBefore(finMois.add(const Duration(days: 1)));
        }).toList();
      case "Cette annee":
        final debutAnnee = DateTime(now.year, 1, 1);
        final finAnnee = DateTime(now.year, 12, 31);
        return _consultations.where((c) {
          final date = DateTime.tryParse(c.dateConsultation);
          if (date == null) return false;
          return date.isAfter(debutAnnee.subtract(const Duration(days: 1))) && date.isBefore(finAnnee.add(const Duration(days: 1)));
        }).toList();
      default:
        return _consultations;
    }
  }

  void _ouvrirDetailConsultation(Consultation consultation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedecinDetailConsultationPage(
          rdvId: consultation.rdvId,
          consultationExistante: consultation,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinRendezVousPage()));
    } else if (index == 2) {
      return;
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
        title: const Text("Consultations", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerConsultations),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Column(
            children: [
              Container(
                color: const Color(0xFF00ACC1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _periodes.map((p) {
                      final isSelected = _periode == p;
                      return GestureDetector(
                        onTap: () => setState(() => _periode = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF00ACC1) : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white.withOpacity(0.92),
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                      : RefreshIndicator(
                          onRefresh: _chargerConsultations,
                          color: const Color(0xFF00ACC1),
                          child: _consultationsFiltrees.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text("Aucune consultation", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                      const SizedBox(height: 8),
                                      Text("Les consultations terminees apparaitront ici", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _consultationsFiltrees.length,
                                  itemBuilder: (_, i) {
                                    final consultation = _consultationsFiltrees[i];
                                    String dateFormatee = consultation.dateConsultation;
                                    try {
                                      final date = DateTime.parse(consultation.dateConsultation);
                                      dateFormatee = "${date.day}/${date.month}/${date.year}";
                                    } catch (e) {}
                                    return GestureDetector(
                                      onTap: () => _ouvrirDetailConsultation(consultation),
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
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: const Icon(Icons.medical_information_rounded, color: Color(0xFF4CAF50), size: 26),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    consultation.diagnostic.length > 40
                                                        ? "${consultation.diagnostic.substring(0, 40)}..."
                                                        : consultation.diagnostic,
                                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(dateFormatee, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text("Termine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ),
            ],
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
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0, 2),
                _buildNavItem(Icons.calendar_today_rounded, "Rendez-vous", 1, 2),
                _buildNavItem(Icons.history_rounded, "Consultations", 2, 2),
                _buildNavItem(Icons.person_rounded, "Profil", 3, 2),
              ],
            ),
          ),
        ),
      ),
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