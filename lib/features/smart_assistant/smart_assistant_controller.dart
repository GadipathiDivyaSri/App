import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';
import 'command_models.dart';
import 'smart_assistant_service.dart';

class SmartAssistantController extends ChangeNotifier {
  final List<AssistantMessage> _messages = [];
  List<AssistantMessage> get messages => List.unmodifiable(_messages);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  ConversationContext? _activeContext;
  ConversationContext? get activeContext => _activeContext;

  SmartAssistantController() {
    _initWelcome();
  }

  void _initWelcome() {
    _messages.add(
      AssistantMessage(
        id: 'msg_welcome',
        text: 'Hi! I\'m your **Wrindha Smart Assistant** 👋\n'
            'I can help you manage your tasks, habits, goals, schedule, expenses and more. Just tell me what you want to do.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: [
          'What should I do now?',
          'Plan my day',
          'Show my tasks',
          'Mark habit completed',
          'Show my progress',
          'Check Deadlines',
          'Study Summary',
          'New Task',
        ],
      ),
    );
  }

  /// Send a user message and trigger rule engine execution
  Future<void> sendMessage(String text, AppProvider provider) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    // 1. Add user message to thread
    final userMsg = AssistantMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isProcessing = true;
    notifyListeners();

    // 2. Micro delay for smooth natural assistant cadence
    await Future.delayed(const Duration(milliseconds: 250));

    // 3. Process via SmartAssistantService
    try {
      final responses = SmartAssistantService.processMessage(
        userText: clean,
        provider: provider,
        currentContext: _activeContext,
      );

      _activeContext = null; // Clear context after completion
      for (final resp in responses) {
        _messages.add(resp);
      }
    } catch (e) {
      _messages.add(
        AssistantMessage(
          id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
          text: 'I ran into an issue processing that. Please try rephrasing your request.',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: ['What should I do now?', 'Show my tasks'],
        ),
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Handle interactive button tap
  void handleActionPayload(String payload, AppProvider provider) {
    final response = SmartAssistantService.processPayload(
      payload: payload,
      provider: provider,
    );
    _messages.add(response);
    notifyListeners();
  }

  /// Clear session chat history
  void clearChat() {
    _messages.clear();
    _activeContext = null;
    _initWelcome();
    notifyListeners();
  }
}
