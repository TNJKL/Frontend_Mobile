class Vendor {
  final int id;
  final String name;
  final String vendorType;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final double? rating;
  final String? notes;
  final bool isFavorite;

  Vendor({
    required this.id,
    required this.name,
    required this.vendorType,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.rating,
    this.notes,
    this.isFavorite = false,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      vendorType: json['vendorType'],
      contactPerson: json['contactPerson'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      website: json['website'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      notes: json['notes'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vendorType': vendorType,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'rating': rating,
      'notes': notes,
      'isFavorite': isFavorite,
    };
  }
}
