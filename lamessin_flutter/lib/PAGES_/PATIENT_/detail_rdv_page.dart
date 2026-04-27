import 'package:flutter/material.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../THEME_/app_theme.dart';

class DetailRdvPage extends StatefulWidget {
  final RendezVous rendezVous;
  const DetailRdvPage({super.key, required this.rendezVous});

  @override
  State<DetailRdvPage> createState() => _DetailRdvPageState();
}

class _DetailRdvPageState extends State<DetailRdvPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 2;

  final String _imageFond = "assets/images/rdv.jpeg";

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rdv = widget.rendezVous;
    final nomMedecin = rdv.medecinConcerne?.compteUtilisateur.lastName ?? "Medecin";
    final prenomMedecin = rdv.medecinConcerne?.compteUtilisateur.firstName ?? "";
    final specialite = rdv.medecinConcerne?.specialiteMedicale ?? "Generaliste";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: const Text("Detail du rendez-vous", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Row(
                      children: [
                        Container(width: 60, height: 60, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.person_rounded, color: _brandColor, size: 30)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Dr $nomMedecin $prenomMedecin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _brandColor)),
                              const SizedBox(height: 4),
                              Text(specialite, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Informations du rendez-vous", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(height: 16),
                        _infoRow(Icons.calendar_today_rounded, "Date", rdv.dateRdv),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time_rounded, "Heure", rdv.heureRdv),
                        const SizedBox(height: 12),
                        _infoRow(Icons.description_rounded, "Motif", rdv.motifConsultation),
                        const SizedBox(height: 12),
                        _infoRow(Icons.info_outline_rounded, "Statut", _getStatutText(rdv.statutActuelRdv)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: _brandColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text("Retour", style: TextStyle(color: _brandColor, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente de confirmation';
      case 'confirme': return 'Confirme';
      case 'annule': return 'Annule';
      case 'termine': return 'Termine';
      case 'expire': return 'Expire';
      default: return statut;
    }
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
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}