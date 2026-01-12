import 'menu_item.dart';

class Menu {
  final int? id;
  final int eventId;
  String mealType;
  String name;
  String? description;
  List<MenuItem> menuItems;

  Menu({
    this.id,
    required this.eventId,
    required this.mealType,
    required this.name,
    this.description,
    List<MenuItem>? menuItems,
  }) : menuItems = menuItems ?? [];

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      eventId: json['eventId'],
      mealType: json['mealType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      menuItems: (json['menuItems'] as List?)
              ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'mealType': mealType,
      'name': name,
      'description': description,
      'menuItems': menuItems.map((e) => e.toJson()).toList(),
    };
  }
}

