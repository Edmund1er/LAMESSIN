import 'package:flutter/material.dart';
import 'package:lamessin_flutter/MODELS_/utilisateur_model.dart';
import '../../SERVICES_/patient_service.dart';
import '../../MODELS_/message_model.dart';
import '../../THEME_/app_theme.dart';
import 'AssistantHistoriquePage.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  static const Color _brandColor = Color(0xFF00ACC1);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  int _selectedIndex = 3;

  final String _imageFond = "assets/images/fond_patient.jpg";

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
    final historique = await PatientService.getHistoriqueAssistant();
    if (mounted) {
      setState(() {
        for (var msg in historique) {
          _messages.add({
            'role': msg.envoyeParUtilisateur ? 'user' : 'bot',
            'text': msg.contenuTexte,
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

    final response = await PatientService.envoyerMessageIAMedical(texte);
    
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text': response ?? "Desole, je n'ai pas pu traiter votre demande. Veuillez reessayer.",
        });
      });
      _scrollToBottom();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      return;
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Assistant LAMESSIN", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text("En ligne", style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/historique_chatbot'),
          ),
        ],
        centerTitle: false,
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
                : Column(
                    children: [
                      Expanded(
                        child: _messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length + (_isTyping ? 1 : 0),
                                itemBuilder: (_, index) {
                                  if (_isTyping && index == _messages.length) return _buildTyping();
                                  final msg = _messages[index];
                                  return _buildBulle(msg['text'], msg['role'] == 'user');
                                },
                              ),
                      ),
                      _buildSaisie(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.smart_toy_rounded, size: 36, color: _brandColor),
          ),
          const SizedBox(height: 16),
          const Text("Bonjour !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 6),
          const Text("Comment puis-je vous aider\ aujourd'hui ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ["Symptomes fievre", "Prendre un RDV", "Trouver une pharmacie", "Urgences medicales"]
                .map((s) => GestureDetector(
                      onTap: () {
                        _controller.text = s;
                        _envoyerMessage();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _brandColor, width: 1.5)),
                        child: Text(s, style: TextStyle(color: _brandColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBulle(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? _brandColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: isUser ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _brandColor.withOpacity(0.3 + i * 0.3), shape: BoxShape.circle),
          )),
        ),
      ),
    );
  }

  Widget _buildSaisie() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: Colors.grey))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[300]!)),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: "Decrivez vos symptomes...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => _envoyerMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _envoyerMessage,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, currentIndex),
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, currentIndex),
              _navItem(Icons.calendar_month_rounded, "RDV", 2, currentIndex),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, currentIndex),
              _navItem(Icons.person_rounded, "Profil", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: () => _onItemTapped(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}