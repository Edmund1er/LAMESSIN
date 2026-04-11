import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../MODELS_/plage_horaire_model.dart';

class GererPlagesHorairesPage extends StatefulWidget {
  const GererPlagesHorairesPage({super.key});

  @override
  State<GererPlagesHorairesPage> createState() =>
      _GererPlagesHorairesPageState();
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
    if (_selectedDate == null ||
        _selectedHeureDebut == null ||
        _selectedHeureFin == null) {
      _showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }

    setState(() => _isAdding = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final heureDebutStr =
          '${_selectedHeureDebut!.hour.toString().padLeft(2, '0')}:${_selectedHeureDebut!.minute.toString().padLeft(2, '0')}';
      final heureFinStr =
          '${_selectedHeureFin!.hour.toString().padLeft(2, '0')}:${_selectedHeureFin!.minute.toString().padLeft(2, '0')}';

      final success = await DoctorService.ajouterPlageHoraire(
        date: dateStr,
        heureDebut: heureDebutStr,
        heureFin: heureFinStr,
        dureeConsultation: int.parse(_dureeController.text),
      );

      if (mounted) {
        if (success) {
          _showSnackBar('Plage horaire ajoutée avec succès');
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
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer la plage du ${_formatDate(plage.date)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await DoctorService.supprimerPlageHoraire(plage.id);
      if (mounted) {
        if (success) {
          _showSnackBar('Plage horaire supprimée');
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
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime(bool isDebut) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gérer mes disponibilités'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadPlagesHoraires,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddForm(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Mes plages horaires',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_plagesHoraires.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPlagesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter une plage horaire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Date',
              value: _selectedDate != null
                  ? _formatDate(_selectedDate!.toIso8601String().split('T')[0])
                  : 'Sélectionner une date',
              icon: Icons.calendar_today_rounded,
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              label: 'Heure de début',
              value: _selectedHeureDebut != null
                  ? _selectedHeureDebut!.format(context)
                  : 'Sélectionner une heure',
              icon: Icons.access_time_rounded,
              onTap: () => _selectTime(true),
            ),
            const SizedBox(height: 12),
            _buildFormField(
              label: 'Heure de fin',
              value: _selectedHeureFin != null
                  ? _selectedHeureFin!.format(context)
                  : 'Sélectionner une heure',
              icon: Icons.access_time_rounded,
              onTap: () => _selectTime(false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dureeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée (minutes)',
                prefixIcon: Icon(Icons.timer_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Champ requis';
                final duree = int.tryParse(value);
                if (duree == null || duree < 15 || duree > 120)
                  return 'Entre 15 et 120 minutes';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isAdding ? null : _ajouterPlageHoraire,
                icon: _isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _isAdding ? 'Ajout en cours...' : 'Ajouter la plage',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
            ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aucune plage horaire',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final sortedPlages = [..._plagesHoraires];
    sortedPlages.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: sortedPlages.asMap().entries.map((entry) {
          final plage = entry.value;
          final isLast = entry.key == sortedPlages.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  _formatDate(plage.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${plage.heureDebut} - ${plage.heureFin} • ${plage.dureeConsultation} min',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  onPressed: () => _supprimerPlageHoraire(plage),
                  tooltip: 'Supprimer',
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}
