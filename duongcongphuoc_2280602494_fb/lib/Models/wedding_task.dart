class WeddingTask {
  final int id;
  final int eventId;
  String title;
  String? description;
  String? assignedToUserId; // ID user được phân công
  String category;
  String priority; // High, Normal, Low
  String status; // Pending, InProgress, Completed, Cancelled
  DateTime? dueDate;
  DateTime? completedDate;
  DateTime? reminderDate;
  
  WeddingTask({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    this.assignedToUserId,
    this.category = "General",
    this.priority = "Normal",
    this.status = "Pending",
    this.dueDate,
    this.completedDate,
    this.reminderDate,
  });

  factory WeddingTask.fromJson(Map<String, dynamic> json) {
    return WeddingTask(
      id: json['id'] ?? 0,
      eventId: json['eventId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      assignedToUserId: json['assignedToUserId'],
      category: json['category'] ?? "General",
      priority: json['priority'] ?? "Normal",
      status: json['status'] ?? "Pending",
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      reminderDate: json['reminderDate'] != null ? DateTime.parse(json['reminderDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'assignedToUserId': assignedToUserId,
      'category': category,
      'priority': priority,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
    };
  }
}
