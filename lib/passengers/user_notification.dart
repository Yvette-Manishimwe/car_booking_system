class NotificationModel {
  final int id;
  final int driverId;
  final int passengerId;
  final int tripId;
  final String message;
  final String status; // This can also be an enum if needed
  final DateTime createdAt; // Use DateTime for proper date handling
  bool isRead; // Determine this based on your logic

  NotificationModel({
    required this.id,
    required this.driverId,
    required this.passengerId,
    required this.tripId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.isRead = false,
  });

  // From JSON factory method
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      driverId: json['driver_id'],
      passengerId: json['passenger_id'],
      tripId: json['trip_id'],
      message: json['message'] ?? "No message available", // Default value for null
      status: json['status'] ?? "Unknown", // Default value for null
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Getter for timestamp
  DateTime get timestamp => createdAt;
}
