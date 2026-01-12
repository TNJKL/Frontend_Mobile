import 'service_package_item.dart';

class ServicePackage {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final List<ServicePackageItem> servicePackageItems;

  ServicePackage({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isActive,
    required this.servicePackageItems,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      isActive: json['isActive'],
      servicePackageItems: (json['servicePackageItems'] as List<dynamic>?)
              ?.map((item) => ServicePackageItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'servicePackageItems': servicePackageItems.map((item) => item.toJson()).toList(),
    };
  }
}
