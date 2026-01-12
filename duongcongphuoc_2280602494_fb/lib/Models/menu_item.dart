class MenuItem {
  final int? id;
  int menuId;
  String name;
  String? category;
  String? description;
  int quantity;
  double? unitPrice;
  double? totalPrice;
  String? notes;
  int displayOrder;
  bool isHidden;

  MenuItem({
    this.id,
    required this.menuId,
    required this.name,
    this.category,
    this.description,
    this.quantity = 0,
    this.unitPrice,
    this.totalPrice,
    this.notes,
    this.displayOrder = 0,
    this.isHidden = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return MenuItem(
      id: json['id'],
      menuId: json['menuId'],
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      unitPrice: _toDouble(json['unitPrice']),
      totalPrice: _toDouble(json['totalPrice']),
      notes: json['notes'],
      displayOrder: json['displayOrder'] ?? 0,
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuId': menuId,
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
      'displayOrder': displayOrder,
      'isHidden': isHidden,
    };
  }
}

