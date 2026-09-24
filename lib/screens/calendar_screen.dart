import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedDate = provider.selectedDate;
    final events = provider.calendarEvents;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final dayEvents = events.where((e) =>
        e.startTime.year == selectedDate.year &&
        e.startTime.month == selectedDate.month &&
        e.startTime.day == selectedDate.day).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: Text(
          'Calendar',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () => _showAddEventDialog(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Pastel Banner (Refer to Image 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelCalendar,
                borderRadius: BorderRadius.circular(22),
                border: isDark
                    ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkIconBg
                          : AppTheme.pastelCalendarIcon,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: isDark ? AppTheme.darkIconGlow : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendar',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Month Header (Clickable for Month/Year Selection)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      provider.setSelectedDate(picked);
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D5CE5)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        provider.setSelectedDate(
                          DateTime(selectedDate.year, selectedDate.month - 1, 1),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        provider.setSelectedDate(
                          DateTime(selectedDate.year, selectedDate.month + 1, 1),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),

            // Calendar Grid Widget
            _buildCalendarGrid(context, provider),

            const SizedBox(height: 24),

            // Daily Agenda Header & Date Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Agenda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1F2B)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D5CE5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Agenda List
            if (dayEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No tasks scheduled for ${DateFormat('MMM d').format(selectedDate)}.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  return _buildAgendaCard(context, provider, event);
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, AppProvider provider) {
    final selectedDate = provider.selectedDate;
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final totalCells = startWeekday + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox(); // Empty padding for preceding month
              }

              final dayNum = index - startWeekday + 1;
              final isSelected = dayNum == selectedDate.day;
              final cellDate = DateTime(selectedDate.year, selectedDate.month, dayNum);

              final hasEvents = provider.calendarEvents.any((e) =>
                  e.startTime.year == cellDate.year &&
                  e.startTime.month == cellDate.month &&
                  e.startTime.day == cellDate.day);

              return GestureDetector(
                onTap: () {
                  provider.setSelectedDate(cellDate);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isDark ? AppTheme.darkIconGlow : AppTheme.pastelCalendarIcon)
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      if (hasEvents) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : const Color(0xFF0D5CE5),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(
      BuildContext context, AppProvider provider, dynamic event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startTimeStr = DateFormat('h:mm a').format(event.startTime);
    final endTimeStr = DateFormat('h:mm a').format(event.endTime);

    // Indicator color according to type / priority
    Color borderAccentColor = const Color(0xFF0D5CE5);
    IconData leadingIcon = Icons.check_circle_outline_rounded;
    if (event.type == 'Meeting') {
      borderAccentColor = Colors.redAccent;
      leadingIcon = Icons.priority_high_rounded;
    } else if (event.isCompleted) {
      borderAccentColor = const Color(0xFF64748B);
      leadingIcon = Icons.check_circle_rounded;
    }

    return GestureDetector(
      onTap: () => _showEventDetailsModal(context, provider, event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppTheme.darkCardBorder) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Line
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: borderAccentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: Icon(
                  leadingIcon,
                  color: borderAccentColor,
                  size: 24,
                ),
                onPressed: () => provider.toggleEventCompletion(event.id),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decoration: event.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: borderAccentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: borderAccentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description.toString().trim().isNotEmpty
                            ? event.description
                            : 'No description added.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            '$startTimeStr - $endTimeStr',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Color(0xFF0D5CE5)),
                            const SizedBox(width: 2),
                            Text(
                              event.location,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0D5CE5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                onSelected: (val) {
                  if (val == 'details') {
                    _showEventDetailsModal(context, provider, event);
                  } else if (val == 'toggle') {
                    provider.toggleEventCompletion(event.id);
                  } else if (val == 'edit') {
                    _showEditEventDialog(context, provider, event);
                  } else if (val == 'delete') {
                    provider.deleteCalendarEvent(event.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0D5CE5)),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(event.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, size: 18, color: const Color(0xFF0D5CE5)),
                        const SizedBox(width: 8),
                        Text(event.isCompleted ? 'Mark Pending' : 'Mark Completed'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D5CE5)),
                        SizedBox(width: 8),
                        Text('Edit Event'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Event', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetailsModal(BuildContext context, AppProvider provider, dynamic event) {
    final startTimeStr = DateFormat('EEEE, MMM d, yyyy · h:mm a').format(event.startTime);
    final endTimeStr = DateFormat('h:mm a').format(event.endTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5CE5).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.type,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D5CE5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text('$startTimeStr - $endTimeStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0D5CE5)),
                  const SizedBox(width: 8),
                  Text(event.location, style: const TextStyle(fontSize: 13, color: Color(0xFF0D5CE5))),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.description.toString().trim().isNotEmpty ? event.description : 'No description provided.',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditEventDialog(context, provider, event);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(event.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, color: Colors.white),
                    label: Text(event.isCompleted ? 'Mark Pending' : 'Mark Complete', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5CE5)),
                    onPressed: () {
                      provider.toggleEventCompletion(event.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, AppProvider provider, dynamic event) {
    final titleCtrl = TextEditingController(text: event.title);
    final descCtrl = TextEditingController(text: event.description);
    final locationCtrl = TextEditingController(text: event.location);
    String type = event.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5CE5)),
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    provider.editCalendarEvent(
                      event.id,
                      titleCtrl.text.trim(),
                      descCtrl.text.trim(),
                      locationCtrl.text.trim(),
                      type,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Ensure default event scheduling date is today or selectedDate if in future
    DateTime eventDate = provider.selectedDate.isBefore(todayMidnight)
        ? todayMidnight
        : provider.selectedDate;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String type = 'Task';
    TimeOfDay preferredStartTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay preferredEndTime = const TimeOfDay(hour: 10, minute: 30);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Schedule Event',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5CE5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today & Future Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D5CE5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Event Title',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dynamic Date Selector with firstDate = today
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      'Date: ${DateFormat('EEE, MMM d, yyyy').format(eventDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final currentNow = DateTime.now();
                      final today = DateTime(currentNow.year, currentNow.month, currentNow.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: eventDate.isBefore(today) ? today : eventDate,
                        firstDate: today, // Past dates dynamically disabled
                        lastDate: DateTime(currentNow.year + 10), // Dynamic future range
                      );
                      if (picked != null) {
                        setStateModal(() => eventDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text('Start: ${preferredStartTime.format(context)}', style: const TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: preferredStartTime);
                            if (picked != null) setStateModal(() => preferredStartTime = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                          label: Text('End: ${preferredEndTime.format(context)}', style: const TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: preferredEndTime);
                            if (picked != null) setStateModal(() => preferredEndTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: locationCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Location',
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Meeting', child: Text('Meeting')),
                            DropdownMenuItem(
                                value: 'Task', child: Text('Task')),
                          ],
                          onChanged: (val) {
                            if (val != null) setStateModal(() => type = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5CE5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an event title.')),
                          );
                          return;
                        }

                        // Validate that date is not in the past
                        if (!provider.isDateAllowedForCreation(eventDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot schedule events in the past. Only today and future dates allowed.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        provider.addCalendarEvent(
                          titleCtrl.text.trim(),
                          descCtrl.text.trim(),
                          eventDate,
                          preferredStartTime,
                          preferredEndTime,
                          locationCtrl.text.trim(),
                          type,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event scheduled successfully!'),
                            backgroundColor: Color(0xFF0D5CE5),
                          ),
                        );
                      },
                      child: const Text(
                        'Save Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
