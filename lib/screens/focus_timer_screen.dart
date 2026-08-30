import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../theme/app_theme.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. STOPWATCH STATE
  int _stopwatchSeconds = 0;
  bool _isStopwatchRunning = false;
  Timer? _stopwatchTimer;

  // 2. POMODORO STATE
  int _pomodoroSeconds = 25 * 60; // 25 Minutes Focus
  bool _isPomodoroRunning = false;
  bool _isBreakMode = false;
  Timer? _pomodoroTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- STOPWATCH LOGIC ---
  void _toggleStopwatch() {
    if (_isStopwatchRunning) {
      _stopwatchTimer?.cancel();
      setState(() => _isStopwatchRunning = false);
    } else {
      setState(() => _isStopwatchRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _stopwatchSeconds++);
      });
    }
  }

  void _resetStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() {
      _stopwatchSeconds = 0;
      _isStopwatchRunning = false;
    });
  }

  // --- POMODORO LOGIC ---
  void _togglePomodoro() {
    if (_isPomodoroRunning) {
      _pomodoroTimer?.cancel();
      setState(() => _isPomodoroRunning = false);
    } else {
      setState(() => _isPomodoroRunning = true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pomodoroSeconds > 0) {
          setState(() => _pomodoroSeconds--);
        } else {
          _pomodoroTimer?.cancel();
          setState(() {
            _isPomodoroRunning = false;
            _isBreakMode = !_isBreakMode;
            _pomodoroSeconds = _isBreakMode ? 5 * 60 : 25 * 60;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBreakMode
                  ? '🍅 Pomodoro session complete! Take a 5-minute break.'
                  : '⚡ Break over! Back to 25-minute Pomodoro focus session.'),
            ),
          );
        }
      });
    }
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _isBreakMode = false;
      _pomodoroSeconds = 25 * 60;
    });
  }

  void _switchPomodoroMode(bool isBreak) {
    if (_isPomodoroRunning) return;
    setState(() {
      _isBreakMode = isBreak;
      _pomodoroSeconds = isBreak ? 5 * 60 : 25 * 60;
    });
  }

  String _formatStopwatch(int totalSecs) {
    final hrs = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPomodoro(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopwatchTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProFeatureGuard(
      feature: AppFeature.focusTimer,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // TAB BAR: STOPWATCH & POMODORO ONLY
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? AppTheme.darkPrimary : AppTheme.pastelStudiesIcon,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '⏱️ Stopwatch'),
                Tab(text: '🍅 Pomodoro'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TAB VIEWS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStopwatchTab(context),
                _buildPomodoroTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STOPWATCH TAB (COUNT UP)
  // ---------------------------------------------------------------------------
  Widget _buildStopwatchTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular Stopwatch Display
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.darkCardBg : AppTheme.pastelStudies,
            border: Border.all(
              color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelStudiesIcon,
              width: 4,
            ),
            boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatStopwatch(_stopwatchSeconds),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isStopwatchRunning ? 'RUNNING' : 'PAUSED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _isStopwatchRunning
                      ? (isDark ? AppTheme.darkIconGlow : AppTheme.pastelStudiesIcon)
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: 'sw_reset_fab',
              backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
              elevation: 2,
              onPressed: _resetStopwatch,
              child: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                heroTag: 'sw_play_fab',
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.pastelStudiesIcon,
                elevation: 4,
                onPressed: _toggleStopwatch,
                child: Icon(
                  _isStopwatchRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. POMODORO TAB (25 MIN FOCUS / 5 MIN BREAK)
  // ---------------------------------------------------------------------------
  Widget _buildPomodoroTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSecs = _isBreakMode ? 5 * 60 : 25 * 60;
    final progress = totalSecs > 0 ? (1.0 - (_pomodoroSeconds / totalSecs)).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mode Switch Chips: 25m Focus vs 5m Break
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('25m Focus ⚡'),
              selected: !_isBreakMode,
              selectedColor: isDark ? AppTheme.darkPrimary : AppTheme.pastelStudiesIcon,
              labelStyle: TextStyle(
                color: !_isBreakMode ? Colors.white : (isDark ? Colors.white70 : AppTheme.lightTextPrimary),
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => _switchPomodoroMode(false),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('5m Break ☕'),
              selected: _isBreakMode,
              selectedColor: const Color(0xFF10B981),
              labelStyle: TextStyle(
                color: _isBreakMode ? Colors.white : (isDark ? Colors.white70 : AppTheme.lightTextPrimary),
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => _switchPomodoroMode(true),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Circular Pomodoro Progress Display
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFFFF9E6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isBreakMode
                      ? const Color(0xFF10B981)
                      : (isDark ? AppTheme.darkPrimary : AppTheme.pastelStudiesIcon),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatPomodoro(_pomodoroSeconds),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBreakMode ? 'BREAK TIME' : (_isPomodoroRunning ? 'FOCUSING' : 'READY'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _isBreakMode
                        ? const Color(0xFF10B981)
                        : (isDark ? AppTheme.darkIconGlow : AppTheme.pastelStudiesIcon),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: 'pomo_reset_fab',
              backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
              elevation: 2,
              onPressed: _resetPomodoro,
              child: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                heroTag: 'pomo_play_fab',
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.pastelStudiesIcon,
                elevation: 4,
                onPressed: _togglePomodoro,
                child: Icon(
                  _isPomodoroRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
