class Guest {
  final int id;
  final int eventId;
  final String fullName;
  final String? email;
  final String? phone;
  final String guestType;
  final String rsvpStatus;
  final int plusOneCount;
  final int? tableNumber;
  final String? dietaryRequirements;
  final String? notes;
  final bool giftReceived;
  final String? giftDescription;

  Guest({
    required this.id,
    required this.eventId,
    required this.fullName,
    this.email,
    this.phone,
    this.guestType = 'Other',
    this.rsvpStatus = 'Pending',
    this.plusOneCount = 0,
    this.tableNumber,
    this.dietaryRequirements,
    this.notes,
    this.giftReceived = false,
    this.giftDescription,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] ?? 0,
      eventId: json['eventId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      guestType: json['guestType'] ?? 'Other',
      rsvpStatus: json['rsvpStatus'] ?? 'Pending',
      plusOneCount: json['plusOneCount'] ?? 0,
      tableNumber: json['tableNumber'],
      dietaryRequirements: json['dietaryRequirements'],
      notes: json['notes'],
      giftReceived: json['giftReceived'] ?? false,
      giftDescription: json['giftDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'guestType': guestType,
      'rsvpStatus': rsvpStatus,
      'plusOneCount': plusOneCount,
      'tableNumber': tableNumber,
      'dietaryRequirements': dietaryRequirements,
      'notes': notes,
      'giftReceived': giftReceived,
      'giftDescription': giftDescription,
    };
  }
}
