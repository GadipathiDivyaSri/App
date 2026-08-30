import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/subscription_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_api_service.dart';
import '../services/feature_access_service.dart';

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
    subscriptionPlan: 'FREE',
  );
  UserProfile get user => _user;

  UserSubscription _subscription = UserSubscription.defaultFree('u_1');
  UserSubscription get subscription => _subscription;

  // ---------------------------------------------------------------------------
  // CENTRALIZED SUBSCRIPTION & FEATURE ACCESS SYSTEM
  // ---------------------------------------------------------------------------
  SubscriptionPlanType get currentPlan =>
      _subscription.isPro || _user.isPremium || _user.subscriptionPlan.toUpperCase() == 'PRO'
          ? SubscriptionPlanType.pro
          : SubscriptionPlanType.free;

  bool get isProUser => FeatureAccessService.isProUser(currentPlan);

  bool hasAccess(AppFeature feature) =>
      FeatureAccessService.hasAccess(feature, plan: currentPlan);

  bool hasFeatureAccess(AppFeature feature) =>
      FeatureAccessService.hasAccess(feature, plan: currentPlan);

  FeatureAccessResult checkFeatureAccess(AppFeature feature) =>
      FeatureAccessService.checkAccess(feature, plan: currentPlan);

  int getHabitLimit() => FeatureAccessService.getHabitLimit(currentPlan);

  int getSubjectLimit() => FeatureAccessService.getSubjectLimit(currentPlan);

  void setSubscription(UserSubscription sub) {
    _subscription = sub;
    _user.subscriptionPlan = sub.plan.toUpperCase();
    _user.isPremium = sub.isPro;
    notifyListeners();
  }

  void updateSubscriptionPlan(SubscriptionPlanType plan) {
    _user.subscriptionPlan = plan.nameCode;
    _user.isPremium = plan.isPro;
    _subscription = UserSubscription(
      id: 'sub_${plan.nameCode.toLowerCase()}_${_user.id}',
      userId: _user.id,
      plan: plan.nameCode.toLowerCase(),
      status: 'active',
      startedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> syncSubscription() async {
    final remoteSub = await ApiService.fetchUserSubscription();
    if (remoteSub != null) {
      setSubscription(remoteSub);
    }
  }

  void setUser(UserProfile user, {UserSubscription? subscription}) {
    _user = user;
    if (subscription != null) {
      _subscription = subscription;
    } else {
      _subscription = UserSubscription(
        id: 'sub_${user.id}',
        userId: user.id,
        plan: user.isPremium || user.subscriptionPlan.toUpperCase() == 'PRO' ? 'pro' : 'free',
        status: 'active',
        startedAt: DateTime.now(),
      );
    }
    _isLoggedIn = true;
    syncSubscription();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _user = UserProfile(
      id: 'u_guest',
      name: 'Guest User',
      contact: '',
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
      subscriptionPlan: 'FREE',
    );
    _subscription = UserSubscription.defaultFree('u_guest');
    await ApiService.clearSession();
    notifyListeners();
  }
  // ---------------------------------------------------------------------------
  // 1. Habits (Personal Growth & Habit Tracker)
  // ---------------------------------------------------------------------------
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  DateTime _selectedHabitDate = DateTime.now();
  DateTime get selectedHabitDate => _selectedHabitDate;

  String get selectedHabitDateStr =>
      '${_selectedHabitDate.year}-${_selectedHabitDate.month.toString().padLeft(2, '0')}-${_selectedHabitDate.day.toString().padLeft(2, '0')}';

  void setSelectedHabitDate(DateTime date) {
    _selectedHabitDate = date;
    notifyListeners();
  }

  // Habits scheduled for the currently selected date
  List<Habit> get scheduledHabitsForSelectedDate =>
      _habits.where((h) => h.status != 'archived' && h.isScheduledForDate(_selectedHabitDate)).toList();

  int get completedHabitsCountForSelectedDate {
    final dateStr = selectedHabitDateStr;
    return _habits.where((h) => h.status != 'archived' && h.isScheduledForDate(_selectedHabitDate) && h.isCompletedOnDate(dateStr)).length;
  }

  double get habitProgressForSelectedDate {
    final scheduled = scheduledHabitsForSelectedDate;
    if (scheduled.isEmpty) return 0.0;
    return completedHabitsCountForSelectedDate / scheduled.length;
  }

  // Centralized Plan Limits (Max 2 for Free, Unlimited for Pro)
  bool get canAddHabit =>
      FeatureAccessService.canCreateHabit(currentHabitCount: _habits.where((h) => h.status == 'active').length, plan: currentPlan);

  int get maxHabits => FeatureAccessService.getHabitLimit(currentPlan);

  int get remainingHabitSlots =>
      FeatureAccessService.getRemainingHabitSlots(currentCount: _habits.where((h) => h.status == 'active').length, plan: currentPlan);

  void addHabit(Habit habit) {
    _habits.add(habit);
    _saveHabits();
    notifyListeners();
    ApiService.createHabitOnBackend(habit);
  }

  void editHabit(
    String id, {
    required String title,
    required String category,
    required String frequency,
    required List<int> selectedDays,
    String description = '',
    int colorHex = 0xFF10B981,
    String iconName = 'repeat',
  }) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].title = title;
      _habits[idx].category = category;
      _habits[idx].frequency = frequency;
      _habits[idx].selectedDays = selectedDays;
      _habits[idx].description = description;
      _habits[idx].colorHex = colorHex;
      _habits[idx].iconName = iconName;
      _saveHabits();
      notifyListeners();
      ApiService.updateHabitOnBackend(_habits[idx]);
    }
  }

  void pauseHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].status = 'paused';
      _saveHabits();
      notifyListeners();
      ApiService.updateHabitStatusOnBackend(id, 'paused');
    }
  }

  void resumeHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].status = 'active';
      _saveHabits();
      notifyListeners();
      ApiService.updateHabitStatusOnBackend(id, 'active');
    }
  }

  void toggleHabit(String id, {DateTime? targetDate}) {
    final date = targetDate ?? _selectedHabitDate;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      final habit = _habits[idx];
      final isCurrentlyCompleted = habit.completionHistory.contains(dateStr);

      if (isCurrentlyCompleted) {
        habit.completionHistory.remove(dateStr);
        if (dateStr == todayStr) {
          habit.isCompleted = false;
          if (habit.streakDay > 0) habit.streakDay -= 1;
        }
      } else {
        if (!habit.completionHistory.contains(dateStr)) {
          habit.completionHistory.add(dateStr);
        }
        if (dateStr == todayStr) {
          habit.isCompleted = true;
          habit.streakDay += 1;
          if (habit.streakDay > habit.longestStreak) {
            habit.longestStreak = habit.streakDay;
          }
        }
      }

      habit.totalCompletions = habit.completionHistory.length;
      _saveHabits();
      notifyListeners();

      ApiService.toggleHabitCompletionOnBackend(
        id,
        date: dateStr,
        isCompleted: !isCurrentlyCompleted,
      );
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _saveHabits();
    notifyListeners();
    ApiService.deleteHabitOnBackend(id);
  }

  // ---------------------------------------------------------------------------
  // 2. Studies & Academic Organizer
  // ---------------------------------------------------------------------------
  List<StudySubject> _subjects = [];
  List<StudySubject> get subjects => _subjects;

  // Centralized Plan Limits for Subjects
  bool get canAddSubject =>
      FeatureAccessService.canCreateSubject(currentSubjectCount: _subjects.length, plan: currentPlan);

  int get maxSubjects => FeatureAccessService.getSubjectLimit(currentPlan);

  int get remainingSubjectSlots =>
      FeatureAccessService.getRemainingSubjectSlots(currentCount: _subjects.length, plan: currentPlan);

  void addSubject(StudySubject subject) {
    _subjects.add(subject);
    _saveSubjects();
    notifyListeners();
    ApiService.createSubjectOnBackend(subject.name, subject.code);
  }

  void editSubject(String id, String name, String code, int colorHex) {
    final idx = _subjects.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _subjects[idx].name = name;
      _subjects[idx].code = code;
      _subjects[idx].colorHex = colorHex;
      _saveSubjects();
      notifyListeners();
    }
  }

  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
    _studyItems.removeWhere((item) => item.subjectId == id);
    _saveSubjects();
    _saveStudyItems();
    notifyListeners();
  }

  List<StudyItem> _studyItems = [];
  List<StudyItem> get studyItems => _studyItems;

  void addStudyItem(StudyItem item) {
    _studyItems.add(item);
    _updateSubjectProgress(item.subjectId);
    _saveStudyItems();
    notifyListeners();
  }

  void toggleStudyItem(String id) {
    final idx = _studyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      _studyItems[idx].isCompleted = !_studyItems[idx].isCompleted;
      _updateSubjectProgress(_studyItems[idx].subjectId);
      _saveStudyItems();
      notifyListeners();
    }
  }

  void deleteStudyItem(String id) {
    final idx = _studyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final subId = _studyItems[idx].subjectId;
      _studyItems.removeAt(idx);
      _updateSubjectProgress(subId);
      _saveStudyItems();
      notifyListeners();
    }
  }

  void _updateSubjectProgress(String subjectId) {
    final items = _studyItems.where((i) => i.subjectId == subjectId).toList();
    final subIdx = _subjects.indexWhere((s) => s.id == subjectId);
    if (subIdx != -1) {
      if (items.isEmpty) {
        _subjects[subIdx].progress = 0.0;
      } else {
        final completed = items.where((i) => i.isCompleted).length;
        _subjects[subIdx].progress = completed / items.length;
      }
      _saveSubjects();
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Journal / Notes (Diary Experience)
  // ---------------------------------------------------------------------------
  List<JournalEntry> _journalEntries = [];
  List<JournalEntry> get journalEntries => _journalEntries;

  void addJournalEntry(JournalEntry entry) {
    _journalEntries.insert(0, entry);
    _saveJournalEntries();
    notifyListeners();
  }

  void updateJournalEntry(JournalEntry entry) {
    final idx = _journalEntries.indexWhere((j) => j.id == entry.id);
    if (idx != -1) {
      _journalEntries[idx] = entry;
      _saveJournalEntries();
      notifyListeners();
    }
  }

  void deleteJournalEntry(String id) {
    _journalEntries.removeWhere((j) => j.id == id);
    _saveJournalEntries();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 4. Career Roadmap (Floating & Flexible)
  // ---------------------------------------------------------------------------
  List<CareerRoadmapNode> _careerNodes = [];
  List<CareerRoadmapNode> get careerNodes => _careerNodes;
  List<CareerRoadmapNode> get careerRoadmap => _careerNodes;

  void addCareerNode(CareerRoadmapNode node) {
    _careerNodes.add(node);
    _saveCareerNodes();
    notifyListeners();
  }

  void toggleCareerNode(String id) {
    final idx = _careerNodes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _careerNodes[idx].isCompleted = !_careerNodes[idx].isCompleted;
      _saveCareerNodes();
      notifyListeners();
    }
  }

  void updateCareerNode(CareerRoadmapNode node) {
    final idx = _careerNodes.indexWhere((n) => n.id == node.id);
    if (idx != -1) {
      _careerNodes[idx] = node;
      _saveCareerNodes();
      notifyListeners();
    }
  }

  void deleteCareerNode(String id) {
    _careerNodes.removeWhere((n) => n.id == id);
    _saveCareerNodes();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 5. Tasks (Eisenhower & Priority)
  // ---------------------------------------------------------------------------
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

  void setAuthenticatedSession({
    required Map<String, dynamic> userMap,
    required String token,
  }) {
    _isLoggedIn = true;
    _user = UserProfile(
      id: userMap['id'] ?? 'u_1',
      name: userMap['full_name'] ?? 'Student User',
      contact: userMap['email'] ?? '',
      focusScore: userMap['focus_score'] ?? 0,
      activeStreak: userMap['active_streak'] ?? 0,
      isPremium: (userMap['subscription_plan'] == 'PREMIUM'),
      token: token,
      referralCode: userMap['referral_code'] ?? 'WRINDHA',
      referredByCode: userMap['referred_by_code'],
    );
    notifyListeners();
  }

  void login(String name, String contact, {String? id, String? token, String? refCode, String? username, String? email}) {
    _isLoggedIn = true;
    _user = UserProfile(
      id: id ?? 'u_1',
      username: username ?? (name.isNotEmpty ? name.toLowerCase().replaceAll(' ', '_') : (contact.contains('@') ? contact.split('@')[0] : 'user')),
      email: email ?? contact,
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
    _saveSession();
    _loadUserIsolatedData();
    notifyListeners();
  }

  void loginWithUser(UserProfile user, [String? token]) {
    _isLoggedIn = true;
    _user = user;
    if (token != null) _user.token = token;
    _saveSession();
    _loadUserIsolatedData();
    notifyListeners();
  }

  void editCalendarEvent(
    String id,
    String title,
    String description,
    String location,
    String type, [
    DateTime? startTime,
    DateTime? endTime,
  ]) {
    final index = _calendarEvents.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = _calendarEvents[index];
      _calendarEvents[index] = CalendarEvent(
        id: id,
        title: title,
        description: description,
        location: location,
        type: type,
        startTime: startTime ?? existing.startTime,
        endTime: endTime ?? existing.endTime,
        isCompleted: existing.isCompleted,
      );
      _saveEvents();
      notifyListeners();
    }
  }

  void signup(String name, String contact, {String? id, String? token, String? refCode, String? username, String? email}) {
    _isLoggedIn = true;
    _user = UserProfile(
      id: id ?? 'u_1',
      username: username ?? name.toLowerCase().replaceAll(' ', '_'),
      email: email ?? contact,
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
    _saveSession();
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_session_user', jsonEncode(_user.toJson()));
    if (_user.token != null) {
      await prefs.setString('saved_session_token', _user.token!);
    }
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
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveExpenses();
    notifyListeners();
  }

  void applyReferralCode(String code) {
    _user.referredByCode = code;
    notifyListeners();
  }

  Future<void> checkoutSubscription(String plan, double basePrice) async {
    _user.isPremium = true;
    _user.activeDiscountPercent = 0;
    _saveSession();
    notifyListeners();
    await ApiService.upgradeSubscription(provider: 'GOOGLE_PLAY');
  }

  Future<void> upgradeToPremium({String provider = 'GOOGLE_PLAY'}) async {
    _user.isPremium = true;
    _user.subscriptionPlan = 'PRO';
    _subscription = UserSubscription(
      id: 'sub_pro_${_user.id}',
      userId: _user.id,
      plan: 'pro',
      status: 'active',
      startedAt: DateTime.now(),
    );
    _saveSession();
    notifyListeners();
    await ApiService.upgradeSubscription(provider: provider);
  }

  // Initial Data Setup & Persistence
  Future<void> _initData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _monthlyBudget = prefs.getDouble('saved_monthly_budget') ?? 10000.0;

      // Restore authenticated session from secure storage
      final storedToken = await AuthApiService.getSessionToken();
      final cachedUser = await AuthApiService.getCachedUser();
      if (storedToken != null && storedToken.isNotEmpty && cachedUser != null) {
        setAuthenticatedSession(userMap: cachedUser, token: storedToken);
      }

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
        _expenses = [];
      }

      // Load Referrals
      final referralsJson = prefs.getString('saved_referrals');
      if (referralsJson != null) {
        final List decoded = jsonDecode(referralsJson);
        _referralActivities =
            decoded.map((item) => ReferralActivity.fromJson(item)).toList();
      }

      // Load Active Session
      final sessionUserJson = prefs.getString('saved_session_user');
      final sessionToken = prefs.getString('saved_session_token');
      if (sessionUserJson != null && sessionUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(sessionUserJson);
          _user = UserProfile.fromJson(userMap);
          if (sessionToken != null) {
            _user.token = sessionToken;
          }
          _isLoggedIn = true;
        } catch (err) {
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
      }

      _recalculateMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  Future<void> _loadUserIsolatedData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _user.id;

    // 1. Habits
    final habitsJson = prefs.getString('saved_habits_$uid') ?? prefs.getString('saved_habits');
    if (habitsJson != null) {
      final List decoded = jsonDecode(habitsJson);
      _habits = decoded.map((item) => Habit.fromJson(item)).toList();
    } else {
      _habits = [
        Habit(id: 'h_1', title: 'Morning Focus & Meditation', frequency: 'DAILY', isCompleted: true, streakDay: 5),
        Habit(id: 'h_2', title: 'Read 20 Pages of Core Topic', frequency: 'DAILY', isCompleted: false, streakDay: 3),
      ];
    }

    // 2. Tasks
    final tasksJson = prefs.getString('saved_tasks_$uid') ?? prefs.getString('saved_tasks');
    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((item) => Task.fromJson(item)).toList();
    } else {
      _tasks = [
        Task(id: 't_1', title: 'Complete Math Assignment 3', category: 'Studies', dueDateLabel: 'Today', dueDate: DateTime.now(), priority: 1),
        Task(id: 't_2', title: 'Review System Architecture Notes', category: 'Career Roadmap', dueDateLabel: 'Tomorrow', dueDate: DateTime.now().add(const Duration(days: 1)), priority: 2),
      ];
    }

    // 3. Calendar Events
    final eventsJson = prefs.getString('saved_events_$uid') ?? prefs.getString('saved_events');
    if (eventsJson != null) {
      final List decoded = jsonDecode(eventsJson);
      _calendarEvents = decoded.map((item) => CalendarEvent.fromJson(item)).toList();
    } else {
      _calendarEvents = [];
    }

    // 4. Expenses
    final expensesJson = prefs.getString('saved_expenses_$uid') ?? prefs.getString('saved_expenses');
    if (expensesJson != null) {
      final List decoded = jsonDecode(expensesJson);
      _expenses = decoded.map((item) => ExpenseTransaction.fromJson(item)).toList();
    } else {
      _expenses = [
        ExpenseTransaction(id: 'exp_1', title: 'Course Textbook', category: 'Education', amount: 450.0, date: DateTime.now()),
        ExpenseTransaction(id: 'exp_2', title: 'Study Cafe Coffee', category: 'Food & Dining', amount: 120.0, date: DateTime.now()),
      ];
    }

    // 5. Subjects & Studies
    final subjectsJson = prefs.getString('saved_subjects_$uid');
    if (subjectsJson != null) {
      final List decoded = jsonDecode(subjectsJson);
      _subjects = decoded.map((item) => StudySubject.fromJson(item)).toList();
    } else {
      _subjects = [
        StudySubject(id: 'sub_1', name: 'Computer Science', code: 'CS101', colorHex: 0xFF0D5CE5, progress: 0.65),
        StudySubject(id: 'sub_2', name: 'Applied Mathematics', code: 'MATH201', colorHex: 0xFF10B981, progress: 0.40),
      ];
    }

    final studyItemsJson = prefs.getString('saved_study_items_$uid');
    if (studyItemsJson != null) {
      final List decoded = jsonDecode(studyItemsJson);
      _studyItems = decoded.map((item) => StudyItem.fromJson(item)).toList();
    } else {
      _studyItems = [
        StudyItem(id: 'st_1', subjectId: 'sub_1', subjectName: 'Computer Science', title: 'Algorithm Complexity Analysis', type: 'ASSIGNMENT', dueDate: DateTime.now().add(const Duration(days: 2)), isCompleted: true),
        StudyItem(id: 'st_2', subjectId: 'sub_1', subjectName: 'Computer Science', title: 'Data Structures Lab Exam', type: 'EXAM', dueDate: DateTime.now().add(const Duration(days: 5)), isCompleted: false),
        StudyItem(id: 'st_3', subjectId: 'sub_2', subjectName: 'Applied Mathematics', title: 'Differential Equations Chapter 4', type: 'TASK', dueDate: DateTime.now().add(const Duration(days: 1)), isCompleted: false),
      ];
    }

    // 6. Journal / Notes
    final journalJson = prefs.getString('saved_journal_$uid');
    if (journalJson != null) {
      final List decoded = jsonDecode(journalJson);
      _journalEntries = decoded.map((item) => JournalEntry.fromJson(item)).toList();
    } else {
      _journalEntries = [
        JournalEntry(
          id: 'j_1',
          title: 'Deep Work & Consistency Reflections',
          content: 'Today was highly focused. Managed 3 solid pomodoro sessions on system design. Energy levels were consistent throughout the morning.',
          date: DateTime.now().subtract(const Duration(days: 1)),
          mood: 'Productive',
          tags: ['Study', 'Focus', 'Reflections'],
        ),
      ];
    }

    // 7. Career Roadmap
    final careerJson = prefs.getString('saved_career_$uid');
    if (careerJson != null) {
      final List decoded = jsonDecode(careerJson);
      _careerNodes = decoded.map((item) => CareerRoadmapNode.fromJson(item)).toList();
    } else {
      _careerNodes = [
        CareerRoadmapNode(id: 'cr_1', section: 'GOAL', title: 'Software Engineering Specialist', description: 'Master full-stack architecture & distributed systems', status: 'IN_PROGRESS', order: 1),
        CareerRoadmapNode(id: 'cr_2', section: 'SKILLS', title: 'Flutter & Dart Mastery', description: 'Advanced state management, custom painting, animations', status: 'COMPLETED', order: 2),
        CareerRoadmapNode(id: 'cr_3', section: 'LEARNING', title: 'Cloud & Database Optimization', description: 'PostgreSQL indexing, Redis caching, microservices', status: 'IN_PROGRESS', order: 3),
        CareerRoadmapNode(id: 'cr_4', section: 'PROJECTS', title: 'Production OS Dashboard', description: 'Full offline-first mobile and desktop productivity application', status: 'IN_PROGRESS', order: 4),
        CareerRoadmapNode(id: 'cr_5', section: 'EXPERIENCE', title: 'Open Source Contributor', description: 'Contribute to top developer tooling ecosystems', status: 'PLANNED', order: 5),
        CareerRoadmapNode(id: 'cr_6', section: 'OPPORTUNITY', title: 'Full-Stack Software Engineer', description: 'Top product engineering company', status: 'PLANNED', order: 6),
      ];
    }

    // 8. Notifications
    final notifsJson = prefs.getString('saved_notifications_$uid') ?? prefs.getString('saved_notifications');
    if (notifsJson != null) {
      final List decoded = jsonDecode(notifsJson);
      _notifications = decoded.map((item) => AppNotification.fromJson(item)).toList();
    } else {
      _notifications = [];
    }
  }

  // Task Operations
  void addTask(String title, String category, String dueDateLabel, {int priority = 1}) {
    final newTask = Task(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      dueDateLabel: dueDateLabel,
      dueDate: DateTime.now(),
      priority: priority,
    );
    _tasks.add(newTask);
    _saveTasks();
    _recalculateMetrics();
    notifyListeners();
  }

  void editTask(String taskId, String newTitle, int priority, String category) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].title = newTitle;
      _tasks[index].priority = priority;
      _tasks[index].category = category;
      _saveTasks();
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      if (_tasks[index].isCompleted) {
        _tasks[index].completedDate = DateTime.now();
        _tasks[index].dueDateLabel = 'Completed';
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
      id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      startTime: startDT,
      endTime: endDT,
      location: location.isEmpty ? 'Workspace' : location,
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

  // Notification Operations
  void addNotification({
    required String title,
    required String header,
    required String message,
    required int colorHex,
    String category = 'RECENT',
  }) {
    final newNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
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

  void updateUserName(String newName) {
    _user.name = newName;
    _saveSession();
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

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _habits.map((h) => h.toJson()).toList();
    await prefs.setString('saved_habits_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setString('saved_tasks_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _calendarEvents.map((e) => e.toJson()).toList();
    await prefs.setString('saved_events_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('saved_notifications_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _expenses.map((e) => e.toJson()).toList();
    await prefs.setString('saved_expenses_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _subjects.map((s) => s.toJson()).toList();
    await prefs.setString('saved_subjects_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveStudyItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _studyItems.map((i) => i.toJson()).toList();
    await prefs.setString('saved_study_items_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _journalEntries.map((j) => j.toJson()).toList();
    await prefs.setString('saved_journal_${_user.id}', jsonEncode(jsonList));
  }

  Future<void> _saveCareerNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _careerNodes.map((n) => n.toJson()).toList();
    await prefs.setString('saved_career_${_user.id}', jsonEncode(jsonList));
  }
}
