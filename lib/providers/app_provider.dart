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
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppProvider() {
    loadThemePreference();
    _initData();
  }

  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    _saveThemePreference();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
    } catch (_) {}
  }

  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {}
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Set<String> _deletedItemIds = {};
  Set<String> get deletedItemIds => _deletedItemIds;

  Future<void> _saveDeletedItemIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_deleted_ids_${_user.id}', _deletedItemIds.toList());
    } catch (e) {
      debugPrint('Error saving deleted item IDs: $e');
    }
  }

  UserProfile _user = UserProfile(
    id: 'u_1',
    name: 'User',
    username: 'user',
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
    _saveSubscriptionState();
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
    _saveSession();
    _saveSubscriptionState();
    notifyListeners();
    ApiService.upgradeSubscription(provider: 'GOOGLE_PLAY');
  }

  Future<void> _saveSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_subscription_${_user.id}', jsonEncode(_subscription.toJson()));
      await prefs.setBool('saved_is_premium_${_user.id}', _user.isPremium);
      await prefs.setString('saved_sub_plan_${_user.id}', _user.subscriptionPlan);
    } catch (_) {}
  }

  Future<void> syncSubscription() async {
    try {
      final isLocallyPro = _user.isPremium ||
          _user.subscriptionPlan.toUpperCase() == 'PRO' ||
          _subscription.isPro;

      final remoteSub = await ApiService.fetchUserSubscription();
      if (remoteSub != null) {
        if (remoteSub.isPro || isLocallyPro) {
          _user.isPremium = true;
          _user.subscriptionPlan = 'PRO';
          _subscription = UserSubscription(
            id: remoteSub.id.isNotEmpty ? remoteSub.id : 'sub_pro_${_user.id}',
            userId: _user.id,
            plan: 'pro',
            status: 'active',
            startedAt: remoteSub.startedAt,
          );
          await _saveSession();
          await _saveSubscriptionState();
          if (!remoteSub.isPro) {
            await ApiService.upgradeSubscription(provider: 'LOCAL_SYNC');
          }
        } else {
          setSubscription(remoteSub);
        }
      } else if (isLocallyPro) {
        _user.isPremium = true;
        _user.subscriptionPlan = 'PRO';
        _subscription = UserSubscription(
          id: 'sub_pro_${_user.id}',
          userId: _user.id,
          plan: 'pro',
          status: 'active',
          startedAt: DateTime.now(),
        );
        await _saveSession();
        await _saveSubscriptionState();
      }
      notifyListeners();
    } catch (_) {}
  }

  void setUser(UserProfile user, {UserSubscription? subscription}) {
    _user = user;
    final isPro = user.isPremium || user.subscriptionPlan.toUpperCase() == 'PRO';
    if (subscription != null) {
      _subscription = subscription;
    } else {
      _subscription = UserSubscription(
        id: 'sub_${user.id}',
        userId: user.id,
        plan: isPro ? 'pro' : 'free',
        status: 'active',
        startedAt: DateTime.now(),
      );
    }
    if (isPro) {
      _user.isPremium = true;
      _user.subscriptionPlan = 'PRO';
      _saveSubscriptionState();
    }
    _isLoggedIn = true;
    _saveSession();
    _loadUserIsolatedData();
    syncSubscription();
    syncAllDataFromCloud();
    notifyListeners();
  }

  Future<void> logout() async {
    ApiService.logAuth('User logout initiated', {'userId': _user.id});
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
    _deletedItemIds = {};
    await ApiService.clearSession();
    await AuthApiService.clearSession();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_session_user');
      await prefs.remove('saved_session_token');
      await prefs.remove('wrindha_auth_token');
      await prefs.remove('wrindha_auth_user');
      await prefs.remove('wrindha_secure_jwt_token');
      await prefs.remove('wrindha_secure_user_profile');
    } catch (_) {}
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
    _recalculateMetrics();
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
      _habits[idx].recalculateStreaks(DateTime.now());
      _saveHabits();
      notifyListeners();
      ApiService.updateHabitStatusOnBackend(id, 'active');
    }
  }

  void toggleHabit(String id, {DateTime? targetDate}) {
    final date = targetDate ?? _selectedHabitDate;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      final habit = _habits[idx];
      final isCurrentlyCompleted = habit.isCompletedOnDate(dateStr);

      if (isCurrentlyCompleted) {
        habit.completionHistory.removeWhere((d) => d.trim().split('T')[0].split(' ')[0] == dateStr);
      } else {
        habit.completionHistory.removeWhere((d) => d.trim().split('T')[0].split(' ')[0] == dateStr);
        habit.completionHistory.add(dateStr);
      }

      habit.recalculateStreaks(DateTime.now());
      _saveHabits();
      _recalculateMetrics();
      notifyListeners();

      ApiService.toggleHabitCompletionOnBackend(
        id,
        date: dateStr,
        isCompleted: !isCurrentlyCompleted,
      );
    }
  }

  void deleteHabit(String id) {
    _deletedItemIds.add(id);
    _saveDeletedItemIds();
    _habits.removeWhere((h) => h.id == id);
    _saveHabits();
    _recalculateMetrics();
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
    ApiService.createSubjectOnBackend(subject);
  }

  void editSubject(String id, String name, String code, int colorHex) {
    final idx = _subjects.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _subjects[idx].name = name;
      _subjects[idx].code = code;
      _subjects[idx].colorHex = colorHex;
      _saveSubjects();
      notifyListeners();
      ApiService.updateSubjectOnBackend(_subjects[idx]);
    }
  }

  void deleteSubject(String id) {
    _deletedItemIds.add(id);
    for (var i in _studyItems.where((item) => item.subjectId == id)) {
      _deletedItemIds.add(i.id);
    }
    final childUnits = _studyUnits.where((u) => u.subjectId == id || u.subjectId.toLowerCase() == id.toLowerCase()).toList();
    for (var u in childUnits) {
      _deletedItemIds.add(u.id);
      for (var t in _studyTopics.where((t) => t.unitId == u.id)) {
        _deletedItemIds.add(t.id);
      }
    }
    _saveDeletedItemIds();
    _subjects.removeWhere((s) => s.id == id);
    _studyItems.removeWhere((item) => item.subjectId == id);
    _saveSubjects();
    _saveStudyItems();
    notifyListeners();
    ApiService.deleteSubjectOnBackend(id);
  }

  List<StudyItem> _studyItems = [];
  List<StudyItem> get studyItems => _studyItems;

  void addStudyItem(StudyItem item) {
    _studyItems.add(item);
    _updateSubjectProgress(item.subjectId);
    _saveStudyItems();
    notifyListeners();
    ApiService.createStudyItemOnBackend(item);
  }

  void toggleStudyItem(String id) {
    final idx = _studyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      _studyItems[idx].isCompleted = !_studyItems[idx].isCompleted;
      _updateSubjectProgress(_studyItems[idx].subjectId);
      _saveStudyItems();
      notifyListeners();
      ApiService.updateStudyItemOnBackend(_studyItems[idx]);
    }
  }

  void deleteStudyItem(String id) {
    _deletedItemIds.add(id);
    _saveDeletedItemIds();
    final idx = _studyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final subId = _studyItems[idx].subjectId;
      _studyItems.removeAt(idx);
      _updateSubjectProgress(subId);
      _saveStudyItems();
      notifyListeners();
      ApiService.deleteStudyItemOnBackend(id);
    }
  }

  void _updateSubjectProgress(String subjectIdOrName) {
    final cleanId = subjectIdOrName.trim().toLowerCase();
    final subIdx = _subjects.indexWhere((s) =>
        s.id.trim().toLowerCase() == cleanId ||
        s.name.trim().toLowerCase() == cleanId);
    if (subIdx != -1) {
      final sId = _subjects[subIdx].id.trim().toLowerCase();
      final sName = _subjects[subIdx].name.trim().toLowerCase();
      final units = _studyUnits.where((u) {
        final uSubId = u.subjectId.trim().toLowerCase();
        return uSubId == sId || uSubId == sName;
      }).toList();

      if (units.isNotEmpty) {
        final allTopics = _studyTopics.where((t) {
          final tUnitId = t.unitId.trim().toLowerCase();
          return units.any((u) => u.id.trim().toLowerCase() == tUnitId || u.title.trim().toLowerCase() == tUnitId);
        }).toList();

        if (allTopics.isNotEmpty) {
          final completedTopics = allTopics.where((t) => t.isCompleted).length;
          _subjects[subIdx].progress = completedTopics / allTopics.length;
        } else {
          final totalProg = units.fold<double>(0.0, (sum, u) => sum + u.progress);
          _subjects[subIdx].progress = totalProg / units.length;
        }
      } else {
        final items = _studyItems.where((i) {
          final iSubId = i.subjectId.trim().toLowerCase();
          return iSubId == sId || iSubId == sName;
        }).toList();
        if (items.isEmpty) {
          _subjects[subIdx].progress = 0.0;
        } else {
          final completed = items.where((i) => i.isCompleted).length;
          _subjects[subIdx].progress = completed / items.length;
        }
      }
      _saveSubjects();
    }
  }

  // UNITS & TOPICS
  List<StudyUnit> _studyUnits = [];
  List<StudyUnit> get studyUnits => _studyUnits;

  List<StudyUnit> getUnitsForSubject(String subjectIdOrName) =>
      _studyUnits.where((u) => u.subjectId == subjectIdOrName || u.subjectId.toLowerCase() == subjectIdOrName.toLowerCase()).toList();

  List<StudyTopic> _studyTopics = [];
  List<StudyTopic> get studyTopics => _studyTopics;

  List<StudyTopic> getTopicsForUnit(String unitIdOrTitle) =>
      _studyTopics.where((t) => t.unitId == unitIdOrTitle || t.unitId.toLowerCase() == unitIdOrTitle.toLowerCase()).toList();

  void addStudyUnit(StudyUnit unit) {
    _studyUnits.add(unit);
    _updateSubjectProgress(unit.subjectId);
    _saveStudyUnits();
    notifyListeners();
    ApiService.createStudyUnitOnBackend(unit);
  }

  void updateStudyUnit(String unitId, String title, String description) {
    final idx = _studyUnits.indexWhere((u) => u.id == unitId);
    if (idx != -1) {
      _studyUnits[idx].title = title;
      _studyUnits[idx].description = description;
      _saveStudyUnits();
      notifyListeners();
      ApiService.createStudyUnitOnBackend(_studyUnits[idx]);
    }
  }

  void markUnit100Percent(String unitId) {
    final idx = _studyUnits.indexWhere((u) => u.id == unitId);
    if (idx != -1) {
      _studyUnits[idx].progress = 1.0;
      _studyUnits[idx].isCompleted = true;
      for (var t in _studyTopics.where((t) => t.unitId == unitId)) {
        t.isCompleted = true;
        ApiService.toggleStudyTopicOnBackend(t.id);
      }
      _updateSubjectProgress(_studyUnits[idx].subjectId);
      _saveStudyUnits();
      _saveStudyTopics();
      notifyListeners();
      ApiService.createStudyUnitOnBackend(_studyUnits[idx]);
    }
  }

  void deleteStudyUnit(String unitId) {
    _deletedItemIds.add(unitId);
    for (var t in _studyTopics.where((t) => t.unitId == unitId)) {
      _deletedItemIds.add(t.id);
    }
    _saveDeletedItemIds();
    final idx = _studyUnits.indexWhere((u) => u.id == unitId);
    String? subjectId;
    if (idx != -1) {
      subjectId = _studyUnits[idx].subjectId;
    }
    _studyUnits.removeWhere((u) => u.id == unitId);
    _studyTopics.removeWhere((t) => t.unitId == unitId);
    if (subjectId != null && subjectId.isNotEmpty) {
      _updateSubjectProgress(subjectId);
    }
    _saveStudyUnits();
    _saveStudyTopics();
    notifyListeners();
    ApiService.deleteStudyUnitOnBackend(unitId);
  }

  void addStudyTopic(StudyTopic topic) {
    _studyTopics.add(topic);
    _updateUnitProgress(topic.unitId);
    _saveStudyTopics();
    notifyListeners();
    ApiService.createStudyTopicOnBackend(topic);
  }

  void updateStudyTopic(String topicId, String title) {
    final idx = _studyTopics.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      _studyTopics[idx].title = title;
      _saveStudyTopics();
      notifyListeners();
      ApiService.createStudyTopicOnBackend(_studyTopics[idx]);
    }
  }

  void toggleStudyTopic(String topicId) {
    final idx = _studyTopics.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      _studyTopics[idx].isCompleted = !_studyTopics[idx].isCompleted;
      _updateUnitProgress(_studyTopics[idx].unitId);
      _saveStudyTopics();
      notifyListeners();
      ApiService.toggleStudyTopicOnBackend(topicId);
    }
  }

  void deleteStudyTopic(String topicId) {
    _deletedItemIds.add(topicId);
    _saveDeletedItemIds();
    final idx = _studyTopics.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      final unitId = _studyTopics[idx].unitId;
      _studyTopics.removeAt(idx);
      _updateUnitProgress(unitId);
      _saveStudyTopics();
      notifyListeners();
      ApiService.deleteStudyTopicOnBackend(topicId);
    }
  }

  void _updateUnitProgress(String unitIdOrTitle) {
    final cleanId = unitIdOrTitle.trim().toLowerCase();
    final unitIdx = _studyUnits.indexWhere((u) => u.id.trim().toLowerCase() == cleanId || u.title.trim().toLowerCase() == cleanId);
    if (unitIdx != -1) {
      final uId = _studyUnits[unitIdx].id.trim().toLowerCase();
      final uTitle = _studyUnits[unitIdx].title.trim().toLowerCase();
      final topics = _studyTopics.where((t) {
        final tUnitId = t.unitId.trim().toLowerCase();
        return tUnitId == uId || tUnitId == uTitle;
      }).toList();
      if (topics.isEmpty) {
        _studyUnits[unitIdx].progress = 0.0;
        _studyUnits[unitIdx].isCompleted = false;
      } else {
        final completed = topics.where((t) => t.isCompleted).length;
        _studyUnits[unitIdx].progress = completed / topics.length;
        _studyUnits[unitIdx].isCompleted = completed == topics.length;
      }
      _saveStudyUnits();
      _updateSubjectProgress(_studyUnits[unitIdx].subjectId);
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
    ApiService.createJournalEntryOnBackend(entry);
  }

  void updateJournalEntry(JournalEntry entry) {
    final idx = _journalEntries.indexWhere((j) => j.id == entry.id);
    if (idx != -1) {
      _journalEntries[idx] = entry;
      _saveJournalEntries();
      notifyListeners();
      ApiService.updateJournalEntryOnBackend(entry);
    }
  }

  void deleteJournalEntry(String id) {
    _deletedItemIds.add(id);
    _saveDeletedItemIds();
    _journalEntries.removeWhere((j) => j.id == id);
    _saveJournalEntries();
    notifyListeners();
    ApiService.deleteJournalEntryOnBackend(id);
  }

  // ---------------------------------------------------------------------------
  // 4. Goals & Strategic Hierarchy (Short, Medium, Long)
  // ---------------------------------------------------------------------------
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  List<Goal> get shortGoals =>
      _goals.where((g) => g.tier.toLowerCase() == 'short').toList();

  List<Goal> get mediumGoals =>
      _goals.where((g) => g.tier.toLowerCase() == 'medium').toList();

  List<Goal> get longGoals =>
      _goals.where((g) => g.tier.toLowerCase() == 'long').toList();

  void addGoal(Goal goal) {
    _goals.add(goal);
    _saveGoals();
    notifyListeners();
    ApiService.createGoalOnBackend(goal);
  }

  void updateGoal(Goal goal) {
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _goals[idx] = goal;
      _saveGoals();
      notifyListeners();
      ApiService.updateGoalOnBackend(goal);
    }
  }

  void toggleGoal(String id) {
    final idx = _goals.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _goals[idx].isCompleted = !_goals[idx].isCompleted;
      _saveGoals();
      notifyListeners();
      ApiService.updateGoalOnBackend(_goals[idx]);
    }
  }

  void deleteGoal(String id) {
    _deletedItemIds.add(id);
    _saveDeletedItemIds();
    _goals.removeWhere((g) => g.id == id);
    _saveGoals();
    notifyListeners();
    ApiService.deleteGoalOnBackend(id);
  }

  Future<void> fetchGoalsFromBackend() async {
    try {
      final remote = await ApiService.fetchGoals();
      final validRemote = remote.where((g) {
        final t = g.tier.toLowerCase();
        return !_deletedItemIds.contains(g.id) &&
            !_deletedItemIds.contains(g.title.trim().toLowerCase()) &&
            t != 'roadmap' &&
            t != 'career' &&
            !t.contains('roadmap') &&
            !t.contains('career');
      }).toList();
      
      final Map<String, Goal> goalMap = {};
      final Map<String, String> titleToId = {};
      
      for (var g in _goals) {
        final normTitle = g.title.trim().toLowerCase();
        final t = g.tier.toLowerCase();
        if (!_deletedItemIds.contains(g.id) &&
            !_deletedItemIds.contains(normTitle) &&
            t != 'roadmap' &&
            t != 'career' &&
            !t.contains('roadmap')) {
          goalMap[g.id] = g;
          if (normTitle.isNotEmpty) titleToId[normTitle] = g.id;
        }
      }
      
      for (var rg in validRemote) {
        final normTitle = rg.title.trim().toLowerCase();
        final existingId = goalMap.containsKey(rg.id) ? rg.id : (normTitle.isNotEmpty ? titleToId[normTitle] : null);
        if (existingId != null && goalMap.containsKey(existingId)) {
          final local = goalMap[existingId]!;
          local.isCompleted = local.isCompleted || rg.isCompleted;
          goalMap[existingId] = local;
        } else {
          goalMap[rg.id] = rg;
          if (normTitle.isNotEmpty) titleToId[normTitle] = rg.id;
        }
      }
      
      _goals = goalMap.values.where((g) {
        final t = g.tier.toLowerCase();
        return !_deletedItemIds.contains(g.id) &&
            !_deletedItemIds.contains(g.title.trim().toLowerCase()) &&
            t != 'roadmap' &&
            t != 'career' &&
            !t.contains('roadmap');
      }).toList();
      _saveGoals();
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 4B. Career Roadmap (Floating & Flexible)
  // ---------------------------------------------------------------------------
  List<CareerRoadmapNode> _careerNodes = [];
  List<CareerRoadmapNode> get careerNodes => _careerNodes;
  List<CareerRoadmapNode> get careerRoadmap => _careerNodes;

  void addCareerNode(CareerRoadmapNode node) {
    _careerNodes.add(node);
    _saveCareerNodes();
    notifyListeners();
    ApiService.createCareerNodeOnBackend(node);
  }

  void toggleCareerNode(String id) {
    final idx = _careerNodes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _careerNodes[idx].isCompleted = !_careerNodes[idx].isCompleted;
      _saveCareerNodes();
      notifyListeners();
      ApiService.updateCareerNodeOnBackend(_careerNodes[idx]);
    }
  }

  void updateCareerNode(CareerRoadmapNode node) {
    final idx = _careerNodes.indexWhere((n) => n.id == node.id);
    if (idx != -1) {
      _careerNodes[idx] = node;
      _saveCareerNodes();
      notifyListeners();
      ApiService.updateCareerNodeOnBackend(node);
    }
  }

  void clearPredefinedNodes() {
    const predefinedTitles = {
      'Entry Level Goal',
      'Core Technical Skills',
      'Portfolio Projects',
      'System Architecture',
      'Engineering Leadership',
      'Senior Offer Target',
    };
    final initialCount = _careerNodes.length;
    _careerNodes.removeWhere((n) => predefinedTitles.contains(n.title));
    if (_careerNodes.length != initialCount) {
      _saveCareerNodes();
      notifyListeners();
    }
  }

  void deleteCareerNode(String id) {
    _deletedItemIds.add(id);
    _saveDeletedItemIds();
    _careerNodes.removeWhere((n) => n.id == id);
    _saveCareerNodes();
    notifyListeners();
    ApiService.deleteCareerNodeOnBackend(id);
  }

  // ---------------------------------------------------------------------------
  // 5. Tasks (To-Do, Organize Matrix, Priority Matrix - 100% Isolated)
  // ---------------------------------------------------------------------------
  List<Task> _todoTasks = [];
  List<Task> get todoTasks => _todoTasks;
  List<Task> get tasks => _todoTasks; // Compatibility getter returns To-Do tasks
  List<Task> get _tasks => _todoTasks;
  set _tasks(List<Task> val) => _todoTasks = val;

  void rescheduleOverdueTasksToTomorrow() {
    final overdue = _todoTasks.where((t) => !t.isCompleted && t.dueDateLabel != 'Today').toList();
    for (final t in overdue) {
      t.dueDateLabel = 'Tomorrow';
      t.dueDate = DateTime.now().add(const Duration(days: 1));
      ApiService.createTaskOnBackend(t);
    }
    _saveTasks();
    notifyListeners();
  }

  List<Task> _organizeTasks = [];
  List<Task> get organizeTasks => _organizeTasks;

  List<Task> _priorityMatrixTasks = [];
  List<Task> get priorityMatrixTasks => _priorityMatrixTasks;

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

  Future<void> setAuthenticatedSession({
    required Map<String, dynamic> userMap,
    required String token,
  }) async {
    _isLoggedIn = true;
    _user = UserProfile.fromJson(userMap);
    _user.token = token;
    final isPro = _user.isPremium || _user.subscriptionPlan.toUpperCase() == 'PRO';

    _subscription = UserSubscription(
      id: 'sub_${_user.id}',
      userId: _user.id,
      plan: isPro ? 'pro' : 'free',
      status: 'active',
      startedAt: DateTime.now(),
    );
    await _saveSession();
    await _loadUserIsolatedData();
    syncSubscription();
    syncAllDataFromCloud();
    notifyListeners();
  }

  void login(
    String name,
    String contact, {
    String? id,
    String? token,
    String? refCode,
    String? username,
    String? email,
    bool isPremium = false,
    String subscriptionPlan = 'FREE',
    String? referralCode,
  }) {
    _isLoggedIn = true;
    final isPro = isPremium || subscriptionPlan.toUpperCase() == 'PRO' || subscriptionPlan.toUpperCase() == 'PREMIUM';
    final resolvedUsername = username ?? (name.isNotEmpty && name != 'Student User' ? name.toLowerCase().replaceAll(' ', '_') : (contact.contains('@') ? contact.split('@')[0] : 'user'));
    final resolvedName = (name.isNotEmpty && name != 'Student User' && name != 'Alex Johnson')
        ? name
        : (resolvedUsername.isNotEmpty && resolvedUsername != 'user' ? resolvedUsername : (contact.contains('@') ? contact.split('@')[0] : 'User'));

    _user = UserProfile(
      id: id ?? 'u_1',
      username: resolvedUsername,
      email: email ?? contact,
      name: resolvedName,
      contact: contact,
      focusScore: 0,
      activeStreak: 0,
      isPremium: isPro,
      subscriptionPlan: isPro ? 'PRO' : 'FREE',
      token: token,
      referralCode: referralCode ?? 'WRINDHA',
      referredByCode: refCode,
    );
    _subscription = UserSubscription(
      id: 'sub_${_user.id}',
      userId: _user.id,
      plan: isPro ? 'pro' : 'free',
      status: 'active',
      startedAt: DateTime.now(),
    );
    if (refCode != null && refCode.trim().isNotEmpty) {
      applyReferralCode(refCode.trim());
    }
    _saveSession();
    _loadUserIsolatedData();
    syncSubscription();
    syncAllDataFromCloud();
    notifyListeners();
  }

  void loginWithUser(UserProfile user, [String? token]) {
    _isLoggedIn = true;
    _user = user;
    if (token != null) _user.token = token;
    _saveSession();
    _loadUserIsolatedData();
    syncSubscription();
    syncAllDataFromCloud();
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
      ApiService.updateCalendarEventOnBackend(_calendarEvents[index]);
    }
  }

  void signup(String name, String contact, {String? id, String? token, String? refCode, String? username, String? email}) {
    _isLoggedIn = true;
    final resolvedUsername = username ?? (name.isNotEmpty && name != 'Student User' ? name.toLowerCase().replaceAll(' ', '_') : (contact.contains('@') ? contact.split('@')[0] : 'user'));
    final resolvedName = (name.isNotEmpty && name != 'Student User' && name != 'Alex Johnson')
        ? name
        : (resolvedUsername.isNotEmpty && resolvedUsername != 'user' ? resolvedUsername : (contact.contains('@') ? contact.split('@')[0] : 'User'));

    _user = UserProfile(
      id: id ?? 'u_1',
      username: resolvedUsername,
      email: email ?? contact,
      name: resolvedName,
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
    final userJson = jsonEncode(_user.toJson());
    await prefs.setString('saved_session_user', userJson);
    await prefs.setString('wrindha_auth_user', userJson);
    await prefs.setString('wrindha_secure_user_profile', userJson);
    if (_user.token != null && _user.token!.isNotEmpty) {
      await prefs.setString('saved_session_token', _user.token!);
      await prefs.setString('wrindha_auth_token', _user.token!);
      await prefs.setString('wrindha_secure_jwt_token', _user.token!);
      await AuthApiService.saveSessionToken(_user.token!);
    }
    await AuthApiService.saveCachedUser(_user.toJson());
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    // 1. Send authenticated delete request to backend
    final result = await ApiService.deleteAccount(
      userId: _user.id,
      contact: _user.contact,
      token: _user.token,
    );

    // 2. Clear local storage persistence for user data and all session tokens
    await ApiService.clearSession();
    await AuthApiService.clearSession();
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
      name: 'User',
      username: 'user',
      contact: '',
      focusScore: 0,
      activeStreak: 0,
      isPremium: false,
    );
    _isLoggedIn = false;

    notifyListeners();
    return result;
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
      id: generateUuidV4(),
      title: title.trim().isEmpty ? category : title.trim(),
      category: category,
      amount: amount,
      isIncome: isIncome,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
    );
    _expenses.insert(0, newExp);
    _saveExpenses();
    notifyListeners();
    ApiService.createExpenseOnBackend(newExp);
  }

  void editExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    bool isIncome = false,
    String paymentMethod = 'UPI',
    DateTime? date,
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
        date: date ?? _expenses[index].date,
        paymentMethod: paymentMethod,
      );
      _saveExpenses();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _deletedItemIds.add(id);
    _expenses.removeWhere((e) => e.id == id);
    _saveDeletedItemIds();
    _saveExpenses();
    notifyListeners();
    ApiService.deleteExpenseOnBackend(id);
  }

  void applyReferralCode(String code) {
    _user.referredByCode = code;
    notifyListeners();
  }

  Future<void> checkoutSubscription(String plan, double basePrice) async {
    _user.isPremium = true;
    _user.subscriptionPlan = 'PRO';
    _user.activeDiscountPercent = 0;
    _subscription = UserSubscription(
      id: 'sub_pro_${_user.id}',
      userId: _user.id,
      plan: 'pro',
      status: 'active',
      startedAt: DateTime.now(),
    );
    await _saveSession();
    await _saveSubscriptionState();
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
    await _saveSession();
    await _saveSubscriptionState();
    notifyListeners();
    await ApiService.upgradeSubscription(provider: provider);
  }

  // Initial Data Setup & Persistence
  Future<void> _initData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _monthlyBudget = prefs.getDouble('saved_monthly_budget') ?? 10000.0;

      // Restore authenticated session from secure storage
      String? storedToken = await AuthApiService.getSessionToken();
      storedToken ??= await ApiService.getSessionToken();
      Map<String, dynamic>? cachedUser = await AuthApiService.getCachedUser();
      cachedUser ??= await ApiService.getSessionUser();
      if (storedToken != null &&
          storedToken.isNotEmpty &&
          storedToken != 'guest_token' &&
          cachedUser != null &&
          cachedUser['id'] != 'guest_user') {
        ApiService.logAuth('Restoring authenticated session during startup', {'userId': cachedUser['id']});
        await setAuthenticatedSession(userMap: cachedUser, token: storedToken);
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

      // Load Priority Matrix Tasks (Eager Load on Startup)
      final eagerPmJson = prefs.getString('saved_priority_matrix_tasks_${_user.id}') ??
          prefs.getString('saved_priority_matrix_tasks');
      if (eagerPmJson != null) {
        try {
          final List decoded = jsonDecode(eagerPmJson);
          _priorityMatrixTasks = decoded.map((item) => Task.fromJson(item)).toList();
        } catch (_) {}
      }

      // Load Organize Tasks (Eager Load on Startup)
      final eagerOrgJson = prefs.getString('saved_organize_tasks_${_user.id}') ??
          prefs.getString('saved_organize_tasks');
      if (eagerOrgJson != null) {
        try {
          final List decoded = jsonDecode(eagerOrgJson);
          _organizeTasks = decoded.map((item) => Task.fromJson(item)).toList();
        } catch (_) {}
      }

      // Load Calendar Events (Eager Load on Startup with User & Fallback Keys)
      final eventsJson = (_user.id.isNotEmpty ? prefs.getString('saved_events_${_user.id}') : null) ??
          prefs.getString('saved_events');
      if (eventsJson != null) {
        try {
          final List decoded = jsonDecode(eventsJson);
          _calendarEvents =
              decoded.map((item) => CalendarEvent.fromJson(item)).toList();
        } catch (_) {
          _calendarEvents = [];
        }
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

      // Load Active Session if not already restored
      if (!_isLoggedIn) {
        final sessionUserJson = prefs.getString('saved_session_user') ??
            prefs.getString('wrindha_auth_user') ??
            prefs.getString('wrindha_secure_user_profile');
        final sessionToken = prefs.getString('saved_session_token') ??
            prefs.getString('wrindha_auth_token') ??
            prefs.getString('wrindha_secure_jwt_token');

        if (sessionUserJson != null && sessionUserJson.isNotEmpty) {
          try {
            final Map<String, dynamic> userMap = jsonDecode(sessionUserJson);
            _user = UserProfile.fromJson(userMap);
            if (sessionToken != null && sessionToken.isNotEmpty) {
              _user.token = sessionToken;
            }
            if ((_user.name.isEmpty || _user.name == 'Student User' || _user.name == 'Alex Johnson') &&
                _user.username.isNotEmpty && _user.username.toLowerCase() != 'user') {
              _user.name = _user.username;
            }
            _isLoggedIn = true;
            await _loadUserIsolatedData();
            syncSubscription();
            syncAllDataFromCloud();
          } catch (err) {
            _isLoggedIn = false;
          }
        } else if (sessionToken != null && sessionToken.isNotEmpty) {
          _isLoggedIn = true;
          _user.token = sessionToken;
          await _loadUserIsolatedData();
          syncSubscription();
          syncAllDataFromCloud();
        } else {
          _isLoggedIn = false;
        }
      }

      _recalculateMetrics();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserIsolatedData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _user.id;

    // 0. Subscription State Restoration (User-Isolated)
    final savedIsPremium = prefs.getBool('saved_is_premium_$uid');
    final savedSubPlan = prefs.getString('saved_sub_plan_$uid');
    final savedSubJson = prefs.getString('saved_user_subscription_$uid');

    if (savedIsPremium == true || (savedSubPlan != null && savedSubPlan.toUpperCase() == 'PRO')) {
      _user.isPremium = true;
      _user.subscriptionPlan = 'PRO';
      if (savedSubJson != null) {
        try {
          _subscription = UserSubscription.fromJson(jsonDecode(savedSubJson));
        } catch (_) {
          _subscription = UserSubscription(
            id: 'sub_pro_$uid',
            userId: uid,
            plan: 'pro',
            status: 'active',
            startedAt: DateTime.now(),
          );
        }
      } else {
        _subscription = UserSubscription(
          id: 'sub_pro_$uid',
          userId: uid,
          plan: 'pro',
          status: 'active',
          startedAt: DateTime.now(),
        );
      }
    }

    // 0B. Deleted Item IDs
    final deletedList = prefs.getStringList('saved_deleted_ids_$uid');
    if (deletedList != null) {
      _deletedItemIds = deletedList.toSet();
    } else {
      _deletedItemIds = {};
    }

    // 1. Habits (User-Isolated)
    final habitsJson = prefs.getString('saved_habits_$uid');
    if (habitsJson != null) {
      final List decoded = jsonDecode(habitsJson);
      _habits = decoded.map((item) => Habit.fromJson(item)).toList();
    } else {
      _habits = [];
    }

    // 2. To-Do Tasks (User-Isolated, Only User Entered)
    final todoJson = prefs.getString('saved_todo_tasks_$uid') ?? prefs.getString('saved_tasks_$uid');
    if (todoJson != null) {
      final List decoded = jsonDecode(todoJson);
      _todoTasks = decoded.map((item) => Task.fromJson(item)).where((t) => !t.isPriorityMatrixOnly).toList();
    } else {
      _todoTasks = [];
    }

    // 2B. Organize Your Tasks / Eisenhower Matrix (Isolated)
    final organizeJson = prefs.getString('saved_organize_tasks_$uid') ??
        (_user.email.isNotEmpty ? prefs.getString('saved_organize_tasks_${_user.email}') : null) ??
        (_user.username.isNotEmpty ? prefs.getString('saved_organize_tasks_${_user.username}') : null) ??
        prefs.getString('saved_organize_tasks');
    if (organizeJson != null) {
      final List decoded = jsonDecode(organizeJson);
      _organizeTasks = decoded.map((item) => Task.fromJson(item)).toList();
    }

    // 3. Calendar Events (User-Isolated with Fallbacks)
    final eventsJson = prefs.getString('saved_events_$uid') ??
        (_user.email.isNotEmpty ? prefs.getString('saved_events_${_user.email}') : null) ??
        (_user.username.isNotEmpty ? prefs.getString('saved_events_${_user.username}') : null) ??
        prefs.getString('saved_events');
    if (eventsJson != null) {
      final List decoded = jsonDecode(eventsJson);
      _calendarEvents = decoded.map((item) => CalendarEvent.fromJson(item)).toList();
    }

    // 4. Expenses (User-Isolated)
    final expensesJson = prefs.getString('saved_expenses_$uid');
    if (expensesJson != null) {
      final List decoded = jsonDecode(expensesJson);
      _expenses = decoded.map((item) => ExpenseTransaction.fromJson(item)).toList();
    } else {
      _expenses = [];
    }

    // 5. Subjects & Studies
    final subjectsJson = prefs.getString('saved_subjects_$uid');
    if (subjectsJson != null) {
      final List decoded = jsonDecode(subjectsJson);
      _subjects = decoded.map((item) => StudySubject.fromJson(item)).toList();
    } else {
      _subjects = [];
    }

    final studyItemsJson = prefs.getString('saved_study_items_$uid');
    if (studyItemsJson != null) {
      final List decoded = jsonDecode(studyItemsJson);
      _studyItems = decoded.map((item) => StudyItem.fromJson(item)).toList();
    } else {
      _studyItems = [];
    }

    final studyUnitsJson = prefs.getString('saved_study_units_$uid');
    if (studyUnitsJson != null) {
      final List decoded = jsonDecode(studyUnitsJson);
      _studyUnits = decoded.map((item) => StudyUnit.fromJson(item)).toList();
    } else {
      _studyUnits = [];
    }

    final studyTopicsJson = prefs.getString('saved_study_topics_$uid');
    if (studyTopicsJson != null) {
      final List decoded = jsonDecode(studyTopicsJson);
      _studyTopics = decoded.map((item) => StudyTopic.fromJson(item)).toList();
    } else {
      _studyTopics = [];
    }

    // 6. Journal / Notes
    final journalJson = prefs.getString('saved_journal_$uid');
    if (journalJson != null) {
      final List decoded = jsonDecode(journalJson);
      _journalEntries = decoded.map((item) => JournalEntry.fromJson(item)).toList();
    } else {
      _journalEntries = [];
    }

    // 7. Goals
    final goalsJson = prefs.getString('saved_goals_$uid');
    if (goalsJson != null) {
      final List decoded = jsonDecode(goalsJson);
      _goals = decoded.map((item) => Goal.fromJson(item)).toList();
    } else {
      _goals = [];
    }

    // 8. Career Roadmap
    final careerJson = prefs.getString('saved_career_$uid');
    if (careerJson != null) {
      final List decoded = jsonDecode(careerJson);
      _careerNodes = decoded.map((item) => CareerRoadmapNode.fromJson(item)).toList();
    } else {
      _careerNodes = [];
    }

    // 8B. Priority Matrix Tasks (Decoupled & Resilient)
    final pmTasksJson = prefs.getString('saved_priority_matrix_tasks_$uid') ??
        (_user.email.isNotEmpty ? prefs.getString('saved_priority_matrix_tasks_${_user.email}') : null) ??
        (_user.username.isNotEmpty ? prefs.getString('saved_priority_matrix_tasks_${_user.username}') : null) ??
        prefs.getString('saved_priority_matrix_tasks');
    if (pmTasksJson != null) {
      final List decoded = jsonDecode(pmTasksJson);
      _priorityMatrixTasks = decoded.map((item) => Task.fromJson(item)).toList();
    }

    // 9. Notifications (User-Isolated)
    final notifsJson = prefs.getString('saved_notifications_$uid');
    if (notifsJson != null) {
      final List decoded = jsonDecode(notifsJson);
      _notifications = decoded.map((item) => AppNotification.fromJson(item)).toList();
    } else {
      _notifications = [];
    }

    // Filter out all previously deleted item IDs safely by unique ID
    _habits.removeWhere((h) => _deletedItemIds.contains(h.id));
    _tasks.removeWhere((t) => _deletedItemIds.contains(t.id));
    _priorityMatrixTasks.removeWhere((t) => _deletedItemIds.contains(t.id));
    _organizeTasks.removeWhere((t) => _deletedItemIds.contains(t.id));
    _calendarEvents.removeWhere((e) => _deletedItemIds.contains(e.id));
    _expenses.removeWhere((e) => _deletedItemIds.contains(e.id));
    _subjects.removeWhere((s) => _deletedItemIds.contains(s.id));
    _studyItems.removeWhere((i) => _deletedItemIds.contains(i.id));
    _studyUnits.removeWhere((u) => _deletedItemIds.contains(u.id));
    _studyTopics.removeWhere((t) => _deletedItemIds.contains(t.id));
    _journalEntries.removeWhere((j) => _deletedItemIds.contains(j.id));
    _careerNodes.removeWhere((n) => _deletedItemIds.contains(n.id));
    _goals.removeWhere((g) => _deletedItemIds.contains(g.id) || g.tier.toLowerCase() == 'roadmap');

    // Deduplicate Goals
    final Map<String, Goal> goalMap = {};
    final Map<String, String> goalTitleMap = {};
    for (var g in _goals) {
      final normTitle = g.title.trim().toLowerCase();
      if (!goalMap.containsKey(g.id) && (normTitle.isEmpty || !goalTitleMap.containsKey(normTitle))) {
        goalMap[g.id] = g;
        if (normTitle.isNotEmpty) goalTitleMap[normTitle] = g.id;
      }
    }
    _goals = goalMap.values.toList();

    // Deduplicate Career Nodes
    final Map<String, CareerRoadmapNode> careerMap = {};
    final Map<String, String> careerTitleMap = {};
    for (var n in _careerNodes) {
      final normTitle = n.title.trim().toLowerCase();
      if (!careerMap.containsKey(n.id) && (normTitle.isEmpty || !careerTitleMap.containsKey(normTitle))) {
        careerMap[n.id] = n;
        if (normTitle.isNotEmpty) careerTitleMap[normTitle] = n.id;
      }
    }
    _careerNodes = careerMap.values.toList();

    recalculateAllSubjectProgress();
    _recalculateMetrics();
    notifyListeners();
    syncAllDataFromCloud();
  }

  // ---------------------------------------------------------------------------
  // 1. To-Do List Operations (User Entered Only)
  // ---------------------------------------------------------------------------
  void addTodoTask(String title, String category, String dueDateLabel, {int priority = 1, DateTime? dueDate, String? dueTime, String? id}) {
    final newTask = Task(
      id: id ?? generateUuidV4(),
      title: title,
      category: category,
      dueDateLabel: dueDateLabel,
      dueDate: dueDate ?? DateTime.now(),
      dueTime: dueTime ?? '05:00 PM',
      priority: priority,
    );
    _todoTasks.add(newTask);
    _saveTodoTasks();
    _recalculateMetrics();
    notifyListeners();
    ApiService.createTaskOnBackend(newTask);
  }

  void addTask(String title, String category, String dueDateLabel, {int priority = 1, DateTime? dueDate, String? dueTime, String? id}) {
    addTodoTask(title, category, dueDateLabel, priority: priority, dueDate: dueDate, dueTime: dueTime, id: id);
  }

  void editTodoTask(String taskId, String newTitle, int priority, String category, {DateTime? dueDate, String? dueTime, String? dueDateLabel}) {
    final index = _todoTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _todoTasks[index].title = newTitle;
      _todoTasks[index].priority = priority;
      _todoTasks[index].category = category;
      if (dueDate != null) _todoTasks[index].dueDate = dueDate;
      if (dueTime != null) _todoTasks[index].dueTime = dueTime;
      if (dueDateLabel != null) _todoTasks[index].dueDateLabel = dueDateLabel;
      _saveTodoTasks();
      notifyListeners();
      ApiService.updateTaskOnBackend(_todoTasks[index]);
    }
  }

  void editTask(String taskId, String newTitle, int priority, String category, {DateTime? dueDate, String? dueTime, String? dueDateLabel}) {
    editTodoTask(taskId, newTitle, priority, category, dueDate: dueDate, dueTime: dueTime, dueDateLabel: dueDateLabel);
  }

  void toggleTodoTaskCompletion(String taskId) {
    final index = _todoTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _todoTasks[index].isCompleted = !_todoTasks[index].isCompleted;
      if (_todoTasks[index].isCompleted) {
        _todoTasks[index].completedDate = DateTime.now();
        _todoTasks[index].dueDateLabel = 'Completed';
      } else {
        _todoTasks[index].completedDate = null;
        _todoTasks[index].dueDateLabel = 'Today';
      }
      _saveTodoTasks();
      _recalculateMetrics();
      notifyListeners();
      ApiService.updateTaskOnBackend(_todoTasks[index]);
    }
  }

  void toggleTaskCompletion(String taskId) {
    toggleTodoTaskCompletion(taskId);
  }

  void deleteTodoTask(String taskId) {
    _deletedItemIds.add(taskId);
    _saveDeletedItemIds();
    _todoTasks.removeWhere((t) => t.id == taskId);
    _saveTodoTasks();
    _recalculateMetrics();
    notifyListeners();
    ApiService.deleteTaskOnBackend(taskId);
  }

  void deleteTask(String taskId) {
    deleteTodoTask(taskId);
  }

  Future<void> _saveTodoTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _todoTasks.map((t) => t.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      if (_user.id.isNotEmpty) {
        await prefs.setString('saved_todo_tasks_${_user.id}', encoded);
        await prefs.setString('saved_tasks_${_user.id}', encoded);
      }
      if (_user.email.isNotEmpty) {
        await prefs.setString('saved_todo_tasks_${_user.email}', encoded);
        await prefs.setString('saved_tasks_${_user.email}', encoded);
      }
      if (_user.username.isNotEmpty) {
        await prefs.setString('saved_todo_tasks_${_user.username}', encoded);
        await prefs.setString('saved_tasks_${_user.username}', encoded);
      }
      await prefs.setString('saved_todo_tasks', encoded);
      await prefs.setString('saved_tasks', encoded);
    } catch (e) {
      debugPrint('Error saving todo tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    await _saveTodoTasks();
  }

  // ---------------------------------------------------------------------------
  // 2. Organize Your Tasks / Eisenhower Matrix Operations (100% Isolated)
  // ---------------------------------------------------------------------------
  void addOrganizeTask(String title, String category, String dueDateLabel, {int priority = 1, DateTime? dueDate, String? dueTime, String? id}) {
    final newTask = Task(
      id: id ?? generateUuidV4(),
      title: title,
      category: 'Eisenhower Matrix',
      dueDateLabel: dueDateLabel,
      dueDate: dueDate ?? DateTime.now(),
      dueTime: dueTime ?? '05:00 PM',
      priority: priority,
    );
    _organizeTasks.add(newTask);
    _saveOrganizeTasks();
    notifyListeners();
    ApiService.createTaskOnBackend(newTask);
  }

  void toggleOrganizeTaskCompletion(String taskId) {
    final index = _organizeTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _organizeTasks[index].isCompleted = !_organizeTasks[index].isCompleted;
      if (_organizeTasks[index].isCompleted) {
        _organizeTasks[index].completedDate = DateTime.now();
        _organizeTasks[index].dueDateLabel = 'Completed';
      } else {
        _organizeTasks[index].completedDate = null;
        _organizeTasks[index].dueDateLabel = 'Today';
      }
      _saveOrganizeTasks();
      notifyListeners();
      ApiService.updateTaskOnBackend(_organizeTasks[index]);
    }
  }

  void deleteOrganizeTask(String taskId) {
    _deletedItemIds.add(taskId);
    _saveDeletedItemIds();
    _organizeTasks.removeWhere((t) => t.id == taskId);
    _saveOrganizeTasks();
    notifyListeners();
    ApiService.deleteTaskOnBackend(taskId);
  }

  Future<void> _saveOrganizeTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _organizeTasks.map((t) => t.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      if (_user.id.isNotEmpty) await prefs.setString('saved_organize_tasks_${_user.id}', encoded);
      if (_user.email.isNotEmpty) await prefs.setString('saved_organize_tasks_${_user.email}', encoded);
      if (_user.username.isNotEmpty) await prefs.setString('saved_organize_tasks_${_user.username}', encoded);
      await prefs.setString('saved_organize_tasks', encoded);
    } catch (e) {
      debugPrint('Error saving organize tasks: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Priority Matrix Operations (100% Isolated)
  // ---------------------------------------------------------------------------
  void addPriorityMatrixTask(
    String title,
    String tag, {
    int priority = 1,
    DateTime? dueDate,
    String? dueTime,
    String? id,
  }) {
    final newTask = Task(
      id: id ?? generateUuidV4(),
      title: title,
      category: 'Priority Matrix',
      tag: tag,
      dueDateLabel: 'Today',
      dueDate: dueDate ?? DateTime.now(),
      dueTime: dueTime ?? '05:00 PM',
      priority: priority,
      isPriorityMatrixOnly: true,
    );
    _priorityMatrixTasks.add(newTask);
    _savePriorityMatrixTasks();
    notifyListeners();
    ApiService.createTaskOnBackend(newTask);
  }

  void editPriorityMatrixTask(
    String taskId,
    String newTitle,
    int priority,
    String tag, {
    DateTime? dueDate,
    String? dueTime,
  }) {
    final index = _priorityMatrixTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _priorityMatrixTasks[index].title = newTitle;
      _priorityMatrixTasks[index].priority = priority;
      _priorityMatrixTasks[index].tag = tag;
      if (dueDate != null) _priorityMatrixTasks[index].dueDate = dueDate;
      if (dueTime != null) _priorityMatrixTasks[index].dueTime = dueTime;
      _savePriorityMatrixTasks();
      notifyListeners();
      ApiService.updateTaskOnBackend(_priorityMatrixTasks[index]);
    }
  }

  void togglePriorityMatrixTaskCompletion(String taskId) {
    final index = _priorityMatrixTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _priorityMatrixTasks[index].isCompleted = !_priorityMatrixTasks[index].isCompleted;
      if (_priorityMatrixTasks[index].isCompleted) {
        _priorityMatrixTasks[index].completedDate = DateTime.now();
        _priorityMatrixTasks[index].dueDateLabel = 'Completed';
      } else {
        _priorityMatrixTasks[index].completedDate = null;
        _priorityMatrixTasks[index].dueDateLabel = 'Today';
      }
      _savePriorityMatrixTasks();
      notifyListeners();
      ApiService.updateTaskOnBackend(_priorityMatrixTasks[index]);
    }
  }

  void deletePriorityMatrixTask(String taskId) {
    _deletedItemIds.add(taskId);
    _saveDeletedItemIds();
    _priorityMatrixTasks.removeWhere((t) => t.id == taskId);
    _savePriorityMatrixTasks();
    notifyListeners();
    ApiService.deleteTaskOnBackend(taskId);
  }

  void clearPriorityMatrixHistory() {
    final completed = _priorityMatrixTasks.where((t) => t.isCompleted).toList();
    for (var t in completed) {
      _deletedItemIds.add(t.id);
      ApiService.deleteTaskOnBackend(t.id);
    }
    _saveDeletedItemIds();
    _priorityMatrixTasks.removeWhere((t) => t.isCompleted);
    _savePriorityMatrixTasks();
    notifyListeners();
  }

  Future<void> _savePriorityMatrixTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _priorityMatrixTasks.map((t) => t.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      if (_user.id.isNotEmpty) await prefs.setString('saved_priority_matrix_tasks_${_user.id}', encoded);
      if (_user.email.isNotEmpty) await prefs.setString('saved_priority_matrix_tasks_${_user.email}', encoded);
      if (_user.username.isNotEmpty) await prefs.setString('saved_priority_matrix_tasks_${_user.username}', encoded);
      await prefs.setString('saved_priority_matrix_tasks', encoded);
    } catch (e) {
      debugPrint('Error saving priority matrix tasks: $e');
    }
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
      id: generateUuidV4(),
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
    ApiService.createCalendarEventOnBackend(newEvent);
  }

  void toggleEventCompletion(String eventId) {
    final index = _calendarEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _calendarEvents[index].isCompleted = !_calendarEvents[index].isCompleted;
      _saveEvents();
      _recalculateMetrics();
      notifyListeners();
      ApiService.updateCalendarEventOnBackend(_calendarEvents[index]);
    }
  }

  void deleteCalendarEvent(String eventId) {
    _deletedItemIds.add(eventId);
    _saveDeletedItemIds();
    _calendarEvents.removeWhere((e) => e.id == eventId);
    _saveEvents();
    notifyListeners();
    ApiService.deleteCalendarEventOnBackend(eventId);
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
    if (_isLoggedIn) {
      ApiService.updateUserProfileOnBackend({
        'name': newName,
        'display_name': newName,
        'full_name': newName,
      });
    }
  }

  void _recalculateMetrics() {
    // 1. Calculate Active Streak STRICTLY from Habits (independent of Tasks)
    if (_habits.isEmpty) {
      _user.activeStreak = 0;
    } else {
      _user.activeStreak = _habits.fold<int>(
        0,
        (maxStreak, h) => h.streakDay > maxStreak ? h.streakDay : maxStreak,
      );
    }

    // 2. Calculate Focus Score based on Task completion & Habit consistency
    final taskTotal = _tasks.length;
    final taskCompleted = _tasks.where((t) => t.isCompleted).length;
    final taskRatio = taskTotal > 0 ? (taskCompleted / taskTotal) : 0.0;

    final habitTotal = _habits.length;
    final habitCompleted = _habits.where((h) => h.isCompleted).length;
    final habitRatio = habitTotal > 0 ? (habitCompleted / habitTotal) : 0.0;

    if (taskTotal == 0 && habitTotal == 0) {
      _user.focusScore = 0;
    } else if (habitTotal == 0) {
      _user.focusScore = (taskRatio * 100).round();
    } else if (taskTotal == 0) {
      _user.focusScore = (habitRatio * 100).round();
    } else {
      _user.focusScore = ((taskRatio * 0.6 + habitRatio * 0.4) * 100).round();
    }

    if (_isLoggedIn) {
      ApiService.updateUserProfileOnBackend({
        'focus_score': _user.focusScore,
        'active_streak': _user.activeStreak,
      });
    }
  }

  void recordFocusSession(int minutes) {
    if (minutes <= 0) return;
    _user.focusScore = (_user.focusScore + (minutes * 2)).clamp(0, 100);
    _recalculateMetrics();
    recalculateAllSubjectProgress();
    addNotification(
      title: 'Focus Session Completed',
      header: 'Completed',
      message: 'Logged $minutes minutes of deep focus! Great job staying productive.',
      colorHex: 0xFF10B981,
    );
    notifyListeners();
  }

  // Persistence helpers
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
  Future<void> _saveHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _habits.map((h) => h.toJson()).toList();
      await prefs.setString('saved_habits_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving habits: $e');
    }
  }


  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _calendarEvents.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      if (_user.id.isNotEmpty) await prefs.setString('saved_events_${_user.id}', encoded);
      if (_user.email.isNotEmpty) await prefs.setString('saved_events_${_user.email}', encoded);
      if (_user.username.isNotEmpty) await prefs.setString('saved_events_${_user.username}', encoded);
      await prefs.setString('saved_events', encoded);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('saved_notifications_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> _saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _expenses.map((e) => e.toJson()).toList();
      await prefs.setString('saved_expenses_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving expenses: $e');
    }
  }

  Future<void> _saveSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _subjects.map((s) => s.toJson()).toList();
      await prefs.setString('saved_subjects_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving subjects: $e');
    }
  }

  Future<void> _saveStudyItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _studyItems.map((i) => i.toJson()).toList();
      await prefs.setString('saved_study_items_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving study items: $e');
    }
  }

  Future<void> _saveStudyUnits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _studyUnits.map((u) => u.toJson()).toList();
      await prefs.setString('saved_study_units_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving study units: $e');
    }
  }

  Future<void> _saveStudyTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _studyTopics.map((t) => t.toJson()).toList();
      await prefs.setString('saved_study_topics_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving study topics: $e');
    }
  }

  Future<void> _saveJournalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _journalEntries.map((j) => j.toJson()).toList();
      await prefs.setString('saved_journal_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving journal entries: $e');
    }
  }

  Future<void> _saveCareerNodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _careerNodes.map((n) => n.toJson()).toList();
      await prefs.setString('saved_career_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving career nodes: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _goals.map((g) => g.toJson()).toList();
      await prefs.setString('saved_goals_${_user.id}', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CLOUD PERSISTENCE & SYNCHRONIZATION SYSTEM
  // ---------------------------------------------------------------------------
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> syncAllDataFromCloud() async {
    if (!_isLoggedIn) return;
    final token = await ApiService.getSessionToken();
    if (token == null || token.isEmpty) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }
    _isSyncing = true;
    try {
      await Future.wait([
        syncTasksFromCloud(),
        syncHabitsFromCloud(),
        syncExpensesFromCloud(),
        syncSubjectsFromCloud(),
        syncStudyUnitsFromCloud(),
        syncStudyTopicsFromCloud(),
        syncStudyItemsFromCloud(),
        syncCalendarEventsFromCloud(),
        fetchGoalsFromBackend(),
        syncCareerRoadmapFromCloud(),
        syncJournalEntriesFromCloud(),
        syncUserProfileFromCloud(),
      ]);
    } catch (e) {
      debugPrint('[AppProvider] Error during syncAllDataFromCloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void recalculateAllSubjectProgress() {
    for (final s in _subjects) {
      _updateSubjectProgress(s.id);
    }
  }

  Future<void> syncTasksFromCloud() async {
    try {
      final remoteTasks = await ApiService.fetchTasks();
      final validRemote = remoteTasks.where((t) =>
        !_deletedItemIds.contains(t.id)
      ).toList();

      // 1. Merge Priority Matrix Tasks
      final remotePmTasks = validRemote.where((t) =>
        t.isPriorityMatrixOnly || t.category == 'Priority Matrix'
      ).toList();
      if (remotePmTasks.isNotEmpty || _priorityMatrixTasks.isNotEmpty) {
        final Map<String, Task> pmMap = {
          for (var t in _priorityMatrixTasks) if (!_deletedItemIds.contains(t.id)) t.id: t
        };
        for (var rt in remotePmTasks) {
          Task? local = pmMap[rt.id];
          if (local == null) {
            for (var t in pmMap.values) {
              if (t.title.trim().toLowerCase() == rt.title.trim().toLowerCase() && t.tag == rt.tag) {
                local = t;
                break;
              }
            }
          }
          if (local != null) {
            final isComp = local.isCompleted || rt.isCompleted;
            local.isCompleted = isComp;
            if (isComp && local.completedDate == null) {
              local.completedDate = rt.completedDate ?? DateTime.now();
              local.dueDateLabel = 'Completed';
            }
            pmMap[local.id] = local;
          } else {
            pmMap[rt.id] = rt;
          }
        }
        _priorityMatrixTasks = pmMap.values.where((t) => !_deletedItemIds.contains(t.id)).toList();
        _savePriorityMatrixTasks();
      }

      // 2. Merge Eisenhower / Organize Matrix Tasks
      final remoteOrgTasks = validRemote.where((t) =>
        t.category == 'Eisenhower Matrix'
      ).toList();
      if (remoteOrgTasks.isNotEmpty || _organizeTasks.isNotEmpty) {
        final Map<String, Task> orgMap = {
          for (var t in _organizeTasks) if (!_deletedItemIds.contains(t.id)) t.id: t
        };
        for (var rt in remoteOrgTasks) {
          Task? local = orgMap[rt.id];
          if (local == null) {
            for (var t in orgMap.values) {
              if (t.title.trim().toLowerCase() == rt.title.trim().toLowerCase()) {
                local = t;
                break;
              }
            }
          }
          if (local != null) {
            final isComp = local.isCompleted || rt.isCompleted;
            local.isCompleted = isComp;
            if (isComp && local.completedDate == null) {
              local.completedDate = rt.completedDate ?? DateTime.now();
              local.dueDateLabel = 'Completed';
            }
            orgMap[local.id] = local;
          } else {
            orgMap[rt.id] = rt;
          }
        }
        _organizeTasks = orgMap.values.where((t) => !_deletedItemIds.contains(t.id)).toList();
        _saveOrganizeTasks();
      }

      // 3. Merge Regular To-Do Tasks
      final remoteTodoTasks = validRemote.where((t) =>
        !t.isPriorityMatrixOnly && t.category != 'Priority Matrix' && t.category != 'Eisenhower Matrix'
      ).toList();
      final Map<String, Task> taskMap = {
        for (var t in _tasks)
          if (!_deletedItemIds.contains(t.id) && !t.isPriorityMatrixOnly && t.category != 'Priority Matrix' && t.category != 'Eisenhower Matrix')
            t.id: t
      };
      for (var rt in remoteTodoTasks) {
        Task? local = taskMap[rt.id];
        if (local == null) {
          for (var t in taskMap.values) {
            if (t.title.trim().toLowerCase() == rt.title.trim().toLowerCase()) {
              local = t;
              break;
            }
          }
        }
        if (local != null) {
          final isComp = local.isCompleted || rt.isCompleted;
          local.isCompleted = isComp;
          if (isComp && local.completedDate == null) {
            local.completedDate = rt.completedDate ?? DateTime.now();
            local.dueDateLabel = 'Completed';
          }
          taskMap[local.id] = local;
        } else {
          taskMap[rt.id] = rt;
        }
      }
      _tasks = taskMap.values.where((t) =>
        !_deletedItemIds.contains(t.id) &&
        !t.isPriorityMatrixOnly &&
        t.category != 'Priority Matrix' &&
        t.category != 'Eisenhower Matrix'
      ).toList();
      _saveTasks();
      _recalculateMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncTasksFromCloud error: $e');
    }
  }

  Future<void> syncHabitsFromCloud() async {
    try {
      final remoteHabits = await ApiService.fetchHabits();
      final validRemote = remoteHabits.where((h) =>
        !_deletedItemIds.contains(h.id) &&
        !_deletedItemIds.contains(h.title.trim().toLowerCase())
      ).toList();
      
      final Map<String, Habit> habitMap = {};
      final Map<String, String> titleToId = {};

      for (var h in _habits) {
        final normTitle = h.title.trim().toLowerCase();
        if (!_deletedItemIds.contains(h.id) && !_deletedItemIds.contains(normTitle)) {
          habitMap[h.id] = h;
          if (normTitle.isNotEmpty) titleToId[normTitle] = h.id;
        }
      }

      for (var rh in validRemote) {
        final normTitle = rh.title.trim().toLowerCase();
        final existingId = habitMap.containsKey(rh.id) ? rh.id : (normTitle.isNotEmpty ? titleToId[normTitle] : null);
        if (existingId != null && habitMap.containsKey(existingId)) {
          final local = habitMap[existingId]!;
          final mergedHistory = {...local.completionHistory, ...rh.completionHistory}.toList();
          local.completionHistory = mergedHistory;
          local.isCompleted = local.isCompleted || rh.isCompleted;
          habitMap[existingId] = local;
        } else {
          habitMap[rh.id] = rh;
          if (normTitle.isNotEmpty) titleToId[normTitle] = rh.id;
        }
      }
      _habits = habitMap.values.where((h) =>
        !_deletedItemIds.contains(h.id) &&
        !_deletedItemIds.contains(h.title.trim().toLowerCase())
      ).toList();
      for (final h in _habits) {
        h.recalculateStreaks(DateTime.now());
      }
      _saveHabits();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncHabitsFromCloud error: $e');
    }
  }

  Future<void> syncExpensesFromCloud() async {
    try {
      final remoteExpenses = await ApiService.fetchExpenses();
      final validRemote = remoteExpenses.where((e) =>
        !_deletedItemIds.contains(e.id) &&
        !_deletedItemIds.contains(e.title.trim().toLowerCase())
      ).toList();
      
      final Map<String, ExpenseTransaction> expMap = {};
      final Map<String, String> keyToId = {};

      for (var e in _expenses) {
        final key = '${e.title.trim().toLowerCase()}_${e.amount}_${e.isIncome}';
        if (!_deletedItemIds.contains(e.id) && !_deletedItemIds.contains(e.title.trim().toLowerCase())) {
          expMap[e.id] = e;
          keyToId[key] = e.id;
        }
      }

      for (var re in validRemote) {
        final key = '${re.title.trim().toLowerCase()}_${re.amount}_${re.isIncome}';
        final existingId = expMap.containsKey(re.id) ? re.id : keyToId[key];
        if (existingId == null) {
          expMap[re.id] = re;
          keyToId[key] = re.id;
        }
      }

      _expenses = expMap.values.where((e) =>
        !_deletedItemIds.contains(e.id) &&
        !_deletedItemIds.contains(e.title.trim().toLowerCase())
      ).toList();
      _saveExpenses();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncExpensesFromCloud error: $e');
    }
  }

  Future<void> syncSubjectsFromCloud() async {
    try {
      final remoteSubjects = await ApiService.fetchSubjects();
      final validRemote = remoteSubjects.where((s) => !_deletedItemIds.contains(s.id)).toList();
      final Map<String, StudySubject> subMap = {for (var s in _subjects) if (!_deletedItemIds.contains(s.id)) s.id: s};
      for (var rs in validRemote) {
        final local = subMap[rs.id];
        if (local != null) {
          local.progress = local.progress > rs.progress ? local.progress : rs.progress;
          subMap[rs.id] = local;
        } else {
          subMap[rs.id] = rs;
        }
      }
      _subjects = subMap.values.where((s) => !_deletedItemIds.contains(s.id)).toList();
      recalculateAllSubjectProgress();
      _saveSubjects();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncSubjectsFromCloud error: $e');
    }
  }

  Future<void> syncStudyItemsFromCloud() async {
    try {
      final remoteItems = await ApiService.fetchStudyItems();
      final validRemote = remoteItems.where((i) => !_deletedItemIds.contains(i.id)).toList();
      final Map<String, StudyItem> itemMap = {for (var i in _studyItems) if (!_deletedItemIds.contains(i.id)) i.id: i};
      for (var ri in validRemote) {
        final local = itemMap[ri.id];
        if (local != null) {
          local.isCompleted = local.isCompleted || ri.isCompleted;
          itemMap[ri.id] = local;
        } else {
          itemMap[ri.id] = ri;
        }
      }
      _studyItems = itemMap.values.where((i) => !_deletedItemIds.contains(i.id)).toList();
      recalculateAllSubjectProgress();
      _saveStudyItems();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncStudyItemsFromCloud error: $e');
    }
  }

  Future<void> syncStudyUnitsFromCloud() async {
    try {
      final remoteUnits = await ApiService.fetchStudyUnits();
      final validRemote = remoteUnits.where((u) => !_deletedItemIds.contains(u.id)).toList();
      final Map<String, StudyUnit> unitMap = {for (var u in _studyUnits) if (!_deletedItemIds.contains(u.id)) u.id: u};
      for (var ru in validRemote) {
        final local = unitMap[ru.id];
        if (local != null) {
          local.isCompleted = local.isCompleted || ru.isCompleted;
          local.progress = local.progress > ru.progress ? local.progress : ru.progress;
          unitMap[ru.id] = local;
        } else {
          unitMap[ru.id] = ru;
        }
      }
      _studyUnits = unitMap.values.where((u) => !_deletedItemIds.contains(u.id)).toList();
      _saveStudyUnits();
      recalculateAllSubjectProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncStudyUnitsFromCloud error: $e');
    }
  }

  Future<void> syncStudyTopicsFromCloud() async {
    try {
      final remoteTopics = await ApiService.fetchStudyTopics();
      final validRemote = remoteTopics.where((t) => !_deletedItemIds.contains(t.id)).toList();
      final Map<String, StudyTopic> topicMap = {for (var t in _studyTopics) if (!_deletedItemIds.contains(t.id)) t.id: t};
      for (var rt in validRemote) {
        final local = topicMap[rt.id];
        if (local != null) {
          local.isCompleted = local.isCompleted || rt.isCompleted;
          topicMap[rt.id] = local;
        } else {
          topicMap[rt.id] = rt;
        }
      }
      _studyTopics = topicMap.values.where((t) => !_deletedItemIds.contains(t.id)).toList();
      _saveStudyTopics();
      recalculateAllSubjectProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncStudyTopicsFromCloud error: $e');
    }
  }

  Future<void> syncCalendarEventsFromCloud() async {
    try {
      final remoteEvents = await ApiService.fetchCalendarEvents();
      final validRemote = remoteEvents.where((e) => !_deletedItemIds.contains(e.id)).toList();
      final Map<String, CalendarEvent> evtMap = {for (var e in _calendarEvents) if (!_deletedItemIds.contains(e.id)) e.id: e};
      for (var re in validRemote) {
        final local = evtMap[re.id];
        if (local != null) {
          local.isCompleted = local.isCompleted || re.isCompleted;
          if (local.type.toLowerCase() != 'general' && re.type.toLowerCase() == 'general') {
            re.type = local.type;
          }
          local.type = re.type.toLowerCase() != 'general' && re.type.isNotEmpty ? re.type : local.type;
          local.category = local.type;
          evtMap[re.id] = local;
        } else {
          evtMap[re.id] = re;
        }
      }
      _calendarEvents = evtMap.values.where((e) => !_deletedItemIds.contains(e.id)).toList();
      _saveEvents();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncCalendarEventsFromCloud error: $e');
    }
  }

  Future<void> syncCareerRoadmapFromCloud() async {
    try {
      final remoteNodes = await ApiService.fetchCareerRoadmapNodes();
      final validRemote = remoteNodes.where((n) =>
        !_deletedItemIds.contains(n.id) &&
        !_deletedItemIds.contains(n.title.trim().toLowerCase())
      ).toList();
      
      final Map<String, CareerRoadmapNode> nodeMap = {};
      final Map<String, String> titleToId = {};
      
      for (var n in _careerNodes) {
        final normTitle = n.title.trim().toLowerCase();
        if (!_deletedItemIds.contains(n.id) && !_deletedItemIds.contains(normTitle)) {
          nodeMap[n.id] = n;
          if (normTitle.isNotEmpty) titleToId[normTitle] = n.id;
        }
      }

      for (var rn in validRemote) {
        final normTitle = rn.title.trim().toLowerCase();
        final existingId = nodeMap.containsKey(rn.id) ? rn.id : (normTitle.isNotEmpty ? titleToId[normTitle] : null);
        if (existingId != null && nodeMap.containsKey(existingId)) {
          final local = nodeMap[existingId]!;
          local.isCompleted = local.isCompleted || rn.isCompleted;
          nodeMap[existingId] = local;
        } else {
          nodeMap[rn.id] = rn;
          if (normTitle.isNotEmpty) titleToId[normTitle] = rn.id;
        }
      }

      _careerNodes = nodeMap.values.where((n) =>
        !_deletedItemIds.contains(n.id) &&
        !_deletedItemIds.contains(n.title.trim().toLowerCase())
      ).toList();
      _saveCareerNodes();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncCareerRoadmapFromCloud error: $e');
    }
  }

  Future<void> syncJournalEntriesFromCloud() async {
    try {
      final remoteEntries = await ApiService.fetchJournalEntries();
      final validRemote = remoteEntries.where((j) => !_deletedItemIds.contains(j.id)).toList();
      final Map<String, JournalEntry> entryMap = {for (var j in _journalEntries) if (!_deletedItemIds.contains(j.id)) j.id: j};
      for (var rj in validRemote) {
        entryMap[rj.id] = rj;
      }
      _journalEntries = entryMap.values.where((j) => !_deletedItemIds.contains(j.id)).toList();
      _saveJournalEntries();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] syncJournalEntriesFromCloud error: $e');
    }
  }

  Future<void> syncUserProfileFromCloud() async {
    try {
      final res = await ApiService.fetchUserProfileFromBackend();
      if (res['user'] != null && res['user'] is Map) {
        final Map<String, dynamic> u = Map<String, dynamic>.from(res['user']);
        bool changed = false;

        // Restore Pro Subscription on reinstall or profile sync
        final isRemotePro = u['is_premium'] == true ||
            u['isPremium'] == true ||
            (u['subscription_plan'] ?? u['subscriptionPlan'] ?? '').toString().toUpperCase() == 'PRO' ||
            (res['subscription'] != null &&
                (res['subscription']['isPro'] == true ||
                 res['subscription']['isPremium'] == true ||
                 (res['subscription']['plan'] ?? '').toString().toLowerCase() == 'pro'));

        if (isRemotePro && (!_user.isPremium || _user.subscriptionPlan != 'PRO' || !_subscription.isPro)) {
          _user.isPremium = true;
          _user.subscriptionPlan = 'PRO';
          _subscription = UserSubscription(
            id: 'sub_pro_${_user.id}',
            userId: _user.id,
            plan: 'pro',
            status: 'active',
            startedAt: DateTime.now(),
          );
          await _saveSubscriptionState();
          changed = true;
        }

        // 1. Sync Username
        final remoteUsername = (u['username'] ?? '').toString().trim();
        if (remoteUsername.isNotEmpty &&
            remoteUsername.toLowerCase() != 'user' &&
            remoteUsername.toLowerCase() != 'student user') {
          if (_user.username != remoteUsername) {
            _user.username = remoteUsername;
            changed = true;
          }
        }

        // 2. Sync Name (Strictly guard against 'Student User' / 'Alex Johnson' overwrite)
        final remoteName = (u['display_name'] ?? u['displayName'] ?? u['full_name'] ?? u['name'] ?? '').toString().trim();
        final isRemotePlaceholder = remoteName.isEmpty || remoteName == 'Student User' || remoteName == 'Alex Johnson';

        if (!isRemotePlaceholder && remoteName != _user.name) {
          _user.name = remoteName;
          changed = true;
        } else if (isRemotePlaceholder && (_user.name.isEmpty || _user.name == 'Student User' || _user.name == 'Alex Johnson')) {
          if (_user.username.isNotEmpty && _user.username.toLowerCase() != 'user') {
            _user.name = _user.username;
            changed = true;
          } else if (_user.email.contains('@')) {
            _user.name = _user.email.split('@')[0];
            changed = true;
          }
        }

        if (u['focus_score'] != null && u['focus_score'] is num) {
          _user.focusScore = (u['focus_score'] as num).toInt();
          changed = true;
        }
        if (u['active_streak'] != null && u['active_streak'] is num) {
          _user.activeStreak = (u['active_streak'] as num).toInt();
          changed = true;
        }
        if (changed) {
          _saveSession();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AppProvider] syncUserProfileFromCloud error: $e');
    }
  }
}
