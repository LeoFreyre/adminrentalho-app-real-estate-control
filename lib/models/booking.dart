class Apartment {
  final int id;
  final String name;

  Apartment({required this.id, required this.name});

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Booking {
  final int id;
  final String guestName;
  final String email;
  final String arrival;
  final String departure;
  final Apartment apartment;

  Booking({
    required this.id,
    required this.guestName,
    required this.email,
    required this.arrival,
    required this.departure,
    required this.apartment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      guestName: json['guest-name'],
      email: json['email'],
      arrival: json['arrival'],
      departure: json['departure'],
      apartment: Apartment.fromJson(json['apartment']),
    );
  }
}
