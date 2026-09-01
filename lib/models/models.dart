class Habit {
  final String id;
  String title;
  String category;
  String frequency; // 'DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM', 'WEEKLY'
  List<int> selectedDays; // 1 = Mon, 2 = Tue, ..., 7 = Sun
  String startDate; // 'yyyy-MM-dd'
  String status; // 'active', 'paused', 'archived'
  String description;
  int colorHex;
  String iconName;
  bool isCompleted;
  int streakDay;
  int longestStreak;
  int totalCompletions;
  List<String> completionHistory; // List of 'yyyy-MM-dd' dates

  Habit({
    required this.id,
    required this.title,
    this.category = 'General',
    this.frequency = 'DAILY',
    List<int>? selectedDays,
    String? startDate,
    this.status = 'active',
    this.description = '',
    this.colorHex = 0xFF10B981,
    this.iconName = 'repeat',
    this.isCompleted = false,
    this.streakDay = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    List<String>? completionHistory,
  })  : selectedDays = selectedDays ?? [],
        startDate = startDate ?? DateTime.now().toIso8601String().split('T')[0],
        completionHistory = completionHistory ?? [];

  bool isScheduledForDate(DateTime date) {
    if (status == 'archived' || status == 'paused') return false;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (dateStr.compareTo(startDate) < 0) return false;

    final weekday = date.weekday; // 1 = Mon, 7 = Sun
    final freq = frequency.toUpperCase();
    if (freq == 'DAILY') return true;
    if (freq == 'WEEKDAYS') return weekday >= 1 && weekday <= 5;
    if (freq == 'WEEKENDS') return weekday == 6 || weekday == 7;
    if (freq == 'CUSTOM') return selectedDays.contains(weekday);
    if (freq == 'WEEKLY') return weekday == 1;
    return true;
  }

  bool isCompletedOnDate(String dateStr) {
    return completionHistory.contains(dateStr);
  }

  void recalculateStreaks([DateTime? asOfDate]) {
    final today = asOfDate ?? DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final compSet = completionHistory.toSet();

    DateTime start = DateTime.tryParse(startDate) ?? today;
    if (completionHistory.isNotEmpty) {
      final sorted = List<String>.from(completionHistory)..sort();
      final earliest = DateTime.tryParse(sorted.first);
      if (earliest != null && earliest.isBefore(start)) {
        start = earliest;
      }
    }

    if (start.isAfter(today)) {
      streakDay = 0;
      longestStreak = 0;
      totalCompletions = compSet.length;
      isCompleted = compSet.contains(todayStr);
      return;
    }

    final scheduledDates = <String>[];
    DateTime cur = DateTime(start.year, start.month, start.day);
    final todayClean = DateTime(today.year, today.month, today.day);

    while (!cur.isAfter(todayClean)) {
      if (isScheduledForDate(cur)) {
        final dStr = '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
        scheduledDates.add(dStr);
      }
      cur = cur.add(const Duration(days: 1));
    }

    int maxStreak = 0;
    int running = 0;
    for (final dStr in scheduledDates) {
      if (compSet.contains(dStr)) {
        running++;
        if (running > maxStreak) maxStreak = running;
      } else {
        running = 0;
      }
    }

    int current = 0;
    if (scheduledDates.isNotEmpty) {
      int idx = scheduledDates.length - 1;
      final lastDate = scheduledDates[idx];

      if (lastDate == todayStr && compSet.contains(todayStr)) {
        while (idx >= 0 && compSet.contains(scheduledDates[idx])) {
          current++;
          idx--;
        }
      } else if (lastDate == todayStr && !compSet.contains(todayStr)) {
        idx--;
        while (idx >= 0 && compSet.contains(scheduledDates[idx])) {
          current++;
          idx--;
        }
      } else {
        while (idx >= 0 && compSet.contains(scheduledDates[idx])) {
          current++;
          idx--;
        }
      }
    }

    streakDay = current;
    longestStreak = maxStreak > current ? maxStreak : current;
    totalCompletions = compSet.length;
    isCompleted = compSet.contains(todayStr);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'frequency': frequency,
        'selectedDays': selectedDays,
        'startDate': startDate,
        'status': status,
        'description': description,
        'colorHex': colorHex,
        'iconName': iconName,
        'isCompleted': isCompleted,
        'streakDay': streakDay,
        'longestStreak': longestStreak,
        'totalCompletions': totalCompletions,
        'completionHistory': completionHistory,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final history = (json['completionHistory'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final days = (json['selectedDays'] as List<dynamic>?)
            ?.map((e) => int.tryParse(e.toString()) ?? 1)
            .toList() ??
        [];

    return Habit(
      id: json['id'] ?? 'h_1',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      frequency: json['frequency'] ?? 'DAILY',
      selectedDays: days,
      startDate: json['startDate'] ?? json['start_date'],
      status: json['status'] ?? 'active',
      description: json['description'] ?? '',
      colorHex: json['colorHex'] != null
          ? (int.tryParse(json['colorHex'].toString()) ?? 0xFF10B981)
          : (json['color_hex'] != null ? (int.tryParse(json['color_hex'].toString()) ?? 0xFF10B981) : 0xFF10B981),
      iconName: json['iconName'] ?? json['icon_name'] ?? 'repeat',
      isCompleted: json['isCompleted'] ?? false,
      streakDay: json['currentStreak'] ?? json['streakDay'] ?? json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalCompletions: json['totalCompletions'] ?? history.length,
      completionHistory: history,
    );
  }
}

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final String completionDate; // 'yyyy-MM-dd'
  final String status;
  final DateTime completedAt;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completionDate,
    this.status = 'completed',
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'userId': userId,
        'completionDate': completionDate,
        'status': status,
        'completedAt': completedAt.toIso8601String(),
      };

  factory HabitCompletion.fromJson(Map<String, dynamic> json) => HabitCompletion(
        id: json['id'] ?? 'hc_1',
        habitId: json['habitId'] ?? json['habit_id'] ?? '',
        userId: json['userId'] ?? json['user_id'] ?? '',
        completionDate: json['completionDate'] ?? json['completion_date'] ?? '',
        status: json['status'] ?? 'completed',
        completedAt: json['completedAt'] != null
            ? (DateTime.tryParse(json['completedAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
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
        isPremium: json['isPremium'] == true || (json['subscriptionPlan'] ?? '').toString().toUpperCase() == 'PRO',
        subscriptionPlan: json['subscriptionPlan'] ?? (json['isPremium'] == true ? 'PRO' : 'FREE'),
        token: json['token'],
        referralCode: json['referralCode'] ?? 'WRINDHA7K92',
        referredByCode: json['referredByCode'],
        successfulReferrals: json['successfulReferrals'] ?? 3,
        pendingReferrals: json['pendingReferrals'] ?? 1,
        activeDiscountPercent: json['activeDiscountPercent'] ?? 10,
      );
}

class UserSubscription {
  final String id;
  final String userId;
  final String plan; // 'free', 'pro'
  final String status; // 'active', 'expired', 'cancelled', 'trial'
  final DateTime startedAt;
  final DateTime? expiresAt;
  final String paymentProvider;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    this.plan = 'free',
    this.status = 'active',
    DateTime? startedAt,
    this.expiresAt,
    this.paymentProvider = 'NONE',
    this.transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'trial';
  bool get isPro => (plan.toLowerCase() == 'pro' || plan.toLowerCase() == 'pro_monthly' || plan.toLowerCase() == 'premium') && isActive;
  bool get isFree => !isPro;

  factory UserSubscription.defaultFree(String userId) => UserSubscription(
        id: 'sub_free_$userId',
        userId: userId,
        plan: 'free',
        status: 'active',
        startedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'plan': plan,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'payment_provider': paymentProvider,
        'transaction_id': transactionId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserSubscription.fromJson(Map<String, dynamic> json) => UserSubscription(
        id: json['id'] ?? json['subscription_id'] ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: json['user_id'] ?? json['userId'] ?? '',
        plan: (json['plan'] ?? json['plan_tier'] ?? 'free').toString().toLowerCase(),
        status: (json['status'] ?? 'active').toString().toLowerCase(),
        startedAt: json['started_at'] != null ? (DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now()) : DateTime.now(),
        expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
        paymentProvider: json['payment_provider'] ?? 'NONE',
        transactionId: json['transaction_id'],
        createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
        updatedAt: json['updated_at'] != null ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      );
}
