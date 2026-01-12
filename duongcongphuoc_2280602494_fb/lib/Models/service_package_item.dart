class ServicePackageItem {
  final int id;
  final int servicePackageId;
  final String itemType; // 'Food', 'Service'
  final int? referenceId; // For Food (GlobalMenuItem Id)
  final String? customName; // For Service
  final double customValue;

  ServicePackageItem({
    required this.id,
    required this.servicePackageId,
    required this.itemType,
    this.referenceId,
    this.customName,
    required this.customValue,
  });

  factory ServicePackageItem.fromJson(Map<String, dynamic> json) {
    return ServicePackageItem(
      id: json['id'],
      servicePackageId: json['servicePackageId'],
      itemType: json['itemType'],
      referenceId: json['referenceId'],
      customName: json['globalMenuItem'] != null ? json['globalMenuItem']['name'] : json['customName'],
      customValue: (json['customValue'] as num).toDouble(),
      // Optional: store image url if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servicePackageId': servicePackageId,
      'itemType': itemType,
      'referenceId': referenceId,
      'customName': customName,
      'customValue': customValue,
    };
  }
}
