class Task {
  final String id;
  String title;
  String category; // 'Career Roadmap', 'Studies', 'Personal Growth'
  String dueDateLabel; // 'Today', 'Tomorrow', 'Completed', etc.
  DateTime dueDate;
  bool isCompleted;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDateLabel,
    required this.dueDate,
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'dueDateLabel': dueDateLabel,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'completedDate': completedDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        dueDateLabel: json['dueDateLabel'] ?? 'Today',
        dueDate: DateTime.parse(json['dueDate']),
        isCompleted: json['isCompleted'] ?? false,
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
      );
}

class CalendarEvent {
  final String id;
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  String location;
  String type; // 'Focus Session', 'Meeting', 'Task'
  bool isCompleted;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location = 'Workspace A',
    this.type = 'Focus Session',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'location': location,
        'type': type,
        'isCompleted': isCompleted,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        location: json['location'] ?? 'Workspace A',
        type: json['type'] ?? 'Focus Session',
        isCompleted: json['isCompleted'] ?? false,
      );
}

class AppNotification {
  final String id;
  String title;
  String header; // 'Approaching', 'Achieved', 'Completed', 'Ready'
  String message;
  DateTime timestamp;
  String category; // 'RECENT', 'ACTIVITY'
  int colorHex; // Highlight border color

  AppNotification({
    required this.id,
    required this.title,
    required this.header,
    required this.message,
    required this.timestamp,
    this.category = 'RECENT',
    this.colorHex = 0xFF0D5CE5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'header': header,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'colorHex': colorHex,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        header: json['header'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        category: json['category'] ?? 'RECENT',
        colorHex: json['colorHex'] ?? 0xFF0D5CE5,
      );
}

class UserProfile {
  String name;
  int focusScore;
  int activeStreak;
  bool isPremium;

  UserProfile({
    required this.name,
    required this.focusScore,
    required this.activeStreak,
    this.isPremium = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'focusScore': focusScore,
        'activeStreak': activeStreak,
        'isPremium': isPremium,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Alex Johnson',
        focusScore: json['focusScore'] ?? 92,
        activeStreak: json['activeStreak'] ?? 14,
        isPremium: json['isPremium'] ?? true,
      );
}
