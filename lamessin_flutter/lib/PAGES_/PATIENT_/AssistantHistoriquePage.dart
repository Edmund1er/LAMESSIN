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
  static const Color _brandColor = Color(0xFF00ACC1);

  bool _isLoading = true;
  List<Message> _historique = [];
  String? _errorMessage;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    _chargerData();
  }

  Future<void> _chargerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await PatientService.getHistoriqueAssistant();
      debugPrint("Historique recu: ${data.length} messages");
      if (mounted) {
        setState(() {
          _historique = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement historique: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de chargement: $e";
          _isLoading = false;
        });
      }
    }
  }

  String _formaterDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Historique des echanges", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _chargerData,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _chargerData,
                              style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
                              child: const Text("Reessayer"),
                            ),
                          ],
                        ),
                      )
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
                                date: _formaterDate(msg.heureMessage),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulle({required String text, required bool isUser, required String date}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? _brandColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: isUser ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.5)),
          const SizedBox(height: 6),
          Text(date, style: TextStyle(color: isUser ? Colors.white70 : Colors.grey, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.history_rounded, size: 36, color: _brandColor),
        ),
        const SizedBox(height: 16),
        const Text("Aucun echange enregistre", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 8),
        const Text("Envoyez un message dans l'assistant", style: TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    );
  }
}