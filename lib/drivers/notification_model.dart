class NotificationModel {
  final int id;
  final int tripId;
  final int passengerId;
  final String passengerName; // New field for passenger's name
  final String passengerPhone; // New field for passenger's phone
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
      id: json['id'] as int,
      tripId: json['trip_id'] as int,
      passengerId: json['passenger_id'] as int,
      passengerName: json['passenger_name'] as String, // Map passenger's name
      passengerPhone: json['passenger_phone'] as String, // Map passenger's phone
      departure: json['departure_location'] as String,
      destination: json['destination'] as String,
      message: json['message'] as String,
      timestamp: json['created_at'] as String,
      isRead: json['status'] == 'Confirmed',
    );
  }
}
