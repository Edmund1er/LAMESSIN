import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../MODELS_/ordonnance_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_profil_page.dart';

class MedecinOrdonnancesPage extends StatefulWidget {
  const MedecinOrdonnancesPage({super.key});

  @override
  State<MedecinOrdonnancesPage> createState() => _MedecinOrdonnancesPageState();
}

class _MedecinOrdonnancesPageState extends State<MedecinOrdonnancesPage> {
  List<Ordonnance> _ordonnances = [];
  bool _chargement = true;
  String _filtre = "Toutes";
  final List<String> _filtres = ["Toutes", "Ce mois", "Cette annee"];

  final String _imageFond = "assets/images/fond_medecin_ordonnances.jpg";

  @override
  void initState() {
    super.initState();
    _chargerOrdonnances();
  }

  Future<void> _chargerOrdonnances() async {
    setState(() => _chargement = true);
    try {
      final data = await DoctorService.getOrdonnances();
      final ordonnances = data.map((item) => Ordonnance.fromJson(item)).toList();
      if (mounted) {
        setState(() {
          _ordonnances = ordonnances;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Ordonnance> get _ordonnancesFiltrees {
    final now = DateTime.now();
    switch (_filtre) {
      case "Ce mois":
        final debutMois = DateTime(now.year, now.month, 1);
        final finMois = DateTime(now.year, now.month + 1, 0);
        return _ordonnances.where((o) {
          final date = DateTime.tryParse(o.datePrescription);
          if (date == null) return false;
          return date.isAfter(debutMois.subtract(const Duration(days: 1))) && date.isBefore(finMois.add(const Duration(days: 1)));
        }).toList();
      case "Cette annee":
        final debutAnnee = DateTime(now.year, 1, 1);
        final finAnnee = DateTime(now.year, 12, 31);
        return _ordonnances.where((o) {
          final date = DateTime.tryParse(o.datePrescription);
          if (date == null) return false;
          return date.isAfter(debutAnnee.subtract(const Duration(days: 1))) && date.isBefore(finAnnee.add(const Duration(days: 1)));
        }).toList();
      default:
        return _ordonnances;
    }
  }

  void _voirDetailOrdonnance(Ordonnance ordonnance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("Detail de l'ordonnance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF00ACC1)),
                  const SizedBox(width: 8),
                  Text("Code securite: ${ordonnance.codeSecurite ?? 'Non genere'}", style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF00ACC1))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("Prescrite le ${ordonnance.datePrescription}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text("Medicaments prescrits:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 8),
            ...ordonnance.lignes.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nomMedicament, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("Quantite: ${l.quantiteBoites} boite(s)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Posologie: ${l.posologieSpecifique}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Duree: ${l.dureeTraitementJours} jours", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Fermer"),
              ),
            ),
          ],
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
        title: const Text("Mes ordonnances", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerOrdonnances),
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
                    children: _filtres.map((f) {
                      final isSelected = _filtre == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filtre = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
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
                          onRefresh: _chargerOrdonnances,
                          color: const Color(0xFF00ACC1),
                          child: _ordonnancesFiltrees.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text("Aucune ordonnance", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _ordonnancesFiltrees.length,
                                  itemBuilder: (_, i) {
                                    final ordonnance = _ordonnancesFiltrees[i];
                                    final nbMedicaments = ordonnance.lignes.length;
                                    return GestureDetector(
                                      onTap: () => _voirDetailOrdonnance(ordonnance),
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
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE0F7FA),
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                  child: const Icon(Icons.description_rounded, color: Color(0xFF00ACC1), size: 26),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Ordonnance du ${ordonnance.datePrescription}",
                                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "$nbMedicaments medicament(s) prescrit(s)",
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text("Valide", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Code: ${ordonnance.codeSecurite ?? 'Non genere'}",
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                  ),
                                                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                                                ],
                                              ),
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