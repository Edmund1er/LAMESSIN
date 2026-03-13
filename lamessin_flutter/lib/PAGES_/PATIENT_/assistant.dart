import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true; // Pour afficher un loader au début

  @override
  void initState() {
    super.initState();
    _chargerHistorique(); // <--- On charge l'historique ici
  }

  Future<void> _chargerHistorique() async {
    final historique = await ApiService.getHistoriqueAssistant();
    if (mounted) {
      setState(() {
        for (var msg in historique) {
          _messages.add({
            'role': msg['envoye_par_utilisateur'] ? 'user' : 'bot',
            'text': msg['contenu_texte']
          });
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _envoyerMessage() async {
    String texte = _controller.text.trim();
    if (texte.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': texte});
      _isTyping = true;
    });
    _controller.clear();

    final response = await ApiService.envoyerMessageAssistant(texte);

    setState(() {
      _isTyping = false;
      if (response != null) {
        _messages.add({'role': 'bot', 'text': response['contenu_texte']});
      } else {
        _messages.add({'role': 'bot', 'text': "Oups ! Connexion perdue."});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Assistant IA Lamessin", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal[800],
        elevation: 0.5,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg['text'], msg['role'] == 'user');
                  },
                ),
              ),
              if (_isTyping) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator(color: Colors.teal, backgroundColor: Colors.transparent)),
              _buildInputArea(),
            ],
          ),
    );
  }

  // ... (Garde tes méthodes _buildChatBubble et _buildInputArea identiques)
  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal[600] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Posez votre question...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.teal[600],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _envoyerMessage,
            ),
          )
        ],
      ),
    );
  }
}