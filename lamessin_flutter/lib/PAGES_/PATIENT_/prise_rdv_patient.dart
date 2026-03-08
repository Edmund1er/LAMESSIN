import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../SERVICES_/api_service.dart';

// AJOUT DU MENU
import '../../WIDGETS_/menu_navigation.dart';

class RendezVousPage extends StatefulWidget {
  const RendezVousPage({super.key});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  dynamic _medecinSelectionne;
  String? _heureSelectionnee;
  DateTime? _dateChoisie;
  String _specialiteFiltre = "Toutes"; 
  final _motif = TextEditingController();

  List<dynamic> _medecinsDisponibles = [];
  List<dynamic> _creneauxDisponibles = []; 
  
  bool _estEnTrainDeCharger = false;
  bool _chargementCreneaux = false; 

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
    setState(() => _estEnTrainDeCharger = true);
    try {
      List<dynamic> liste = await ApiService.getListeMedecins();
      setState(() => _medecinsDisponibles = liste);
    } catch (e) {
      print("Erreur médecins: $e");
    } finally {
      setState(() => _estEnTrainDeCharger = false);
    }
  }

  Future<void> _chargerCreneauxDisponibles() async {
    if (_medecinSelectionne == null || _dateChoisie == null) return;
    setState(() => _chargementCreneaux = true);
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_dateChoisie!);
      int idMed = _medecinSelectionne['compte_utilisateur']['id']; 
      List<dynamic> data = await ApiService.getCreneaux(idMed, dateStr);
      setState(() {
        _creneauxDisponibles = data;
        _heureSelectionnee = null; 
      });
    } catch (e) {
      print("Erreur : $e");
      _afficherMessage("Erreur lors du chargement des créneaux.", Colors.red);
    } finally {
      setState(() => _chargementCreneaux = false);
    }
  }

  void _validerRendezVous() async {
    if (_medecinSelectionne == null || _dateChoisie == null || _heureSelectionnee == null) {
      _afficherMessage("Veuillez remplir tous les champs.", Colors.orange);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      _afficherMessage("Merci de préciser le motif.", Colors.orange);
      return;
    }
    setState(() => _estEnTrainDeCharger = true);
    Map<String, dynamic> rdv = {
      "medecin_concerne": _medecinSelectionne['compte_utilisateur']['id'], 
      "date_rdv": DateFormat('yyyy-MM-dd').format(_dateChoisie!), 
      "heure_rdv": _heureSelectionnee,                            
      "motif_consultation": _motif.text.trim(),
      "statut_actuel_rdv": "en_attente",
    };
    bool succes = await ApiService.creerRendezVous(rdv);
    if (!mounted) return;
    setState(() => _estEnTrainDeCharger = false);
    if (succes) {
      _afficherMessage("Rendez-vous enregistré avec succès !", Colors.green);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/mes_rendez_vous_page', ModalRoute.withName('/page_utilisateur'));
      });
    } else {
      _afficherMessage("Erreur lors de l'enregistrement.", Colors.red);
    }
  }

  List<String> get _categories {
    final specs = _medecinsDisponibles.map((m) => m['specialite_medicale'] as String).toSet().toList();
    return ["Toutes", ...specs];
  }

  List<dynamic> get _medecinsAffiches {
    if (_specialiteFiltre == "Toutes") return _medecinsDisponibles;
    return _medecinsDisponibles.where((m) => m['specialite_medicale'] == _specialiteFiltre).toList();
  }

  Widget _buildFiltreSpecialite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Filtrer par spécialité :", style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((spec) {
              bool estSelectionne = _specialiteFiltre == spec;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(spec),
                  selected: estSelectionne,
                  selectedColor: Colors.blueAccent,
                  onSelected: (bool selected) {
                    setState(() {
                      _specialiteFiltre = spec;
                      _medecinSelectionne = null; 
                      _dateChoisie = null;
                      _creneauxDisponibles = [];
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMedecinDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<dynamic>(
        value: _medecinsAffiches.contains(_medecinSelectionne) ? _medecinSelectionne : null,
        hint: const Text("Sélectionnez un médecin"),
        isExpanded: true,
        items: _medecinsAffiches.map((dynamic med) {
          final infoPerso = med['compte_utilisateur']; 
          return DropdownMenuItem<dynamic>(
            value: med,
            child: Text("Dr ${infoPerso['last_name']} (${med['specialite_medicale']})"),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _medecinSelectionne = newValue;
            _dateChoisie = null;
            _creneauxDisponibles = [];
          });
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      leading: const Icon(Icons.event, color: Colors.blueAccent),
      title: Text(_dateChoisie == null ? "Choisir une date" : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateChoisie!)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2027),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) {
          setState(() => _dateChoisie = picked);
          _chargerCreneauxDisponibles();
        }
      },
    );
  }

  Widget _buildCreneauxGrid() {
    if (_chargementCreneaux) return const Center(child: CircularProgressIndicator());
    if (_creneauxDisponibles.isEmpty) return const Text("Aucun créneau ce jour.");
    return Wrap(
      spacing: 8,
      children: _creneauxDisponibles.map((c) {
        bool selected = _heureSelectionnee == c['id']; 
        return ChoiceChip(
          label: Text(c['heure']),
          selected: selected,
          selectedColor: Colors.blueAccent,
          onSelected: (s) => setState(() => _heureSelectionnee = s ? c['id'] : null),
        );
      }).toList(),
    );
  }

  Widget _buildMotifField() {
    return TextField(
      controller: _motif,
      maxLines: 2,
      decoration: const InputDecoration(hintText: "Ex: Fièvre, consultation annuelle...", border: InputBorder.none),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _estEnTrainDeCharger ? null : _validerRendezVous,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _estEnTrainDeCharger ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirmer le rendez-vous", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  Widget _buildSectionHeader(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Colors.blueAccent, child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      // MENU AJOUTÉ
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Prendre un Rendez-vous", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _estEnTrainDeCharger && _medecinsDisponibles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("1", "Rechercher un Praticien"),
                  _buildFiltreSpecialite(),
                  const SizedBox(height: 12),
                  _buildGlassCard(child: _buildMedecinDropdown()),
                  const SizedBox(height: 20),
                  _buildSectionHeader("2", "Date de Consultation"),
                  _buildGlassCard(child: _buildDateSelector()),
                  const SizedBox(height: 20),
                  _buildSectionHeader("3", "Horaires Disponibles"),
                  _buildGlassCard(child: _dateChoisie != null ? _buildCreneauxGrid() : const Text("Sélectionnez d'abord une date", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                  const SizedBox(height: 20),
                  _buildSectionHeader("4", "Motif de Consultation"),
                  _buildGlassCard(child: _buildMotifField()),
                  const SizedBox(height: 35),
                  _buildSubmitButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}