import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/utilisateur_model.dart';

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
  String? _messageErreur; // Pour stocker les erreurs éventuelles

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
      List<Medecin> liste = await ApiService.getListeMedecins();

      if (mounted) {
        setState(() {
          _medecinsDisponibles = liste;
          _estEnTrainDeCharger = false;
          // DEBUG : Si la liste est vide, on le note
          if (liste.isEmpty) {
            _messageErreur = "Aucun médecin trouvé dans la base de données.";
          }
        });
      }
    } catch (e) {
      print("Erreur médecins: $e");
      if (mounted) {
        setState(() {
          _estEnTrainDeCharger = false;
          _messageErreur = "Erreur de connexion au serveur: $e";
        });
      }
    }
  }

  Future<void> _chargerCreneauxDisponibles() async {
    if (_medecinSelectionne == null || _dateChoisie == null) return;
    setState(() => _chargementCreneaux = true);
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_dateChoisie!);
      int idMed = _medecinSelectionne!.compteUtilisateur.id;

      List<dynamic> data = await ApiService.getCreneaux(idMed, dateStr);
      setState(() {
        _creneauxDisponibles = data;
        _idHeureSelectionnee = null;
        _chargementCreneaux = false;
      });
    } catch (e) {
      _afficherMessage(
        "Erreur lors du chargement des créneaux: $e",
        Colors.red,
      );
      setState(() => _chargementCreneaux = false);
    }
  }

  void _validerRendezVous() async {
    if (_medecinSelectionne == null ||
        _dateChoisie == null ||
        _idHeureSelectionnee == null) {
      _afficherMessage("Veuillez remplir tous les champs.", Colors.orange);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      _afficherMessage("Merci de préciser le motif.", Colors.orange);
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

    bool succes = await ApiService.creerRendezVous(rdv);

    if (!mounted) return;
    setState(() => _estEnTrainDeCharger = false);

    if (succes) {
      _afficherMessage("Rendez-vous enregistré avec succès !", Colors.green);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mes_rendez_vous_page',
          ModalRoute.withName('/page_utilisateur'),
        );
      });
    } else {
      _afficherMessage("Erreur lors de l'enregistrement.", Colors.red);
    }
  }

  List<String> get _categories {
    final specs = _medecinsDisponibles
        .map((m) => m.specialiteMedicale)
        .toSet()
        .toList();
    return ["Toutes", ...specs];
  }

  List<Medecin> get _medecinsAffiches {
    if (_specialiteFiltre == "Toutes") return _medecinsDisponibles;
    return _medecinsDisponibles
        .where((m) => m.specialiteMedicale == _specialiteFiltre)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text(
          "Prendre un Rendez-vous",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _estEnTrainDeCharger
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AFFICHAGE DU MESSAGE D'ERREUR OU D'INFORMATION
                  if (_messageErreur != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _messageErreur!,
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                    ),

                  _buildSectionHeader("1", "Rechercher un Praticien"),

                  // Affichage des filtres seulement s'il y a des médecins
                  if (_medecinsDisponibles.isNotEmpty) _buildFiltreSpecialite(),

                  const SizedBox(height: 12),
                  _buildGlassCard(child: _buildMedecinDropdown()),
                  const SizedBox(height: 20),
                  _buildSectionHeader("2", "Date de Consultation"),
                  _buildGlassCard(child: _buildDateSelector()),
                  const SizedBox(height: 20),
                  _buildSectionHeader("3", "Horaires Disponibles"),
                  _buildGlassCard(
                    child: _dateChoisie != null
                        ? _buildCreneauxGrid()
                        : const Text(
                            "Sélectionnez d'abord une date",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
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

  Widget _buildFiltreSpecialite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Filtrer par spécialité :",
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      child: DropdownButton<Medecin>(
        value: _medecinsAffiches.contains(_medecinSelectionne)
            ? _medecinSelectionne
            : null,
        hint: const Text("Sélectionnez un médecin"),
        isExpanded: true,
        items: _medecinsAffiches.map((Medecin med) {
          return DropdownMenuItem<Medecin>(
            value: med,
            child: Text(
              "Dr ${med.compteUtilisateur.lastName} (${med.specialiteMedicale})",
            ),
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
      title: Text(
        _dateChoisie == null
            ? "Choisir une date"
            : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateChoisie!),
      ),
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
    if (_chargementCreneaux)
      return const Center(child: CircularProgressIndicator());
    if (_creneauxDisponibles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(
          "Aucun créneau disponible pour cette date. (Vérifiez dans l'admin Django si des plages horaires existent)",
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: _creneauxDisponibles.map((c) {
        bool selected = _idHeureSelectionnee == c['id'];
        return ChoiceChip(
          label: Text(c['heure']),
          selected: selected,
          selectedColor: Colors.blueAccent,
          onSelected: (s) =>
              setState(() => _idHeureSelectionnee = s ? c['id'] : null),
        );
      }).toList(),
    );
  }

  Widget _buildMotifField() {
    return TextField(
      controller: _motif,
      maxLines: 2,
      decoration: const InputDecoration(
        hintText: "Ex: Fièvre, consultation...",
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _estEnTrainDeCharger ? null : _validerRendezVous,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _estEnTrainDeCharger
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Confirmer le rendez-vous",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  Widget _buildSectionHeader(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blueAccent,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
