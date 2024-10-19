class Passenger {
  final int id;
  final String name;

  Passenger({required this.id, required this.name});

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      name: json['name'],
    );
  }
}
