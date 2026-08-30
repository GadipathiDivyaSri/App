class Habit {
  final String id;
  String title;
  String frequency;
  bool isCompleted;
  int streakDay;
  List<String> completionHistory; // List of 'yyyy-MM-dd' dates

  Habit({
    required this.id,
    required this.title,
    this.frequency = 'DAILY',
    this.isCompleted = false,
    this.streakDay = 0,
    List<String>? completionHistory,
  }) : completionHistory = completionHistory ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'frequency': frequency,
        'isCompleted': isCompleted,
        'streakDay': streakDay,
        'completionHistory': completionHistory,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] ?? 'h_1',
        title: json['title'] ?? '',
        frequency: json['frequency'] ?? 'DAILY',
        isCompleted: json['isCompleted'] ?? false,
        streakDay: json['streakDay'] ?? 0,
        completionHistory: (json['completionHistory'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class Task {
  final String id;
  String title;
  String category; // 'Career Roadmap', 'Studies', 'Personal Growth'
  String tag; // 'STUDY', 'EXAM', 'WORK', 'PLANNING', 'PERSONAL'
  String dueDateLabel; // 'Today', 'Tomorrow', 'Completed', etc.
  DateTime dueDate;
  String dueTime;
  int priority; // 1 = High / Urgent, 2 = Medium / Schedule, 3 = Low / Delegate
  bool isCompleted;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.tag = 'STUDY',
    required this.dueDateLabel,
    required this.dueDate,
    this.dueTime = '05:00 PM',
    this.priority = 1,
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'tag': tag,
        'dueDateLabel': dueDateLabel,
        'dueDate': dueDate.toIso8601String(),
        'dueTime': dueTime,
        'priority': priority,
        'isCompleted': isCompleted,
        'completedDate': completedDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] ?? 't_1',
        title: json['title'] ?? 'Untitled Task',
        category: json['category'] ?? 'Studies',
        tag: json['tag'] ?? 'STUDY',
        dueDateLabel: json['dueDateLabel'] ?? 'Today',
        dueDate: json['dueDate'] != null
            ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
            : DateTime.now(),
        dueTime: json['dueTime'] ?? '05:00 PM',
        priority: json['priority'] != null ? int.tryParse(json['priority'].toString()) ?? 1 : 1,
        isCompleted: json['isCompleted'] ?? false,
        completedDate: json['completedDate'] != null
            ? DateTime.tryParse(json['completedDate'].toString())
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
  String category;
  bool isCompleted;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.location = 'Workspace A',
    this.type = 'Focus Session',
    this.category = 'General',
    this.isCompleted = false,
  });

  DateTime get date => startTime;
  String get time => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'location': location,
        'type': type,
        'category': category,
        'isCompleted': isCompleted,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] ?? 'ev_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Event',
        description: json['description'] ?? '',
        startTime: json['startTime'] != null
            ? (DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now())
            : DateTime.now(),
        endTime: json['endTime'] != null
            ? (DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1)))
            : DateTime.now().add(const Duration(hours: 1)),
        location: json['location'] ?? 'Workspace A',
        type: json['type'] ?? 'Focus Session',
        category: json['category'] ?? 'General',
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
        id: json['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Notification',
        header: json['header'] ?? 'Update',
        message: json['message'] ?? '',
        timestamp: json['timestamp'] != null
            ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
            : DateTime.now(),
        category: json['category'] ?? 'RECENT',
        colorHex: json['colorHex'] ?? 0xFF0D5CE5,
      );
}

class ExpenseTransaction {
  final String id;
  String title;
  String category;
  double amount;
  bool isIncome;
  DateTime date;
  String paymentMethod;

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.isIncome = false,
    required this.date,
    this.paymentMethod = 'UPI',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
      };

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) =>
      ExpenseTransaction(
        id: json['id'] ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Expense',
        category: json['category'] ?? 'General',
        amount: (json['amount'] is num)
            ? (json['amount'] as num).toDouble()
            : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        isIncome: json['isIncome'] ?? false,
        date: json['date'] != null
            ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
            : DateTime.now(),
        paymentMethod: json['paymentMethod'] ?? 'UPI',
      );
}

class ReferralActivity {
  final String id;
  final String name;
  final String status; // 'PENDING', 'QUALIFIED', 'USED'
  final String date;
  final int discountPercent;
  final bool isApplied;

  ReferralActivity({
    required this.id,
    required this.name,
    required this.status,
    required this.date,
    this.discountPercent = 10,
    this.isApplied = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'date': date,
        'discountPercent': discountPercent,
        'isApplied': isApplied,
      };

  factory ReferralActivity.fromJson(Map<String, dynamic> json) =>
      ReferralActivity(
        id: json['id'] ?? 'ref_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] ?? 'Friend',
        status: json['status'] ?? 'PENDING',
        date: json['date'] ?? 'Just now',
        discountPercent: json['discountPercent'] ?? 10,
        isApplied: json['isApplied'] ?? false,
      );
}

class JournalEntry {
  final String id;
  String title;
  String content;
  DateTime date;
  String mood; // 'Happy', 'Productive', 'Reflective', 'Calm', 'Stressed'
  List<String> tags;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood = 'Reflective',
    List<String>? tags,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'mood': mood,
        'tags': tags,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] ?? 'j_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Journal Entry',
        content: json['content'] ?? '',
        date: json['date'] != null
            ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
            : DateTime.now(),
        mood: json['mood'] ?? 'Reflective',
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class StudySubject {
  final String id;
  String name;
  String code;
  int colorHex;
  double progress; // 0.0 to 1.0
  List<String> topics;

  StudySubject({
    required this.id,
    required this.name,
    this.code = '',
    int? colorHex,
    int? colorValue,
    this.progress = 0.0,
    List<String>? topics,
  })  : colorHex = colorValue ?? colorHex ?? 0xFF0D5CE5,
        topics = topics ?? [];

  int get colorValue => colorHex;
  set colorValue(int val) => colorHex = val;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'colorHex': colorHex,
        'progress': progress,
        'topics': topics,
      };

