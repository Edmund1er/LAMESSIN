import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart';
import '../../MODELS_/message_model.dart';
import '../../THEME_/app_theme.dart';

class AssistantHistoriquePage extends StatefulWidget {
  const AssistantHistoriquePage({super.key});
  @override
  State<AssistantHistoriquePage> createState() => _AssistantHistoriquePageState();
}

class _AssistantHistoriquePageState extends State<AssistantHistoriquePage> {
  bool _isLoading = true;
  List<Message> _historique = [];

  @override
  void initState() { super.initState(); _chargerData(); }

  Future<void> _chargerData() async {
    final data = await PatientService.getHistoriqueAssistant();
    if (mounted) setState(() { _historique = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar("Historique des échanges"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _historique.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historique.length,
                  itemBuilder: (_, index) {
                    final msg = _historique[index];
                    return _buildBulle(
                        text: msg.contenuTexte,
                        isUser: msg.envoyeParUtilisateur,
                        date: msg.heureMessage);
                  },
                ),
    );
  }

  Widget _buildBulle({required String text, required bool isUser, required String date}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(
              color: isUser ? Colors.white : AppColors.textPrimary,
              fontSize: 14, height: 1.5)),
          const SizedBox(height: 6),
          Text(date, style: TextStyle(
              color: isUser ? Colors.white60 : AppColors.textSecondary,
              fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.history_rounded, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text("Aucun échange enregistré",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]),
    );
  }
}
