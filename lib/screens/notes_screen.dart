import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/premium_lock_banner.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';

/// Journal / Notes Screen for WrindhaOS
/// 
/// Diary-style personal reflection experience with:
/// - Header: Journal / Notes + [ + New Entry ]
/// - Full entry viewer and rich editor
/// - Search filter
/// - Date & Time stamps, mood chips, short preview
/// - Persistent storage in AppProvider
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    final allEntries = provider.journalEntries;
    final filteredEntries = _searchQuery.isEmpty
        ? allEntries
        : allEntries.where((e) {
            final q = _searchQuery.toLowerCase();
            return e.title.toLowerCase().contains(q) || e.content.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Journal / Notes',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () {
                if (!isPremium) {
                  showUpgradeProModal(
                    context,
                    featureTitle: 'Journal & Notes',
                    limitExplanation: 'Free plan includes read-only preview of Journal. Upgrade to Pro for ₹49/month to write unlimited personal diary entries.',
                  );
                } else {
                  _showEntryEditor(context, null);
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_fab',
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: Icon(
          !isPremium ? Icons.lock_rounded : Icons.edit_note_rounded,
          color: Colors.white,
          size: 26,
        ),
        onPressed: () {
          if (!isPremium) {
            showUpgradeProModal(
              context,
              featureTitle: 'Journal & Notes',
              limitExplanation: 'Free plan includes read-only preview of Journal. Upgrade to Pro for ₹49/month to write unlimited personal diary entries.',
            );
          } else {
            _showEntryEditor(context, null);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Lock Banner if Free
            if (!isPremium)
              const PremiumLockBanner(
                featureName: 'Journal / Notes',
                description: 'You are currently viewing Journal / Notes in preview mode. Upgrade to Pro for ₹49/month to write, search, and store unlimited encrypted diary entries.',
              ),

            // 2. Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search journal entries...',
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Entries List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Reflections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                Text(
                  '${filteredEntries.length} ${filteredEntries.length == 1 ? 'ENTRY' : 'ENTRIES'}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (filteredEntries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 48, color: textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Your journal is empty.\nTap "+ New Entry" to capture your thoughts!'
                          : 'No matching entries found for "$_searchQuery".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: filteredEntries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showEntryReader(context, entry, isPremium),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Date & Mood
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 13, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('EEEE, MMM d, yyyy • h:mm a').format(entry.date),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      entry.mood,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Title
                              Text(
                                entry.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Content Snippet
                              Text(
                                entry.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Footer Row: Tags and Options
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    children: entry.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF242321) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_horiz_rounded, size: 20, color: textSecondary),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        if (!isPremium) {
                                          showUpgradeProModal(context, featureTitle: 'Journal Editing', limitExplanation: 'Upgrade to Pro for ₹49/month to edit past journal logs.');
                                        } else {
                                          _showEntryEditor(context, entry);
                                        }
                                      } else if (action == 'delete') {
                                        provider.deleteJournalEntry(entry.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- ENTRY READER MODAL ---
  void _showEntryReader(BuildContext context, JournalEntry entry, bool isPremium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(entry.date),
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (!isPremium) {
                        showUpgradeProModal(context, featureTitle: 'Journal Editing', limitExplanation: 'Upgrade to Pro for ₹49/month to edit past journal logs.');
                      } else {
                        _showEntryEditor(context, entry);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ENTRY EDITOR MODAL ---
  void _showEntryEditor(BuildContext context, JournalEntry? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String mood = existing?.mood ?? 'Productive';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'New Journal Entry' : 'Edit Journal Entry',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title / Focus of the Day', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: mood,
                    decoration: const InputDecoration(labelText: 'Mood / State', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Productive', child: Text('⚡ Productive')),
                      DropdownMenuItem(value: 'Happy', child: Text('😊 Happy & Energized')),
                      DropdownMenuItem(value: 'Reflective', child: Text('🌿 Calm & Reflective')),
                      DropdownMenuItem(value: 'Stressed', child: Text('🔥 Stressed / Challenging')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => mood = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts, learnings, and reflections freely...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isNotEmpty && content.isNotEmpty) {
                        final provider = Provider.of<AppProvider>(context, listen: false);
                        if (existing == null) {
                          provider.addJournalEntry(
                            JournalEntry(
                              id: 'j_${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              content: content,
                              date: DateTime.now(),
                              mood: mood,
                            ),
                          );
                        } else {
                          existing.title = title;
                          existing.content = content;
                          existing.mood = mood;
                          provider.updateJournalEntry(existing);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(existing == null ? 'Save Entry' : 'Update Entry', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
