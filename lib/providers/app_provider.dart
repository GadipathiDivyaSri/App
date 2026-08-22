import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  UserProfile _user = UserProfile(
    id: 'u_1',
    name: 'Student User',
    contact: '',
    focusScore: 0,
    activeStreak: 0,
    isPremium: false,
  );
  UserProfile get user => _user;

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
  }

  void toggleHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].isCompleted = !_habits[idx].isCompleted;
      if (_habits[idx].isCompleted) {
        _habits[idx].streakDay += 1;
      }
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  List<CalendarEvent> _calendarEvents = [];
  List<CalendarEvent> get calendarEvents => _calendarEvents;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  List<ExpenseTransaction> _expenses = [];
  List<ExpenseTransaction> get expenses => _expenses;

  List<ReferralActivity> _referralActivities = [];
  List<ReferralActivity> get referralActivities => _referralActivities;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String _notificationFilter = 'RECENT';
  String get notificationFilter => _notificationFilter;

  double _monthlyBudget = 10000.0;
  double get monthlyBudget => _monthlyBudget;

  // Financial Summary Getters
  double get totalExpenses => _expenses
      .where((e) => !e.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalIncome => _expenses
      .where((e) => e.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get availableBalance => _monthlyBudget + totalIncome - totalExpenses;

  // Date Restriction Validation
  bool isDateAllowedForCreation(DateTime date) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final targetMidnight = DateTime(date.year, date.month, date.day);
    return !targetMidnight.isBefore(todayMidnight);
  }

  AppProvider() {
    _initData();
  }

  void login(String name, String contact, {String? id, String? token, String? refCode}) {
    _isLoggedIn = true;
    _user = UserProfile(
      id: id ?? 'u_1',
      name: name.isNotEmpty ? name : 'Student User',
      contact: contact,
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
      token: token,
      referralCode: 'WRINDHA7K92',
      referredByCode: refCode,
    );
    if (refCode != null && refCode.trim().isNotEmpty) {
      applyReferralCode(refCode.trim());
    }
    notifyListeners();
  }

  void signup(String name, String contact, {String? id, String? token, String? refCode}) {
    _isLoggedIn = true;
    _user = UserProfile(
      id: id ?? 'u_1',
      name: name.isNotEmpty ? name : 'Student User',
      contact: contact,
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
      token: token,
      referralCode: 'WRINDHA${DateTime.now().millisecondsSinceEpoch % 10000}',
      referredByCode: refCode,
    );
    if (refCode != null && refCode.trim().isNotEmpty) {
      applyReferralCode(refCode.trim());
    }
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    // 1. Send authenticated delete request to backend
    final result = await ApiService.deleteAccount(
      userId: _user.id,
      contact: _user.contact,
      token: _user.token,
    );

    // 2. Clear local storage persistence for user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_tasks');
    await prefs.remove('saved_events');
    await prefs.remove('saved_notifications');
    await prefs.remove('saved_monthly_budget');
    await prefs.remove('saved_expenses');
    await prefs.remove('saved_referrals');

    // 3. Reset in-memory state
    _tasks = [];
    _calendarEvents = [];
    _notifications = [];
    _expenses = [];
    _monthlyBudget = 10000.0;
    _user = UserProfile(
      id: 'u_1',
      name: 'Student User',
      contact: '',
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
    );
    _isLoggedIn = false;

    notifyListeners();
    return result;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void setNotificationFilter(String filter) {
    _notificationFilter = filter;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> editMonthlyBudget(double amount) async {
    _monthlyBudget = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_monthly_budget', amount);
    notifyListeners();
  }

  // Expense Operations
  void addExpense(
    String title,
    String category,
    double amount, {
    bool isIncome = false,
    String paymentMethod = 'UPI',
  }) {
    if (amount <= 0) return;
    final newExp = ExpenseTransaction(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? category : title.trim(),
      category: category,
      amount: amount,
      isIncome: isIncome,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
    );
    _expenses.insert(0, newExp);
    _saveExpenses();
    ApiService.createExpense(
      title: newExp.title,
      category: newExp.category,
      amount: newExp.amount,
      isIncome: newExp.isIncome,
      paymentMethod: newExp.paymentMethod,
    );
    notifyListeners();
  }

  void editExpense(
    String id,
    String title,
    String category,
    double amount, {
    bool isIncome = false,
    String paymentMethod = 'UPI',
  }) {
    if (amount <= 0) return;
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index] = ExpenseTransaction(
        id: id,
        title: title.trim().isEmpty ? category : title.trim(),
        category: category,
        amount: amount,
        isIncome: isIncome,
        date: _expenses[index].date,
        paymentMethod: paymentMethod,
      );
      _saveExpenses();
      ApiService.updateExpense(
        id: id,
        title: title,
        category: category,
        amount: amount,
        isIncome: isIncome,
        paymentMethod: paymentMethod,
      );
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveExpenses();
    ApiService.deleteExpense(id);
    notifyListeners();
  }

  // Referral Operations
  void applyReferralCode(String code) {
    _user.referredByCode = code;
    ApiService.applyReferralCode(_user.id, code);
    notifyListeners();
  }

  Future<void> checkoutSubscription(String plan, double basePrice) async {
    final res = await ApiService.checkoutSubscription(
      userId: _user.id,
      plan: plan,
      basePrice: basePrice,
    );
    if (res['success'] == true || res['subscription'] != null) {
      _user.isPremium = true;
      _user.activeDiscountPercent = 0; // consumed
      notifyListeners();
    }
  }

  // Initial Mock Data Setup & Persistence
  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();

    // Force clean slate cache reset for v4 profile update
    final isV4Clean = prefs.getBool('is_v4_profile_clean') ?? false;
    if (!isV4Clean) {
      await prefs.clear();
      await prefs.setBool('is_v4_profile_clean', true);
    }

    // Load Monthly Budget
    _monthlyBudget = prefs.getDouble('saved_monthly_budget') ?? 10000.0;

    // Load Theme
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Tasks
    final tasksJson = prefs.getString('saved_tasks');
    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((item) => Task.fromJson(item)).toList();
    } else {
      _tasks = [];
    }

    // Load Calendar Events
    final eventsJson = prefs.getString('saved_events');
    if (eventsJson != null) {
      final List decoded = jsonDecode(eventsJson);
      _calendarEvents =
          decoded.map((item) => CalendarEvent.fromJson(item)).toList();
    } else {
      _calendarEvents = [];
    }

    // Load Notifications
    final notifsJson = prefs.getString('saved_notifications');
    if (notifsJson != null) {
      final List decoded = jsonDecode(notifsJson);
      _notifications =
          decoded.map((item) => AppNotification.fromJson(item)).toList();
    } else {
      _notifications = [];
    }

    // Load Expenses
    final expensesJson = prefs.getString('saved_expenses');
    if (expensesJson != null) {
      final List decoded = jsonDecode(expensesJson);
      _expenses =
          decoded.map((item) => ExpenseTransaction.fromJson(item)).toList();
    } else {
      _expenses = [
        ExpenseTransaction(
          id: 'e_1',
          title: 'Lunch with Client',
          category: 'Food & Drinks',
          amount: 45.20,
          isIncome: false,
          date: DateTime.now().subtract(const Duration(hours: 2)),
          paymentMethod: 'UPI',
        ),
        ExpenseTransaction(
          id: 'e_2',
          title: 'Freelance Payout',
          category: 'Income',
          amount: 1200.00,
          isIncome: true,
          date: DateTime.now().subtract(const Duration(days: 1)),
          paymentMethod: 'Bank Transfer',
        ),
      ];
    }

    // Load Referrals
    final referralsJson = prefs.getString('saved_referrals');
    if (referralsJson != null) {
      final List decoded = jsonDecode(referralsJson);
      _referralActivities =
          decoded.map((item) => ReferralActivity.fromJson(item)).toList();
    }

    _recalculateMetrics();
    notifyListeners();
  }

  // Task Operations
  void addTask(String title, String category, String dueDateLabel) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      dueDateLabel: dueDateLabel,
      dueDate: DateTime.now(),
    );
    _tasks.add(newTask);
    _saveTasks();
    _recalculateMetrics();
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      if (_tasks[index].isCompleted) {
        _tasks[index].completedDate = DateTime.now();
        _tasks[index].dueDateLabel = 'Completed';

        // Check Milestone trigger (e.g. 7 day streak trigger)
        _checkAndAddMilestoneNotification();
      } else {
        _tasks[index].completedDate = null;
        _tasks[index].dueDateLabel = 'Today';
      }
      _saveTasks();
      _recalculateMetrics();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
    _recalculateMetrics();
    notifyListeners();
  }

  // Calendar Event Operations
  void addCalendarEvent(
    String title,
    String description,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    String location,
    String type,
  ) {
    final startDT = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDT = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    final newEvent = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startTime: startDT,
      endTime: endDT,
      location: location.isEmpty ? 'Workspace A' : location,
      type: type,
    );

    _calendarEvents.add(newEvent);
    _saveEvents();
    notifyListeners();
  }

  void toggleEventCompletion(String eventId) {
    final index = _calendarEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _calendarEvents[index].isCompleted = !_calendarEvents[index].isCompleted;

      if (_calendarEvents[index].isCompleted &&
          _calendarEvents[index].type == 'Focus Session') {
        // Trigger Focus Session Complete notification
        addNotification(
          title: 'Focus Session Complete',
          header: 'Completed',
          message:
              'Great work! You finished "${_calendarEvents[index].title}". Take a well-deserved break.',
          colorHex: 0xFF0EA5E9,
          category: 'RECENT',
        );
      }
      _saveEvents();
      _recalculateMetrics();
      notifyListeners();
    }
  }

  void deleteCalendarEvent(String eventId) {
    _calendarEvents.removeWhere((e) => e.id == eventId);
    _saveEvents();
    notifyListeners();
  }

  void editCalendarEvent(
    String eventId,
    String title,
    String description,
    String location,
    String type,
  ) {
    final index = _calendarEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _calendarEvents[index] = CalendarEvent(
        id: eventId,
        title: title,
        description: description,
        startTime: _calendarEvents[index].startTime,
        endTime: _calendarEvents[index].endTime,
        location: location,
        type: type,
        isCompleted: _calendarEvents[index].isCompleted,
      );
      _saveEvents();
      notifyListeners();
    }
  }

  // Notification Operations
  void addNotification({
    required String title,
    required String header,
    required String message,
    required int colorHex,
    String category = 'RECENT',
  }) {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      header: header,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      colorHex: colorHex,
    );
    _notifications.insert(0, newNotif);
    _saveNotifications();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  // Inter-module calculation & Milestone Check
  void _checkAndAddMilestoneNotification() {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    if (completedCount > 0 && completedCount % 3 == 0) {
      addNotification(
        title: 'New Milestone Achieved',
        header: 'Achieved',
        message:
            'Consistency King! You\'ve completed $completedCount key targets. Keep the momentum going!',
        colorHex: 0xFF3B82F6,
        category: 'RECENT',
      );
    }
  }

  void updateUserName(String newName) {
    _user.name = newName;
    notifyListeners();
  }

  void _recalculateMetrics() {
    if (_tasks.isEmpty) {
      _user.focusScore = 0;
      _user.activeStreak = 0;
      return;
    }
    final completed = _tasks.where((t) => t.isCompleted).length;
    final total = _tasks.length;
    _user.focusScore = ((completed / total) * 100).round();
    _user.activeStreak = completed;
  }

  // Persistence helpers
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString('saved_tasks', jsonEncode(jsonList));
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _calendarEvents.map((e) => e.toJson()).toList();
    await prefs.setString('saved_events', jsonEncode(jsonList));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('saved_notifications', jsonEncode(jsonList));
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _expenses.map((e) => e.toJson()).toList();
    await prefs.setString('saved_expenses', jsonEncode(jsonList));
  }

  Future<void> _saveReferrals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _referralActivities.map((r) => r.toJson()).toList();
    await prefs.setString('saved_referrals', jsonEncode(jsonList));
  }
}
