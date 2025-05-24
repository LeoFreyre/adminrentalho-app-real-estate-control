class Apartment {
  final Location location;
  final String timeZone;
  final Rooms rooms;
  final List<String> equipments;
  final String currency;
  final Price price;
  final ApartmentType type;

  Apartment({
    required this.location,
    required this.timeZone,
    required this.rooms,
    required this.equipments,
    required this.currency,
    required this.price,
    required this.type,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      location: Location.fromJson(json['location']),
      timeZone: json['timeZone'] ?? '',
      rooms: Rooms.fromJson(json['rooms']),
      equipments: List<String>.from(json['equipments'] ?? []),
      currency: json['currency'],
      price: Price.fromJson(json['price']),
      type: ApartmentType.fromJson(json['type']),
    );
  }
}

class Location {
  final String street;
  final String zip;
  final String city;
  final String country;
  final String latitude;
  final String longitude;

  Location({
    required this.street,
    required this.zip,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      street: json['street'],
      zip: json['zip'],
      city: json['city'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

class Rooms {
  final int maxOccupancy;
  final int bedrooms;
  final int bathrooms;
  final int doubleBeds;
  final int singleBeds;
  final int? sofaBeds;
  final int? couches;
  final int? childBeds;
  final int? queenSizeBeds;
  final int? kingSizeBeds;

  Rooms({
    required this.maxOccupancy,
    required this.bedrooms,
    required this.bathrooms,
    required this.doubleBeds,
    required this.singleBeds,
    this.sofaBeds,
    this.couches,
    this.childBeds,
    this.queenSizeBeds,
    this.kingSizeBeds,
  });

  factory Rooms.fromJson(Map<String, dynamic> json) {
    return Rooms(
      maxOccupancy: json['maxOccupancy'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      doubleBeds: json['doubleBeds'],
      singleBeds: json['singleBeds'],
      sofaBeds: json['sofaBeds'],
      couches: json['couches'],
      childBeds: json['childBeds'],
      queenSizeBeds: json['queenSizeBeds'],
      kingSizeBeds: json['kingSizeBeds'],
    );
  }
}

class Price {
  final String minimal;
  final String maximal;

  Price({
    required this.minimal,
    required this.maximal,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      minimal: json['minimal'],
      maximal: json['maximal'],
    );
  }
}

class ApartmentType {
  final int id;
  final String name;

  ApartmentType({
    required this.id,
    required this.name,
  });

  factory ApartmentType.fromJson(Map<String, dynamic> json) {
    return ApartmentType(
      id: json['id'],
      name: json['name'],
    );
  }
}
