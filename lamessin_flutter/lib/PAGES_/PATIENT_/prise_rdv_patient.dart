import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../SERVICES_/api_service.dart';

class RendezVousPage extends StatefulWidget {
  const RendezVousPage({super.key});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  // --- Variables (Conservées de l'original) ---
  int? _idMedecinSelectionne;
  int? _idCreneauSelectionne;
  DateTime? _dateChoisie;
  final _motif = TextEditingController();

  List<dynamic> _medecinsDisponibles = [];
  List<dynamic> _creneauxDisponibles = []; // Cette liste sera alimentée dynamiquement
  
  bool _estEnTrainDeCharger = false; // Pour le chargement initial ou la soumission
  bool _chargementCreneaux = false; // Pour le chargement spécifique des créneaux

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

  // --- Méthodes API ---

  // 1. Charger la liste des médecins
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

  // 2. Charger les créneaux quand une date est choisie (DYNAMIQUE)
  // NOTE: Pour que cela soit totalement connecté à ta DB, tu dois créer 
  // une endpoint dans ton ApiService qui récupère les créneaux libres 
  // pour ce médecin à cette date.
  Future<void> _chargerCreneauxDisponibles() async {
    if (_idMedecinSelectionne == null || _dateChoisie == null) return;

    setState(() => _chargementCreneaux = true);
    _creneauxDisponibles.clear(); // Réinitialiser
    _idCreneauSelectionne = null; // Désélectionner

    try {
      // --- APPEL API RÉEL (À DÉCOMMENTER QUAND TON BACKEND EST PRÊT) ---
      /*
      String dateStr = DateFormat('yyyy-MM-dd').format(_dateChoisie!);
      List<dynamic> data = await ApiService.getCreneaux(_idMedecinSelectionne!, dateStr);
      setState(() => _creneauxDisponibles = data);
      */

      // --- SIMULATION POUR DÉMO (Supprimer ce bloc quand l'API est prête) ---
      // Cela simule ce que le backend renverrait (Liste d'objets avec id et heure)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _creneauxDisponibles = [
          {"id": 1, "heure": "08:30"},
          {"id": 2, "heure": "09:00"},
          {"id": 3, "heure": "10:00"},
          {"id": 4, "heure": "14:00"},
          {"id": 5, "heure": "15:30"},
        ];
      });
      // ---------------------------------------------------------------

    } catch (e) {
      print("Erreur chargement créneaux: $e");
    } finally {
      setState(() => _chargementCreneaux = false);
    }
  }

  // 3. Validation et Envoi
  void _validerRendezVous() async {
    // Contrôles
    if (_idMedecinSelectionne == null) {
      _afficherMessage("Veuillez choisir un médecin.", Colors.orange);
      return;
    }
    if (_dateChoisie == null) {
      _afficherMessage("Veuillez choisir une date.", Colors.orange);
      return;
    }
    if (_idCreneauSelectionne == null) {
      _afficherMessage("Veuillez choisir un horaire.", Colors.orange);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      _afficherMessage("Merci de préciser le motif.", Colors.orange);
      return;
    }

    // Envoi
    setState(() => _estEnTrainDeCharger = true);

    Map<String, dynamic> rdv = {
      "patient_demandeur": 1, // ID du patient connecté
      "medecin_concerne": _idMedecinSelectionne,
      "creneau_reserve": _idCreneauSelectionne, // On envoie l'ID du créneau (comme l'original)
      "motif_consultation": _motif.text.trim(),
      "statut_actuel_rdv": "en_attente",
    };

    bool succes = await ApiService.creerRendezVous(rdv);

    if (!mounted) return;
    setState(() => _estEnTrainDeCharger = false);

    if (succes) {
      _afficherMessage("Rendez-vous enregistré avec succès !", Colors.green);
      Navigator.pop(context); // Retour arrière
    } else {
      _afficherMessage("Erreur lors de l'enregistrement.", Colors.red);
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: couleur),
    );
  }

  // --- INTERFACE UTILISATEUR ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prendre Rendez-vous"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _estEnTrainDeCharger && _medecinsDisponibles.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("1. Choix du praticien"),
                  _buildMedecinDropdown(),
                  const SizedBox(height: 25),

                  _buildSectionTitle("2. Date souhaitée"),
                  _buildDateSelector(),
                  const SizedBox(height: 25),

                  _buildSectionTitle("3. Horaire disponible"),
                  if (_dateChoisie != null) _buildCreneauxGrid() else const Text("Sélectionnez une date pour voir les horaires."),
                  const SizedBox(height: 30),

                  _buildSectionTitle("4. Motif de consultation"),
                  _buildMotifField(),
                  const SizedBox(height: 30),

                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS CONSTITUTIFS (UI) ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildMedecinDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          hint: const Text("Sélectionner un médecin"),
          value: _idMedecinSelectionne,
          items: _medecinsDisponibles.map((m) {
            return DropdownMenuItem<int>(
              value: m['id'],
              child: Text(
                "Dr ${m['compte_utilisateur']['last_name']} (${m['specialite_medicale']})",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            setState(() {
              _idMedecinSelectionne = id;
              // Si on change de médecin, on recharge les créneaux si une date est déjà là
              if (_dateChoisie != null) _chargerCreneauxDisponibles();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2026),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) {
          setState(() {
            _dateChoisie = picked;
          });
          // Déclencher le chargement dynamique des créneaux
          _chargerCreneauxDisponibles();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _dateChoisie == null
                    ? "Cliquez pour choisir une date"
                    : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateChoisie!),
                style: TextStyle(
                  fontSize: 16,
                  color: _dateChoisie == null ? Colors.grey.shade600 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreneauxGrid() {
    if (_chargementCreneaux) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_creneauxDisponibles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Text("Aucun créneau disponible pour cette date.", style: TextStyle(color: Colors.red)),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _creneauxDisponibles.map((creneau) {
        // On s'attend à ce que l'API renvoie {"id": ..., "heure": ...}
        int id = creneau['id'];
        String heure = creneau['heure'];
        bool isSelected = _idCreneauSelectionne == id;

        return ChoiceChip(
          label: Text(heure),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() => _idCreneauSelectionne = selected ? id : null);
          },
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 1),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMotifField() {
    return TextField(
      controller: _motif,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "Décrivez brièvement le motif...",
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _estEnTrainDeCharger ? null : _validerRendezVous,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        child: _estEnTrainDeCharger
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text("Confirmer le rendez-vous", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}