  factory StudySubject.fromJson(Map<String, dynamic> json) => StudySubject(
        id: json['id'] ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] ?? 'Subject',
        code: json['code'] ?? '',
        colorHex: json['colorHex'] != null
            ? int.tryParse(json['colorHex'].toString()) ?? 0xFF0D5CE5
            : 0xFF0D5CE5,
        progress: (json['progress'] is num)
            ? (json['progress'] as num).toDouble()
            : 0.0,
        topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class StudyItem {
  final String id;
  String subjectId;
  String subjectName;
  String title;
  String type; // 'TASK', 'ASSIGNMENT', 'EXAM'
  DateTime dueDate;
  bool isCompleted;

  StudyItem({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    this.type = 'TASK',
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'title': title,
        'type': type,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory StudyItem.fromJson(Map<String, dynamic> json) => StudyItem(
        id: json['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: json['subjectId'] ?? '',
        subjectName: json['subjectName'] ?? '',
        title: json['title'] ?? 'Task',
        type: json['type'] ?? 'TASK',
        dueDate: json['dueDate'] != null
            ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
            : DateTime.now(),
        isCompleted: json['isCompleted'] ?? false,
      );
}

class CareerRoadmapNode {
  final String id;
  String section; // 'GOAL', 'SKILLS', 'LEARNING', 'PROJECTS', 'EXPERIENCE', 'OPPORTUNITY'
  String title;
  String description;
  String status; // 'PLANNED', 'IN_PROGRESS', 'COMPLETED'
  int order;

  CareerRoadmapNode({
    required this.id,
    required this.section,
    required this.title,
    this.description = '',
    this.status = 'PLANNED',
    this.order = 0,
    bool? isCompleted,
  }) {
    if (isCompleted != null) {
      status = isCompleted ? 'COMPLETED' : 'PLANNED';
    }
  }

  bool get isCompleted => status == 'COMPLETED';
  set isCompleted(bool val) {
    status = val ? 'COMPLETED' : 'PLANNED';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        'title': title,
        'description': description,
        'status': status,
        'order': order,
      };

  factory CareerRoadmapNode.fromJson(Map<String, dynamic> json) =>
      CareerRoadmapNode(
        id: json['id'] ?? 'cr_${DateTime.now().millisecondsSinceEpoch}',
        section: json['section'] ?? 'SKILLS',
        title: json['title'] ?? 'Career Item',
        description: json['description'] ?? '',
        status: json['status'] ?? 'PLANNED',
        order: json['order'] != null ? int.tryParse(json['order'].toString()) ?? 0 : 0,
      );
}

class UserProfile {
  String id;
  String username;
  String email;
  String name;
  String contact;
  bool isEmailVerified;
  int focusScore;
  int activeStreak;
  bool isPremium;
  String subscriptionPlan;
  String? token;
  String referralCode;
  String? referredByCode;
  int successfulReferrals;
  int pendingReferrals;
  int activeDiscountPercent;

  UserProfile({
    this.id = 'u_1',
    this.username = 'alex_j',
    this.email = '',
    required this.name,
    this.contact = '',
    this.isEmailVerified = true,
    required this.focusScore,
    required this.activeStreak,
    this.isPremium = false,
    this.subscriptionPlan = 'FREE',
    this.token,
    this.referralCode = 'WRINDHA7K92',
    this.referredByCode,
    this.successfulReferrals = 0,
    this.pendingReferrals = 0,
    this.activeDiscountPercent = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'name': name,
        'contact': contact,
        'isEmailVerified': isEmailVerified,
        'focusScore': focusScore,
        'activeStreak': activeStreak,
        'isPremium': isPremium,
        'subscriptionPlan': subscriptionPlan,
        'token': token,
        'referralCode': referralCode,
        'referredByCode': referredByCode,
        'successfulReferrals': successfulReferrals,
        'pendingReferrals': pendingReferrals,
        'activeDiscountPercent': activeDiscountPercent,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? 'u_1',
        username: json['username'] ?? (json['name'] ?? 'user').toString().toLowerCase().replaceAll(' ', '_'),
        email: json['email'] ?? json['contact'] ?? '',
        name: json['name'] ?? 'Alex Johnson',
        contact: json['contact'] ?? json['email'] ?? '',
        isEmailVerified: json['isEmailVerified'] ?? true,
        focusScore: json['focusScore'] ?? 92,
        activeStreak: json['activeStreak'] ?? 14,
        isPremium: json['isPremium'] ?? false,
        subscriptionPlan: json['subscriptionPlan'] ?? (json['isPremium'] == true ? 'PREMIUM' : 'FREE'),
        token: json['token'],
        referralCode: json['referralCode'] ?? 'WRINDHA7K92',
        referredByCode: json['referredByCode'],
        successfulReferrals: json['successfulReferrals'] ?? 3,
        pendingReferrals: json['pendingReferrals'] ?? 1,
        activeDiscountPercent: json['activeDiscountPercent'] ?? 10,
      );
}
