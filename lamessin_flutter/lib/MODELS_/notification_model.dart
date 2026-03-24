class NotificationModel {
  final int id;
  final String? message;
  final String? heureEnvoi;
  final String? typeNotification;
  final bool lu;

  NotificationModel({
    required this.id, 
    required this.message, 
    required this.heureEnvoi, 
    required this.typeNotification,
    required this.lu,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'] ?? '',
      heureEnvoi: json['heure_envoi'] ?? '',
      typeNotification: json['type_notification'] ?? 'info',
      lu: json['lu'] ?? false,
    );
  }
}