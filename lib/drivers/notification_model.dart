class NotificationModel {
  final int id;
  final int tripId; // Trip ID to link the notification with a specific trip
  final int passengerId; // Passenger ID related to the notification
  final String message;
  final String timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int, // Ensure ID is an integer
      tripId: json['trip_id'] as int, // Trip ID from the JSON
      passengerId: json['passenger_id'] as int, // Passenger ID from the JSON
      message: json['message'] as String, // Message as String
      timestamp: json['created_at'] as String, // Ensure this is a String
      isRead: json['status'] == 'Confirmed', // Convert status to a bool based on some condition
    );
  }
}
