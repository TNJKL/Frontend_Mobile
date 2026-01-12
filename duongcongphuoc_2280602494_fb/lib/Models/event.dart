import 'dart:convert';
import 'event_category.dart';

class Event {
  int? id;
  String? title;
  String? description;
  DateTime startTime;
  DateTime? endTime;
  String? location;
  int? eventCategoryId;
  EventCategory? eventCategory;
  String? userId;
  bool isHidden;
  DateTime createdAt;
  DateTime? updatedAt;
  String? creatorName;
  String? creatorRole;
  
  // Thông tin sự kiện cưới
  String? brideName;
  String? groomName;
  String status;
  int guestCount;
  double? budget;
  String? imageUrl;

  Event({
    this.id,
    this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.eventCategoryId,
    this.eventCategory,
    this.userId,
    this.isHidden = false,
    required this.createdAt,
    this.updatedAt,
    this.creatorName,
    this.creatorRole,
    this.brideName,
    this.groomName,
    this.status = 'Planning',
    this.guestCount = 0,
    this.budget,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      location: json['location'],
      eventCategoryId: json['eventCategoryId'],
      eventCategory: json['eventCategory'] != null
          ? EventCategory.fromJson(json['eventCategory'])
          : null,
      userId: json['userId'],
      isHidden: json['isHidden'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      creatorName: json['creatorName'],
      creatorRole: json['creatorRole'],
      brideName: json['brideName'],
      groomName: json['groomName'],
      status: json['status'] ?? 'Planning',
      guestCount: json['guestCount'] ?? 0,
      budget: json['budget'] != null ? (json['budget'] is int ? json['budget'].toDouble() : json['budget']) : null,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'eventCategoryId': eventCategoryId,
      'isHidden': isHidden,
      'brideName': brideName,
      'groomName': groomName,
      'status': status,
      'guestCount': guestCount,
      'budget': budget,
      'imageUrl': imageUrl,
    };
    
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }
}

