import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../SERVICES_/patient_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';

class RendezVousPage extends StatefulWidget {
  const RendezVousPage({super.key});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  static const Color _brandColor = Color(0xFF00ACC1);

  Medecin? _medecinSelectionne;
  String? _heureSelectionnee;
  DateTime? _dateChoisie;
  String _specialiteFiltre = "Toutes";
  final _motif = TextEditingController();
  int _selectedIndex = 2;

  List<Medecin> _medecinsDisponibles = [];
  List<dynamic> _creneauxDisponibles = [];
  bool _estEnTrainDeCharger = false;
  bool _chargementCreneaux = false;
  String? _messageErreur;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    _chargerMedecins();
  }

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _chargerMedecins() async {
    setState(() {
      _estEnTrainDeCharger = true;
      _messageErreur = null;
    });
    try {
      List<Medecin> liste = await PatientService.getListeMedecins();
      if (mounted) {
        setState(() {
          _medecinsDisponibles = liste;
          _estEnTrainDeCharger = false;
          if (liste.isEmpty) {
            _messageErreur = "Aucun medecin trouve.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estEnTrainDeCharger = false;
          _messageErreur = "Erreur de connexion : $e";
        });
      }
    }
  }

  Future<void> _chargerCreneauxDisponibles() async {
    if (_medecinSelectionne == null || _dateChoisie == null) {
      return;
    }
    setState(() => _chargementCreneaux = true);
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_dateChoisie!);
      int idMed = _medecinSelectionne!.compteUtilisateur.id;

      List<dynamic> data = await PatientService.getCreneaux(idMed, dateStr);

      setState(() {
        _creneauxDisponibles = data;
        _heureSelectionnee = null;
        _chargementCreneaux = false;
      });
    } catch (e) {
      AppWidgets.showSnack(context, "Erreur creneaux : $e", color: AppColors.danger);
      setState(() => _chargementCreneaux = false);
    }
  }

  void _validerRendezVous() async {
    if (_medecinSelectionne == null || _dateChoisie == null || _heureSelectionnee == null) {
      AppWidgets.showSnack(context, "Veuillez remplir tous les champs.", color: AppColors.warning);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      AppWidgets.showSnack(context, "Merci de preciser le motif.", color: AppColors.warning);
      return;
    }

    setState(() => _estEnTrainDeCharger = true);

    Map<String, dynamic> rdv = {
      "medecin_concerne": _medecinSelectionne!.compteUtilisateur.id,
      "date_rdv": DateFormat('yyyy-MM-dd').format(_dateChoisie!),
      "heure_rdv": _heureSelectionnee,
      "motif_consultation": _motif.text.trim(),
      "statut_actuel_rdv": "en_attente",
    };

    bool succes = await PatientService.creerRendezVous(rdv);
    if (!mounted) return;
    setState(() => _estEnTrainDeCharger = false);

    if (succes) {
      AppWidgets.showSnack(context, "Rendez-vous enregistre !", color: AppColors.success);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/mes_rendez_vous_page', ModalRoute.withName('/page_utilisateur'));
      });
    } else {
      AppWidgets.showSnack(context, "Erreur lors de l'enregistrement.", color: AppColors.danger);
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

  IconData _getIconForSpecialty(String spec) {
    switch (spec.toLowerCase()) {
      case 'cardiologie': return Icons.favorite;
      case 'dentiste': return Icons.clean_hands;
      case 'pediatrie': return Icons.child_care;
      case 'gynecologie': return Icons.woman;
      case 'neurologie': return Icons.psychology;
      case 'ophtalmologie': return Icons.visibility;
      case 'generaliste': return Icons.medical_services;
      case 'pneumologie': return Icons.air;
      case 'dermatologie': return Icons.face;
      default: return Icons.medication;
    }
  }

  List<String> get _categories => [
    "Toutes",
    ..._medecinsDisponibles.map((m) => m.specialiteMedicale).toSet().toList()
  ];

  List<Medecin> get _medecinsAffiches => _specialiteFiltre == "Toutes"
      ? _medecinsDisponibles
      : _medecinsDisponibles.where((m) => m.specialiteMedicale == _specialiteFiltre).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Prendre RDV", style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _brandColor),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Column(
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _brandColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, spreadRadius: 5)],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _buildTinyGrid(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  width: double.infinity,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (_messageErreur != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                              child: Text(_messageErreur!, style: const TextStyle(color: Colors.red)),
                            ),
                          const Text("Medecins disponibles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _brandColor)),
                          const SizedBox(height: 16),
                          _buildListeMedecins(),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Date de consultation"),
                          const SizedBox(height: 12),
                          _buildSelecteurDate(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Horaires"),
                          const SizedBox(height: 12),
                          _buildCreneaux(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Motif"),
                          const SizedBox(height: 12),
                          _buildMotif(),
                          const SizedBox(height: 30),
                          AppWidgets.primaryButton(
                            label: "Confirmer le rendez-vous",
                            onPressed: _estEnTrainDeCharger ? null : _validerRendezVous,
                            loading: _estEnTrainDeCharger,
                          ),
                          const SizedBox(height: 30),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brandColor));
  }

  Widget _buildTinyGrid() {
    int cols = MediaQuery.of(context).size.width > 600 ? 8 : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.0,
      children: _categories.map((spec) {
        bool isSelected = _specialiteFiltre == spec;
        return GestureDetector(
          onTap: () => setState(() {
            _specialiteFiltre = spec;
            _medecinSelectionne = null;
            _dateChoisie = null;
            _creneauxDisponibles = [];
          }),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _brandColor : Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(spec == "Toutes" ? Icons.grid_view : _getIconForSpecialty(spec), color: isSelected ? _brandColor : Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(
                  spec.length > 9 ? "${spec.substring(0, 7)}.." : spec,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isSelected ? _brandColor : Colors.white.withOpacity(0.9), fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListeMedecins() {
    if (_medecinsAffiches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        child: const Center(child: Text("Aucun medecin disponible", style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: _medecinsAffiches.map((med) {
        bool sel = _medecinSelectionne == med;
        return GestureDetector(
          onTap: () => setState(() {
            _medecinSelectionne = med;
            _dateChoisie = null;
            _creneauxDisponibles = [];
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel ? _brandColor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? _brandColor : Colors.grey.shade200, width: sel ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: _brandColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Dr ${med.compteUtilisateur.lastName}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: sel ? _brandColor : Colors.black87)),
                const SizedBox(height: 4),
                Text(med.specialiteMedicale, style: TextStyle(fontSize: 13, color: sel ? _brandColor : Colors.grey[600])),
              ])),
              if (sel) Icon(Icons.check_circle_rounded, color: _brandColor, size: 26),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelecteurDate() {
    return GestureDetector(
      onTap: () async {
        if (_medecinSelectionne == null) {
          AppWidgets.showSnack(context, "Selectionnez d'abord un medecin.", color: AppColors.warning);
          return;
        }
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2027),
          locale: const Locale('fr', 'FR'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _dateChoisie = picked);
          _chargerCreneauxDisponibles();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dateChoisie != null ? _brandColor : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today, color: _dateChoisie != null ? _brandColor : Colors.grey, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dateChoisie == null ? "Choisir une date" : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateChoisie!),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _dateChoisie != null ? _brandColor : Colors.black54),
            ),
          ),
          if (_dateChoisie != null) const Icon(Icons.check, color: Colors.green, size: 22),
        ]),
      ),
    );
  }

  Widget _buildCreneaux() {
    if (_chargementCreneaux) return const Center(child: CircularProgressIndicator(color: _brandColor));
    if (_dateChoisie == null) return const Center(child: Text("Selectionnez une date d'abord", style: TextStyle(color: Colors.grey)));
    if (_creneauxDisponibles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Text("Aucun creneau disponible", style: TextStyle(color: Colors.grey)),
      );
    }

    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _creneauxDisponibles.map((c) {
        bool sel = _heureSelectionnee == c['heure'];
        return GestureDetector(
          onTap: () => setState(() => _heureSelectionnee = sel ? null : c['heure']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? _brandColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? _brandColor : Colors.grey.shade300, width: 1.5),
            ),
            child: Text(c['heure'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.black87)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMotif() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300, width: 1)),
      child: TextField(
        controller: _motif,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: const InputDecoration(
          hintText: "Decrivez vos symptomes...",
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
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
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}