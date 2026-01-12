class EventTimeline {
  final int id;
  final int eventId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? description;
  final int? vendorId;
  final String? personInCharge;
  final int displayOrder;
  final String status;
  final bool isHidden;

  EventTimeline({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.location,
    this.description,
    this.vendorId,
    this.personInCharge,
    this.displayOrder = 0,
    this.status = 'Pending',
    this.isHidden = false,
  });

  factory EventTimeline.fromJson(Map<String, dynamic> json) {
    return EventTimeline(
      id: json['id'] ?? 0,
      eventId: json['eventId'] ?? 0,
      title: json['title'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      location: json['location'],
      description: json['description'],
      vendorId: json['vendorId'],
      personInCharge: json['personInCharge'],
      displayOrder: json['displayOrder'] ?? 0,
      status: json['status'] ?? 'Pending',
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'description': description,
      'vendorId': vendorId,
      'personInCharge': personInCharge,
      'displayOrder': displayOrder,
      'status': status,
      'isHidden': isHidden,
    };
  }
}
