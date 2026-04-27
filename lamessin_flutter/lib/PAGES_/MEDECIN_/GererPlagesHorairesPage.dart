import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/plage_horaire_model.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_profil_page.dart';

class GererPlagesHorairesPage extends StatefulWidget {
  const GererPlagesHorairesPage({super.key});

  @override
  State<GererPlagesHorairesPage> createState() => _GererPlagesHorairesPageState();
}

class _GererPlagesHorairesPageState extends State<GererPlagesHorairesPage> {
  List<PlageHoraire> _plagesHoraires = [];
  bool _isLoading = true;
  bool _isAdding = false;

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedHeureDebut;
  TimeOfDay? _selectedHeureFin;
  final _dureeController = TextEditingController(text: '60');

  final String _imageFond = "assets/images/fond_medecin_disponibilites.jpg";

  @override
  void initState() {
    super.initState();
    _loadPlagesHoraires();
  }

  @override
  void dispose() {
    _dureeController.dispose();
    super.dispose();
  }

  Future<void> _loadPlagesHoraires() async {
    setState(() => _isLoading = true);
    try {
      final plages = await DoctorService.getPlagesHoraires();
      if (mounted) {
        setState(() {
          _plagesHoraires = plages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erreur lors du chargement', isError: true);
      }
    }
  }

  Future<void> _ajouterPlageHoraire() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedHeureDebut == null || _selectedHeureFin == null) {
      _showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }
    setState(() => _isAdding = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final heureDebutStr = '${_selectedHeureDebut!.hour.toString().padLeft(2, '0')}:${_selectedHeureDebut!.minute.toString().padLeft(2, '0')}';
      final heureFinStr = '${_selectedHeureFin!.hour.toString().padLeft(2, '0')}:${_selectedHeureFin!.minute.toString().padLeft(2, '0')}';
      final success = await DoctorService.ajouterPlageHoraire(
        date: dateStr,
        heureDebut: heureDebutStr,
        heureFin: heureFinStr,
        dureeConsultation: int.parse(_dureeController.text),
      );
      if (mounted) {
        if (success) {
          _showSnackBar('Plage horaire ajoutee avec succes');
          _resetForm();
          await _loadPlagesHoraires();
        } else {
          _showSnackBar('Erreur lors de l\'ajout', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _supprimerPlageHoraire(PlageHoraire plage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer la plage du ${_formatDate(plage.date)} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final success = await DoctorService.supprimerPlageHoraire(plage.id);
      if (mounted) {
        if (success) {
          _showSnackBar('Plage horaire supprimee');
          await _loadPlagesHoraires();
        } else {
          _showSnackBar('Erreur lors de la suppression', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', isError: true);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = null;
      _selectedHeureDebut = null;
      _selectedHeureFin = null;
      _dureeController.text = '60';
    });
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00ACC1)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime(bool isDebut) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00ACC1)),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isDebut) {
          _selectedHeureDebut = time;
        } else {
          _selectedHeureFin = time;
        }
      });
    }
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
        title: const Text("Gerer mes disponibilites", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
              : Container(
                  color: Colors.white.withOpacity(0.92),
                  child: RefreshIndicator(
                    onRefresh: _loadPlagesHoraires,
                    color: const Color(0xFF00ACC1),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Ajouter une plage horaire", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  _buildFormField(
                                    label: "Date",
                                    value: _selectedDate != null ? _formatDate(_selectedDate!.toIso8601String().split('T')[0]) : "Selectionner une date",
                                    icon: Icons.calendar_today_rounded,
                                    onTap: _selectDate,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    label: "Heure de debut",
                                    value: _selectedHeureDebut != null ? _selectedHeureDebut!.format(context) : "Selectionner une heure",
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _selectTime(true),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    label: "Heure de fin",
                                    value: _selectedHeureFin != null ? _selectedHeureFin!.format(context) : "Selectionner une heure",
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _selectTime(false),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _dureeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "Duree (minutes)",
                                      prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF00ACC1)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Champ requis';
                                      final duree = int.tryParse(value);
                                      if (duree == null || duree < 15 || duree > 120) return 'Entre 15 et 120 minutes';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _isAdding ? null : _ajouterPlageHoraire,
                                      icon: _isAdding ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_rounded),
                                      label: Text(_isAdding ? 'Ajout en cours...' : 'Ajouter la plage'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00ACC1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text("Mes plages horaires", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(20)),
                                child: Text('${_plagesHoraires.length}', style: const TextStyle(color: Color(0xFF00ACC1), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPlagesList(),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildFormField({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF00ACC1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPlagesList() {
    if (_plagesHoraires.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text("Aucune plage horaire", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    final List<PlageHoraire> sortedPlages = List.from(_plagesHoraires)..sort((a, b) => b.date.compareTo(a.date));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: sortedPlages.asMap().entries.map((MapEntry<int, PlageHoraire> entry) {
          final PlageHoraire plage = entry.value;
          final bool isLast = entry.key == sortedPlages.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00ACC1)),
                ),
                title: Text(_formatDate(plage.date), style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                subtitle: Text(
                  '${plage.heureDebut} - ${plage.heureFin}  ${plage.dureeConsultation} min',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _supprimerPlageHoraire(plage),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 72, color: Colors.grey),
            ],
          );
        }).toList(),
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