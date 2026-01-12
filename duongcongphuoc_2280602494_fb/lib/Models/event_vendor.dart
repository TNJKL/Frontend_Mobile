import 'vendor.dart';

class EventVendor {
  final int id;
  final int eventId;
  final int vendorId;
  final Vendor? vendor;
  final String? serviceDescription;
  final double? contractAmount;
  final double? depositAmount;
  final double? balanceAmount;
  final DateTime? contractDate;
  final DateTime? serviceDate;
  final String status;
  final String? notes;

  EventVendor({
    required this.id,
    required this.eventId,
    required this.vendorId,
    this.vendor,
    this.serviceDescription,
    this.contractAmount,
    this.depositAmount,
    this.balanceAmount,
    this.contractDate,
    this.serviceDate,
    required this.status,
    this.notes,
  });

  factory EventVendor.fromJson(Map<String, dynamic> json) {
    return EventVendor(
      id: json['id'],
      eventId: json['eventId'],
      vendorId: json['vendorId'],
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
      serviceDescription: json['serviceDescription'],
      contractAmount: json['contractAmount'] != null ? (json['contractAmount'] as num).toDouble() : null,
      depositAmount: json['depositAmount'] != null ? (json['depositAmount'] as num).toDouble() : null,
      balanceAmount: json['balanceAmount'] != null ? (json['balanceAmount'] as num).toDouble() : null,
      contractDate: json['contractDate'] != null ? DateTime.parse(json['contractDate']) : null,
      serviceDate: json['serviceDate'] != null ? DateTime.parse(json['serviceDate']) : null,
      status: json['status'] ?? 'Pending',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'vendorId': vendorId,
      'serviceDescription': serviceDescription,
      'contractAmount': contractAmount,
      'depositAmount': depositAmount,
      'balanceAmount': balanceAmount,
      'contractDate': contractDate?.toIso8601String(),
      'serviceDate': serviceDate?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
