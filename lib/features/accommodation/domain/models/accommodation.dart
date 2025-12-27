class Accommodation {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final String hostName;
  final String hostPhoto;
  final List<String> photos;
  final double pricePerNight;
  final String currency;
  final AccommodationLocation location;
  final int maxGuests;
  final int bedrooms;
  final int beds;
  final int bathrooms;
  final List<String> amenities;
  final List<String> languages;
  final List<Ritual> rituals;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Accommodation({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.hostPhoto,
    required this.photos,
    required this.pricePerNight,
    required this.currency,
    required this.location,
    required this.maxGuests,
    required this.bedrooms,
    required this.beds,
    required this.bathrooms,
    required this.amenities,
    required this.languages,
    required this.rituals,
    required this.rating,
    required this.reviewCount,
    this.isFavorite = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      hostId: json['host_id'] as String,
      hostName: json['host']?['full_name'] as String? ?? '',
      hostPhoto: json['host']?['photo_url'] as String? ?? '',
      photos:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'FCFA',
      location: AccommodationLocation.fromJson({
        'address': json['address'] ?? '',
        'city': json['city'] ?? '',
        'country': json['country'] ?? 'Bénin',
        'latitude': json['latitude'] ?? 0.0,
        'longitude': json['longitude'] ?? 0.0,
      }),
      maxGuests: json['max_guests'] as int? ?? 1,
      bedrooms: json['bedrooms'] as int? ?? 1,
      beds: json['beds'] as int? ?? 1,
      bathrooms: json['bathrooms'] as int? ?? 1,
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rituals:
          (json['rituals'] as List<dynamic>?)
              ?.map((e) => Ritual.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'host_id': hostId,
      'images': photos,
      'price_per_night': pricePerNight,
      'currency': currency,
      'address': location.address,
      'city': location.city,
      'country': location.country,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'max_guests': maxGuests,
      'bedrooms': bedrooms,
      'beds': beds,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'languages': languages,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Accommodation copyWith({
    String? id,
    String? title,
    String? description,
    String? hostId,
    String? hostName,
    String? hostPhoto,
    List<String>? photos,
    double? pricePerNight,
    String? currency,
    AccommodationLocation? location,
    int? maxGuests,
    int? bedrooms,
    int? beds,
    int? bathrooms,
    List<String>? amenities,
    List<String>? languages,
    List<Ritual>? rituals,
    double? rating,
    int? reviewCount,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Accommodation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhoto: hostPhoto ?? this.hostPhoto,
      photos: photos ?? this.photos,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      maxGuests: maxGuests ?? this.maxGuests,
      bedrooms: bedrooms ?? this.bedrooms,
      beds: beds ?? this.beds,
      bathrooms: bathrooms ?? this.bathrooms,
      amenities: amenities ?? this.amenities,
      languages: languages ?? this.languages,
      rituals: rituals ?? this.rituals,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AccommodationLocation {
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  AccommodationLocation({
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory AccommodationLocation.fromJson(Map<String, dynamic> json) {
    return AccommodationLocation(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? 'Bénin',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Ritual {
  final String id;
  final String name;
  final String description;
  final String divinity;
  final String divinityIcon;
  final String photo;
  final int durationMinutes;
  final String significance;
  final List<String> precautions;
  final bool isAvailable;

  Ritual({
    required this.id,
    required this.name,
    required this.description,
    required this.divinity,
    required this.divinityIcon,
    required this.photo,
    required this.durationMinutes,
    required this.significance,
    required this.precautions,
    this.isAvailable = true,
  });

  factory Ritual.fromJson(Map<String, dynamic> json) {
    return Ritual(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      divinity: json['deity'] as String? ?? '',
      divinityIcon: json['deity_icon'] as String? ?? '',
      photo: json['image_url'] as String? ?? '',
      durationMinutes: json['duration'] as int? ?? 60,
      significance: json['significance'] as String? ?? '',
      precautions:
          (json['precautions'] as String?)
              ?.split(',')
              .map((e) => e.trim())
              .toList() ??
          [],
      isAvailable: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'deity': divinity,
      'deity_icon': divinityIcon,
      'image_url': photo,
      'duration': durationMinutes,
      'significance': significance,
      'precautions': precautions.join(', '),
      'is_active': isAvailable,
    };
  }
}
