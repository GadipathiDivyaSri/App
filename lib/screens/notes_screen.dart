import 'package:flutter/material.dart';
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
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () => _showAddJournalDialog(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          if (_journalEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'No journal entries written yet.\nTap + or click below to record your first entry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
              ),
            )
          else
            ..._journalEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildJournalCard(context, item, index);
            }).toList(),

          // Dashed Quick Journal Entry Container
          GestureDetector(
            onTap: () => _showAddJournalDialog(context),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelGrowth,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : const Color(0xFFB4DEBF),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelGrowthIcon,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to write a quick journal entry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
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
