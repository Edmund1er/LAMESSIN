import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class AssistantHistoriquePage extends StatefulWidget {
  const AssistantHistoriquePage({super.key});

  @override
  State<AssistantHistoriquePage> createState() => _AssistantHistoriquePageState();
}

class _AssistantHistoriquePageState extends State<AssistantHistoriquePage> {
  bool _isLoading = true;
  List<dynamic> _historique = [];

  @override
  void initState() {
    super.initState();
    _chargerData();
  }

  Future<void> _chargerData() async {
    final data = await ApiService.getHistoriqueAssistant();
    setState(() {
      _historique = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon Historique Santé")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _historique.length,
            itemBuilder: (context, index) {
              final msg = _historique[index];
              bool isUser = msg['envoye_par_utilisateur'];
              return ListTile(
                title: Text(isUser ? "Moi" : "Assistant"),
                subtitle: Text(msg['contenu_texte']),
                leading: Icon(isUser ? Icons.person : Icons.medical_services, 
                              color: isUser ? Colors.blue : Colors.teal),
              );
            },
          ),
    );
  }
}