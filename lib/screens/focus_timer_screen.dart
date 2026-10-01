import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
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
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.user.isPremium) {
      ProUpgradeDialog.showFeatureLockedDialog(context, AppFeature.focusTimer);
      return;
    }
    if (_isStopwatchRunning) {
      _stopwatchTimer?.cancel();
      setState(() => _isStopwatchRunning = false);
      if (_stopwatchSeconds >= 60) {
        final loggedMins = (_stopwatchSeconds / 60).round();
        provider.recordFocusSession(loggedMins);
      }
    } else {
      setState(() => _isStopwatchRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _stopwatchSeconds++);
      });
    }
  }

  void _resetStopwatch() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _stopwatchTimer?.cancel();
    if (_stopwatchSeconds >= 60) {
      final loggedMins = (_stopwatchSeconds / 60).round();
      provider.recordFocusSession(loggedMins);
    }
    setState(() {
      _stopwatchSeconds = 0;
      _isStopwatchRunning = false;
    });
  }

  // --- POMODORO LOGIC ---
  void _togglePomodoro() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.user.isPremium) {
      ProUpgradeDialog.showFeatureLockedDialog(context, AppFeature.focusTimer);
      return;
    }
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
          final isFocusDone = !_isBreakMode;
          if (isFocusDone) {
            provider.recordFocusSession(25);
          }
          setState(() {
            _isPomodoroRunning = false;
            _isBreakMode = !_isBreakMode;
            _pomodoroSeconds = _isBreakMode ? 5 * 60 : 25 * 60;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBreakMode
                  ? '🍅 Pomodoro session complete! +25m focus logged. Take a 5-minute break.'
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

  void _adjustStopwatch(int deltaSeconds) {
    setState(() {
      _stopwatchSeconds = (_stopwatchSeconds + deltaSeconds).clamp(0, 86400);
    });
  }

  void _adjustPomodoro(int deltaSeconds) {
    setState(() {
      _pomodoroSeconds = (_pomodoroSeconds + deltaSeconds).clamp(10, 86400);
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
    final provider = Provider.of<AppProvider>(context);

    return ProFeatureGuard(
      feature: AppFeature.focusTimer,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Focus Hub',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            // ULTRA-MODERN TAB SELECTOR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF0D5CE5), const Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: '⏱️ Stopwatch'),
                  Tab(text: '🍅 Pomodoro'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TAB VIEWS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStopwatchTab(context, isDark, provider),
                  _buildPomodoroTab(context, isDark, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STOPWATCH TAB (ATTRACTIVE NEUMORPHIC / GLOWING UI)
  // ---------------------------------------------------------------------------
  Widget _buildStopwatchTab(BuildContext context, bool isDark, AppProvider provider) {
    final activeColor = _isStopwatchRunning
        ? const Color(0xFF10B981)
        : (isDark ? const Color(0xFF6366F1) : const Color(0xFF0D5CE5));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Glowing Outer Container with Neumorphic Ring
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF161722) : Colors.white,
              border: Border.all(
                color: activeColor.withOpacity(0.4),
                width: 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(isDark ? 0.25 : 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Dot
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isStopwatchRunning ? 'ACTIVE FOCUS' : 'PAUSED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Digital Time
                  Text(
                    _formatStopwatch(_stopwatchSeconds),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elapsed Time',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Preset Adjusters
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAdjustChip('-5m', () => _adjustStopwatch(-300), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('-1m', () => _adjustStopwatch(-60), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('+1m', () => _adjustStopwatch(60), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('+5m', () => _adjustStopwatch(300), isDark),
            ],
          ),
          const SizedBox(height: 28),

          // Action Controls (Reset & Play/Pause)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _resetStopwatch,
                tooltip: 'Reset Stopwatch',
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 26,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF27293A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _toggleStopwatch,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isStopwatchRunning
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF10B981), const Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isStopwatchRunning ? Colors.redAccent : const Color(0xFF10B981))
                            .withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isStopwatchRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Deck Footer
          _buildFocusStatsCard(isDark, provider),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. POMODORO TAB (25M FOCUS / 5M BREAK GLOWING UI)
  // ---------------------------------------------------------------------------
  Widget _buildPomodoroTab(BuildContext context, bool isDark, AppProvider provider) {
    final totalSecs = _isBreakMode ? 5 * 60 : 25 * 60;
    final progress = totalSecs > 0 ? (1.0 - (_pomodoroSeconds / totalSecs)).clamp(0.0, 1.0) : 0.0;
    final themeColor = _isBreakMode
        ? const Color(0xFF10B981)
        : (isDark ? const Color(0xFF6366F1) : const Color(0xFF0D5CE5));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // Focus vs Break Mode Switch
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _switchPomodoroMode(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isBreakMode
                          ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF0D5CE5))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⚡ 25m Focus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !_isBreakMode ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _switchPomodoroMode(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isBreakMode ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '☕ 5m Break',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isBreakMode ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Circular Pomodoro Progress Display
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
              ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF161722) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isBreakMode
                            ? 'REST & CHARGE'
                            : (_isPomodoroRunning ? 'DEEP FOCUSING' : 'READY TO START'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatPomodoro(_pomodoroSeconds),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBreakMode ? 'Take a short break' : 'Target: 25 Minutes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Preset Adjusters
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAdjustChip('-5m', () => _adjustPomodoro(-300), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('-1m', () => _adjustPomodoro(-60), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('+1m', () => _adjustPomodoro(60), isDark),
              const SizedBox(width: 8),
              _buildAdjustChip('+5m', () => _adjustPomodoro(300), isDark),
            ],
          ),
          const SizedBox(height: 28),

          // Action Controls (Reset & Play/Pause)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _resetPomodoro,
                tooltip: 'Reset Pomodoro',
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 26,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF27293A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _togglePomodoro,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isPomodoroRunning
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [themeColor, themeColor.withOpacity(0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPomodoroRunning ? Colors.redAccent : themeColor).withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPomodoroRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Deck Footer
          _buildFocusStatsCard(isDark, provider),
        ],
      ),
    );
  }

  Widget _buildAdjustChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27293A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusStatsCard(bool isDark, AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '⚡ Focus Score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.user.focusScore} pts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Container(
            height: 30,
            width: 1,
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
          ),
          Column(
            children: [
              Text(
                '🔥 Active Streak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.user.activeStreak} Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
