import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';
import 'detail_rdv_page.dart';

class MesRendezVousPage extends StatefulWidget {
  const MesRendezVousPage({super.key});

  @override
  State<MesRendezVousPage> createState() => _MesRendezVousPageState();
}

class _MesRendezVousPageState extends State<MesRendezVousPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  List<RendezVous> _tousMesRDV = [];
  bool _chargement = true;
  int _selectedIndex = 2;

  final String _imageFond = "assets/images/rdv.jpeg";

  @override
  void initState() {
    super.initState();
    _recupererRendezVous();
  }

  Future<void> _recupererRendezVous() async {
    setState(() => _chargement = true);
    try {
      // 1. D'abord expirer les rendez-vous dont la date est passee
      await PatientService.expirerRendezVous();
      
      // 2. Ensuite charger la liste mise a jour
      final List<RendezVous> data = await PatientService.getMesRendezVous();
      setState(() {
        _tousMesRDV = data;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
      _msg("Erreur de recuperation", AppColors.danger);
    }
  }

  Future<void> _annulerRDV(int id) async {
    bool succes = await PatientService.annulerRendezVous(id);
    if (succes) {
      _msg("Rendez-vous annule", AppColors.warning);
      _recupererRendezVous();
    } else {
      _msg("Erreur lors de l'annulation", AppColors.danger);
    }
  }

  void _voirDetails(RendezVous rdv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailRdvPage(rendezVous: rdv)),
    );
  }

  List<RendezVous> get _rdvFuturs {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime d = DateTime.parse(rdv.dateRdv);
      return d.isAfter(now.subtract(const Duration(days: 1))) 
          && rdv.statutActuelRdv != 'annule' 
          && rdv.statutActuelRdv != 'expire';
    }).toList();
  }

  List<RendezVous> get _rdvPassesOuAnnules {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime d = DateTime.parse(rdv.dateRdv);
      return d.isBefore(now) || rdv.statutActuelRdv == 'annule' || rdv.statutActuelRdv == 'expire';
    }).toList();
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'confirme': return 'Confirme';
      case 'annule': return 'Annule';
      case 'termine': return 'Termine';
      case 'expire': return 'Expire';
      default: return statut;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente': return const Color(0xFFF57C00);
      case 'confirme': return const Color(0xFF00ACC1);
      case 'termine': return const Color(0xFF4CAF50);
      case 'annule': return const Color(0xFFEF5350);
      case 'expire': return Colors.grey[600]!;
      default: return Colors.grey;
    }
  }

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _brandColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text("Mes rendez-vous", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: "A venir"),
              Tab(text: "Historique"),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
            ),
            Container(
              color: Colors.white.withOpacity(0.92),
              child: _chargement
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                  : TabBarView(
                      children: [
                        _buildListe(_rdvFuturs, estAncien: false),
                        _buildListe(_rdvPassesOuAnnules, estAncien: true),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/rendez_vous_page'),
          backgroundColor: _brandColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          label: const Text("Prendre rendez-vous", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        bottomNavigationBar: _buildBottomNav(_selectedIndex),
      ),
    );
  }

  Widget _buildListe(List<RendezVous> liste, {required bool estAncien}) {
    if (liste.isEmpty) return _buildEmpty(estAncien);
    return RefreshIndicator(
      onRefresh: _recupererRendezVous,
      color: _brandColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100),
        itemCount: liste.length,
        itemBuilder: (_, i) => _buildCard(liste[i], grise: estAncien),
      ),
    );
  }

  Widget _buildCard(RendezVous rdv, {bool grise = false}) {
    final String nomMedecin = rdv.medecinConcerne?.compteUtilisateur.lastName ?? "Medecin";
    final String specialite = rdv.medecinConcerne?.specialiteMedicale ?? "Generaliste";
    final bool estAVenir = !grise && rdv.statutActuelRdv != 'annule' && rdv.statutActuelRdv != 'expire';
    final Color statutColor = _getStatusColor(rdv.statutActuelRdv);
    final String statutTexte = _getStatutText(rdv.statutActuelRdv);

    return Opacity(
      opacity: grise ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.person_rounded, color: _brandColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dr $nomMedecin", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                        Text(specialite, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statutColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(statutTexte, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statutColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(rdv.dateRdv, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(rdv.heureRdv, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (estAVenir) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmerAnnulation(rdv.id),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text("Annuler", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _voirDetails(rdv),
                        style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0),
                        child: const Text("Voir", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
              if (rdv.statutActuelRdv == 'expire')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text("Ce rendez-vous a expire", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool estAncien) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Icon(estAncien ? Icons.folder_open_rounded : Icons.event_busy_rounded, size: 36, color: _brandColor),
          ),
          const SizedBox(height: 16),
          Text(
            estAncien ? "Historique vide" : "Aucun rendez-vous a venir",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            estAncien ? "Vos anciens RDV apparaitront ici" : "Prenez un RDV des maintenant",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _confirmerAnnulation(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Annuler le rendez-vous ?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Cette action est irreversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Retour", style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _annulerRDV(id);
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _msg(String msg, Color c) {
    AppWidgets.showSnack(context, msg, color: c);
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