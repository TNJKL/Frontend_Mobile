class EventCategory {
  int? id;
  String? name;
  String? color;
  String? description;
  bool isHidden;

  EventCategory({
    this.id,
    this.name,
    this.color,
    this.description,
    this.isHidden = false,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      description: json['description'],
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'color': color,
      'description': description,
      'isHidden': isHidden,
    };
    
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }
}

