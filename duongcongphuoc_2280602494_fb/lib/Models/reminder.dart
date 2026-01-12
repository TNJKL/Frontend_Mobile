import 'dart:convert';
import 'event.dart';

class Reminder {
  int? id;
  int eventId;
  Event? event;
  DateTime reminderTime;
  String? message;
  bool isNotified;
  DateTime createdAt;

  Reminder({
    this.id,
    required this.eventId,
    this.event,
    required this.reminderTime,
    this.message,
    this.isNotified = false,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      eventId: json['eventId'],
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      reminderTime: DateTime.parse(json['reminderTime']),
      message: json['message'],
      isNotified: json['isNotified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'eventId': eventId,
      'reminderTime': reminderTime.toIso8601String(),
      'message': message,
      'isNotified': isNotified,
    };
    
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }
}

