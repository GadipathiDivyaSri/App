import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final notifications = provider.notifications;
    final activeFilter = provider.notificationFilter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredNotifs = notifications.where((n) {
      if (activeFilter == 'ACTIVITY') {
        return n.category == 'ACTIVITY';
      }
      return true; // RECENT shows all or recent
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFF0D5CE5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control Tabs
            Row(
              children: [
                _buildSegmentTab(
                  context,
                  title: 'RECENT',
                  isSelected: activeFilter == 'RECENT',
                  onTap: () => provider.setNotificationFilter('RECENT'),
                ),
                const SizedBox(width: 20),
                _buildSegmentTab(
                  context,
                  title: 'ACTIVITY',
                  isSelected: activeFilter == 'ACTIVITY',
                  onTap: () => provider.setNotificationFilter('ACTIVITY'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Notification List
            Expanded(
              child: filteredNotifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 50,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications right now',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredNotifs.length,
                      itemBuilder: (context, index) {
                        final notif = filteredNotifs[index];
                        return _buildNotificationCard(context, notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0D5CE5) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: isSelected ? const Color(0xFF0D5CE5) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(notif.colorHex);

    // Pick icon according to title / header
    IconData cardIcon = Icons.timer_outlined;
    if (notif.title.contains('Milestone')) {
      cardIcon = Icons.emoji_events_outlined;
    } else if (notif.title.contains('Focus')) {
      cardIcon = Icons.filter_vintage_outlined;
    } else if (notif.title.contains('Analytics')) {
      cardIcon = Icons.show_chart_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            // Left Colored Highlight Border
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Circular Icon Background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(cardIcon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            _formatTimeAgo(notif.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes < 1 ? 1 : diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
