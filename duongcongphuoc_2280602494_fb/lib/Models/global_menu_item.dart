class GlobalMenuItem {
  final int? id;
  String name;
  String? category;
  String? description;
  double? unitPrice;
  double? totalPrice;
  String? notes;
  String? imageUrl;
  int displayOrder;
  bool isHidden;

  GlobalMenuItem({
    this.id,
    required this.name,
    this.category,
    this.description,
    this.unitPrice,
    this.totalPrice,
    this.notes,
    this.imageUrl,
    this.displayOrder = 0,
    this.isHidden = false,
  });

  factory GlobalMenuItem.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return GlobalMenuItem(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      unitPrice: _toDouble(json['unitPrice']),
      totalPrice: _toDouble(json['totalPrice']),
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isHidden': isHidden,
    };
  }
}
