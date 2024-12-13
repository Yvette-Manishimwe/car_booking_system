class NotificationModel {
  final int id;
  final int tripId;
  final int passengerId;
  final String passengerName;
  final String passengerPhone;
  final String message;
  final String timestamp;
  final String departure;
  final String destination;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.message,
    required this.timestamp,
    required this.departure,
    required this.destination,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] != null ? json['id'] as int : 0,
      tripId: json['trip_id'] != null ? json['trip_id'] as int : 0,
      passengerId: json['passenger_id'] != null ? json['passenger_id'] as int : 0,
      passengerName: json['passenger_name'] ?? 'Unknown Passenger',
      passengerPhone: json['passenger_phone'] ?? 'Unknown Phone',
      departure: json['departure_location'] ?? 'Unknown Location',
      destination: json['destination'] ?? 'Unknown Destination',
      message: json['message'] ?? 'No message available',
      timestamp: json['created_at'] ?? 'Unknown time',
      isRead: json['status'] == 'Sent', // Assuming 'Sent' indicates the message is read
    );
  }
}
