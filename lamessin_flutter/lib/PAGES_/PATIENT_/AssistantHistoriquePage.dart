import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/message_model.dart';

class AssistantHistoriquePage extends StatefulWidget {
  const AssistantHistoriquePage({super.key});

  @override
  State<AssistantHistoriquePage> createState() => _AssistantHistoriquePageState();
}

class _AssistantHistoriquePageState extends State<AssistantHistoriquePage> {
  bool _isLoading = true;
  List<Message> _historique = [];

  final Color couleurRose = const Color(0xFFF96AD5);
  final Color couleurBleue = const Color(0xFF1A73E8);

  @override
  void initState() {
    super.initState();
    _chargerData();
  }

  Future<void> _chargerData() async {
    final data = await ApiService.getHistoriqueAssistant();
    if (mounted) {
      setState(() {
        _historique = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Historique Santé"),
        backgroundColor: couleurRose,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: couleurRose))
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _historique.length,
            itemBuilder: (context, index) {
              final msg = _historique[index];
              return _buildChatBubble(
                text: msg.contenuTexte,
                isUser: msg.envoyeParUtilisateur,
                date: msg.heureMessage // <--- CORRIGÉ ICI
              );
            },
          ),
    );
  }

  Widget _buildChatBubble({required String text, required bool isUser, required String date}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? couleurBleue : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
            const SizedBox(height: 5),
            Text(date, style: TextStyle(color: isUser ? Colors.white70 : Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}