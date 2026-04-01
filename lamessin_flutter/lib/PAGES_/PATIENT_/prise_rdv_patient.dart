import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../SERVICES_/patient_service.dart'; // CORRECTION
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';

class RendezVousPage extends StatefulWidget {
  const RendezVousPage({super.key});
  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  Medecin? _medecinSelectionne;
  int? _idHeureSelectionnee;
  DateTime? _dateChoisie;
  String _specialiteFiltre = "Toutes";
  final _motif = TextEditingController();

  List<Medecin> _medecinsDisponibles = [];
  List<dynamic> _creneauxDisponibles = [];
  bool _estEnTrainDeCharger = false;
  bool _chargementCreneaux = false;
  String? _messageErreur;

  @override
  void initState() { super.initState(); _chargerMedecins(); }

  @override
  void dispose() { _motif.dispose(); super.dispose(); }

  Future<void> _chargerMedecins() async {
    setState(() { _estEnTrainDeCharger = true; _messageErreur = null; });
    try {
      List<Medecin> liste = await PatientService.getListeMedecins(); // CORRECTION
      if (mounted) setState(() {
        _medecinsDisponibles = liste;
        _estEnTrainDeCharger = false;
        if (liste.isEmpty) _messageErreur = "Aucun médecin trouvé.";
      });
    } catch (e) {
      if (mounted) setState(() {
        _estEnTrainDeCharger = false;
        _messageErreur = "Erreur de connexion : $e";
      });
    }
  }

  Future<void> _chargerCreneauxDisponibles() async {
    if (_medecinSelectionne == null || _dateChoisie == null) return;
    setState(() => _chargementCreneaux = true);
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_dateChoisie!);
      int idMed = _medecinSelectionne!.compteUtilisateur.id;
      List<dynamic> data = await PatientService.getCreneaux(idMed, dateStr); // CORRECTION
      setState(() {
        _creneauxDisponibles = data;
        _idHeureSelectionnee = null;
        _chargementCreneaux = false;
      });
    } catch (e) {
      AppWidgets.showSnack(context, "Erreur créneaux : $e", color: AppColors.danger);
      setState(() => _chargementCreneaux = false);
    }
  }

  void _validerRendezVous() async {
    if (_medecinSelectionne == null || _dateChoisie == null || _idHeureSelectionnee == null) {
      AppWidgets.showSnack(context, "Veuillez remplir tous les champs.", color: AppColors.warning);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      AppWidgets.showSnack(context, "Merci de préciser le motif.", color: AppColors.warning);
      return;
    }
    setState(() => _estEnTrainDeCharger = true);
    Map<String, dynamic> rdv = {
      "medecin_concerne": _medecinSelectionne!.compteUtilisateur.id,
      "date_rdv": DateFormat('yyyy-MM-dd').format(_dateChoisie!),
      "heure_rdv": _idHeureSelectionnee,
      "motif_consultation": _motif.text.trim(),
      "statut_actuel_rdv": "en_attente",
    };
    bool succes = await PatientService.creerRendezVous(rdv); // CORRECTION
    if (!mounted) return;
    setState(() => _estEnTrainDeCharger = false);
    if (succes) {
      AppWidgets.showSnack(context, "Rendez-vous enregistré !", color: AppColors.success);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/mes_rendez_vous_page',
            ModalRoute.withName('/page_utilisateur'));
      });
    } else {
      AppWidgets.showSnack(context, "Erreur lors de l'enregistrement.", color: AppColors.danger);
    }
  }

  List<String> get _categories => ["Toutes",
      ..._medecinsDisponibles.map((m) => m.specialiteMedicale).toSet().toList()];

  List<Medecin> get _medecinsAffiches => _specialiteFiltre == "Toutes"
      ? _medecinsDisponibles
      : _medecinsDisponibles.where((m) => m.specialiteMedicale == _specialiteFiltre).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const MenuNavigation(),
      appBar: AppWidgets.appBar("Prendre un rendez-vous"),
      body: _estEnTrainDeCharger && _medecinsDisponibles.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Message d'erreur
                if (_messageErreur != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_messageErreur!,
                        style: const TextStyle(color: Color(0xFFE65100))),
                  ),

                // ÉTAPE 1
                AppWidgets.stepHeader("1", "Rechercher un praticien"),
                if (_medecinsDisponibles.isNotEmpty) _buildFiltres(),
                const SizedBox(height: 10),
                _buildListeMedecins(),
                const SizedBox(height: 22),

                // ÉTAPE 2
                AppWidgets.stepHeader("2", "Date de consultation"),
                _buildSelecteurDate(),
                const SizedBox(height: 22),

                // ÉTAPE 3
                AppWidgets.stepHeader("3", "Horaires disponibles"),
                _buildCreneaux(),
                const SizedBox(height: 22),

                // ÉTAPE 4
                AppWidgets.stepHeader("4", "Motif de consultation"),
                _buildMotif(),
                const SizedBox(height: 30),

                AppWidgets.darkButton(
                  label: "Confirmer le rendez-vous",
                  onPressed: _estEnTrainDeCharger ? null : _validerRendezVous,
                  loading: _estEnTrainDeCharger,
                ),
                const SizedBox(height: 30),
              ]),
            ),
    );
  }

  Widget _buildFiltres() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.map((spec) {
          bool sel = _specialiteFiltre == spec;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _specialiteFiltre = spec;
                _medecinSelectionne = null;
                _dateChoisie = null;
                _creneauxDisponibles = [];
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border, width: 1.5),
                ),
                child: Text(spec, style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListeMedecins() {
    if (_medecinsAffiches.isEmpty) {
      return AppWidgets.card(child: const Center(
        child: Text("Aucun médecin disponible",
            style: TextStyle(color: AppColors.textSecondary))));
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.borderLight,
                width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded,
                    color: sel ? Colors.white : AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Dr ${med.compteUtilisateur.lastName}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: sel ? AppColors.primary : AppColors.textPrimary)),
                Text(med.specialiteMedicale,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
              if (sel) const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
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
          AppWidgets.showSnack(context, "Sélectionnez d'abord un médecin.", color: AppColors.warning);
          return;
        }
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2027),
          locale: const Locale('fr', 'FR'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primary)),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _dateChoisie = picked);
          _chargerCreneauxDisponibles();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _dateChoisie != null ? AppColors.primary : AppColors.borderLight,
            width: _dateChoisie != null ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month_rounded,
              color: _dateChoisie != null ? AppColors.primary : AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            _dateChoisie == null ? "Choisir une date"
                : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateChoisie!),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: _dateChoisie != null ? AppColors.primary : AppColors.textSecondary),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildCreneaux() {
    if (_chargementCreneaux)
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_dateChoisie == null)
      return AppWidgets.card(child: const Text("Sélectionnez d'abord une date",
          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)));
    if (_creneauxDisponibles.isEmpty)
      return AppWidgets.card(child: const Text(
          "Aucun créneau disponible. Vérifiez dans l'admin si des plages existent.",
          style: TextStyle(color: AppColors.danger)));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight)),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _creneauxDisponibles.map((c) {
          bool sel = _idHeureSelectionnee == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _idHeureSelectionnee = sel ? null : c['id']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border, width: 1.5),
              ),
              child: Text(c['heure'], style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.textPrimary)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMotif() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight)),
      child: TextField(
        controller: _motif, maxLines: 3,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: "Ex: Fièvre, consultation annuelle...",
          border: InputBorder.none, contentPadding: EdgeInsets.zero),
      ),
    );
  }
}