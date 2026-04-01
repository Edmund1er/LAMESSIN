import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';

class EditProfilPage extends StatefulWidget {
  final Patient patient;
  const EditProfilPage({super.key, required this.patient});
  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _telController;
  bool _enChargement = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.patient.compteUtilisateur.firstName);
    _nomController    = TextEditingController(text: widget.patient.compteUtilisateur.lastName);
    _telController    = TextEditingController(text: widget.patient.compteUtilisateur.numeroTelephone);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  void _sauvegarder() async {
    if (_prenomController.text.trim().isEmpty ||
        _nomController.text.trim().isEmpty ||
        _telController.text.trim().isEmpty) {
      AppWidgets.showSnack(context,
          "Veuillez remplir tous les champs obligatoires", color: AppColors.danger);
      return;
    }
    setState(() => _enChargement = true);
    Map<String, dynamic> data = {
      "first_name":       _prenomController.text.trim(),
      "last_name":        _nomController.text.trim(),
      "numero_telephone": _telController.text.trim(),
    };
    bool succes = await ApiService.updateProfil(data);
    if (mounted) {
      setState(() => _enChargement = false);
      if (succes) {
        Navigator.pop(context, true);
      } else {
        AppWidgets.showSnack(context,
            "Erreur lors de la mise à jour", color: AppColors.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar("Modifier mon profil"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 28),

          const Text("Vos coordonnées",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),

          _label("Prénom"),
          const SizedBox(height: 8),
          _buildField(_prenomController, "Kofi", Icons.person_rounded),
          const SizedBox(height: 16),

          _label("Nom"),
          const SizedBox(height: 8),
          _buildField(_nomController, "Mensah", Icons.person_outline_rounded),
          const SizedBox(height: 16),

          _label("Numéro de téléphone"),
          const SizedBox(height: 8),
          _buildField(_telController, "+228 90 00 00 00", Icons.phone_android_rounded,
              keyboard: TextInputType.phone),
          const SizedBox(height: 36),

          AppWidgets.primaryButton(
            label: "Sauvegarder les modifications",
            icon: Icons.save_rounded,
            onPressed: _sauvegarder,
            loading: _enChargement,
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
