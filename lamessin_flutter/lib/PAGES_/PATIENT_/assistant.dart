import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/message_model.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _chargerHistorique() async {
    final historique = await ApiService.getHistoriqueAssistant();
    if (mounted) {
      setState(() {
        for (var msg in historique) {
          _messages.add({
            'role': msg.envoyeParUtilisateur ? 'user' : 'bot',
            'text': msg.contenuTexte // <--- UTILISE .contenuTexte
          });
        }
        _isLoading = false;
      });
      _scrollToBottom();
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
    _scrollToBottom();

    final response = await ApiService.envoyerMessageAssistant(texte);

    if (mounted) {
      setState(() {
        _isTyping = false;
        if (response != null) {
          _messages.add({
            'role': 'bot', 
            'text': response.contenuTexte // <--- UTILISE .contenuTexte
          });
        }
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("Assistant Santé")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg['text'], msg['role'] == 'user');
                  },
                ),
              ),
              if (_isTyping) const LinearProgressIndicator(color: Colors.teal),
              _buildInputArea(),
            ],
          ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal[600] : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Décrivez vos symptômes..."),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _envoyerMessage),
        ],
      ),
    );
  }
}