import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/rendezvous_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_profil_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_detail_consultation_page.dart';

class MedecinRendezVousPage extends StatefulWidget {
  const MedecinRendezVousPage({super.key});

  @override
  State<MedecinRendezVousPage> createState() => _MedecinRendezVousPageState();
}

class _MedecinRendezVousPageState extends State<MedecinRendezVousPage> {
  List<RendezVous> _tousRdv = [];
  bool _chargement = true;
  String _filtre = "Tous";
  final List<String> _filtres = [
    "Tous",
    "En attente",
    "Confirmes",
    "Termines",
    "Annules",
    "Expires",
  ];

  final String _imageFond = "assets/images/fond_medecin_rendezvous.jpg";

  @override
  void initState() {
    super.initState();
    _chargerRdv();
  }

  Future<void> _chargerRdv() async {
    setState(() => _chargement = true);
    try {
      await DoctorService.expirerRendezVous();
      final data = await DoctorService.getMesRendezVousMedecin();
      if (mounted) {
        setState(() {
          _tousRdv = data;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _confirmerRdv(int id) async {
    final ok = await DoctorService.updateRendezVousStatut(id, 'confirme');
    if (ok) {
      AppWidgets.showSnack(
        context,
        "Rendez-vous confirme",
        color: const Color(0xFF4CAF50),
      );
      _chargerRdv();
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de la confirmation",
        color: Colors.red,
      );
    }
  }

  Future<void> _annulerRdv(int id) async {
    final ok = await DoctorService.updateRendezVousStatut(id, 'annule');
    if (ok) {
      AppWidgets.showSnack(context, "Rendez-vous annule", color: Colors.orange);
      _chargerRdv();
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de l'annulation",
        color: Colors.red,
      );
    }
  }

  void _ouvrirFormulaireConsultation(int rdvId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedecinDetailConsultationPage(rdvId: rdvId),
      ),
    ).then((_) => _chargerRdv());
  }

  List<RendezVous> get _rdvFiltres {
    switch (_filtre) {
      case "En attente":
        return _tousRdv
            .where((r) => r.statutActuelRdv == 'en_attente')
            .toList();
      case "Confirmes":
        return _tousRdv.where((r) => r.statutActuelRdv == 'confirme').toList();
      case "Termines":
        return _tousRdv.where((r) => r.statutActuelRdv == 'termine').toList();
      case "Annules":
        return _tousRdv.where((r) => r.statutActuelRdv == 'annule').toList();
      case "Expires":
        return _tousRdv.where((r) => r.statutActuelRdv == 'expire').toList();
      default:
        return _tousRdv;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return const Color(0xFFF57C00);
      case 'confirme':
        return const Color(0xFF00ACC1);
      case 'termine':
        return const Color(0xFF4CAF50);
      case 'annule':
        return const Color(0xFFEF5350);
      case 'expire':
        return Colors.grey[600]!;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente':
        return "En attente";
      case 'confirme':
        return "Confirme";
      case 'termine':
        return "Termine";
      case 'annule':
        return "Annule";
      case 'expire':
        return "Expire";
      default:
        return statut;
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinDashboardPage()),
      );
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedecinProfilPage()),
      );
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MedecinDashboardPage()),
          ),
        ),
        title: const Text(
          "Mes rendez-vous",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _chargerRdv,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _imageFond,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[100]),
            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF00ACC1)
                                  : Colors.white,
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
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00ACC1),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _chargerRdv,
                          color: const Color(0xFF00ACC1),
                          child: _rdvFiltres.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy_rounded,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Aucun rendez-vous",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _rdvFiltres.length,
                                  itemBuilder: (_, i) {
                                    final rdv = _rdvFiltres[i];
                                    final isEnAttente =
                                        rdv.statutActuelRdv == 'en_attente';
                                    final isConfirme =
                                        rdv.statutActuelRdv == 'confirme';
                                    final isExpire =
                                        rdv.statutActuelRdv == 'expire';
                                    final nomPatient =
                                        rdv
                                            .patientDemandeur
                                            ?.compteUtilisateur
                                            .firstName ??
                                        "Patient";
                                    final prenomPatient =
                                        rdv
                                            .patientDemandeur
                                            ?.compteUtilisateur
                                            .lastName ??
                                        "";
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE0F7FA,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  color: Color(0xFF00ACC1),
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "$nomPatient $prenomPatient",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      rdv.motifConsultation ??
                                                          "Consultation generale",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    rdv.statutActuelRdv,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _getStatusText(
                                                    rdv.statutActuelRdv,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getStatusColor(
                                                      rdv.statutActuelRdv,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  rdv.dateRdv,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  rdv.heureRdv,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (isEnAttente && !isExpire)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _confirmerDialog(
                                                          rdv.id,
                                                        ),
                                                    style: OutlinedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF4CAF50,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      side: BorderSide.none,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "Confirmer",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _annulerDialog(rdv.id),
                                                    style: OutlinedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.white,
                                                      foregroundColor:
                                                          const Color(
                                                            0xFFEF5350,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFFEF5350,
                                                        ),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "Annuler",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (isConfirme && !isExpire)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _ouvrirFormulaireConsultation(
                                                      rdv.id,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF00ACC1,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                                child: const Text(
                                                  "Remplir la consultation",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isExpire)
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    color: Colors.grey,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Ce rendez-vous a expire",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0, 1),
                _buildNavItem(
                  Icons.calendar_today_rounded,
                  "Rendez-vous",
                  1,
                  1,
                ),
                _buildNavItem(Icons.history_rounded, "Consultations", 2, 1),
                _buildNavItem(Icons.person_rounded, "Profil", 3, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmerDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text("Voulez-vous confirmer ce rendez-vous ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmerRdv(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  void _annulerDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Annuler",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Voulez-vous annuler ce rendez-vous ? Cette action est irreversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Retour", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _annulerRdv(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
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