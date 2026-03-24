class Message {
  final int id;
  final int chatbotAssocieId;
  final String contenuTexte;
  final bool envoyeParUtilisateur;
  final String heureMessage;

  Message({
    required this.id, 
    required this.chatbotAssocieId,
    required this.contenuTexte, 
    required this.envoyeParUtilisateur, 
    required this.heureMessage
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatbotAssocieId: json['chatbot_associe'] ?? 0,
      contenuTexte: json['contenu_texte'] ?? '',
      envoyeParUtilisateur: json['envoye_par_utilisateur'] ?? false,
      heureMessage: json['heure_message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'chatbot_associe': chatbotAssocieId,
    'contenu_texte': contenuTexte,
    'envoye_par_utilisateur': envoyeParUtilisateur,
  };
}