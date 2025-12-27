enum BookingStatus { pending, confirmed, cancelled, completed }

enum PaymentMethod { card, paypal, mtn }

class Booking {
  final String id;
  final String accommodationId;
  final String userId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String currency;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final bool payInTwo;
  final String? socialProjectId;
  final double? socialProjectContribution;
  final List<String> selectedRituals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.accommodationId,
    required this.userId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.payInTwo = false,
    this.socialProjectId,
    this.socialProjectContribution,
    this.selectedRituals = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      accommodationId: json['accommodation_id'] as String,
      userId: json['user_id'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      guests: json['guests'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'FCFA',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.card,
      ),
      payInTwo: json['pay_in_two'] as bool? ?? false,
      socialProjectId: json['social_project_id'] as String?,
      socialProjectContribution: (json['social_contribution'] as num?)
          ?.toDouble(),
      selectedRituals:
          (json['selected_rituals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accommodation_id': accommodationId,
      'user_id': userId,
      'check_in': checkIn.toIso8601String().split('T')[0],
      'check_out': checkOut.toIso8601String().split('T')[0],
      'guests': guests,
      'total_price': totalPrice,
      'currency': currency,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'pay_in_two': payInTwo,
      'social_project_id': socialProjectId,
      'social_contribution': socialProjectContribution,
      'selected_rituals': selectedRituals,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  Booking copyWith({
    String? id,
    String? accommodationId,
    String? userId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? totalPrice,
    String? currency,
    BookingStatus? status,
    PaymentMethod? paymentMethod,
    bool? payInTwo,
    String? socialProjectId,
    double? socialProjectContribution,
    List<String>? selectedRituals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      accommodationId: accommodationId ?? this.accommodationId,
      userId: userId ?? this.userId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payInTwo: payInTwo ?? this.payInTwo,
      socialProjectId: socialProjectId ?? this.socialProjectId,
      socialProjectContribution:
          socialProjectContribution ?? this.socialProjectContribution,
      selectedRituals: selectedRituals ?? this.selectedRituals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SocialProject {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final double contributionPercentage;

  SocialProject({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.contributionPercentage,
  });

  factory SocialProject.fromJson(Map<String, dynamic> json) {
    return SocialProject(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      icon: json['icon'] as String? ?? '',
      contributionPercentage:
          (json['contribution_percentage'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'contribution_percentage': contributionPercentage,
    };
  }
}
