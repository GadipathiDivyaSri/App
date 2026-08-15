import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppProvider initialization test', () async {
    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(provider.user.name, 'Student User');
    expect(provider.user.focusScore, 0);
    expect(provider.user.activeStreak, 0);
    expect(provider.tasks.length, 0); // Zero predefined data start!
  });

  test('Adding task updates task list', () async {
    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(provider.tasks.length, 0);

    provider.addTask('New Test Task', 'Studies', 'Today');
    expect(provider.tasks.length, 1);
    expect(provider.tasks.last.title, 'New Test Task');
  });

  test('Toggling task completion recalculates metrics', () async {
    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 100));

    provider.addTask('Metric Test Task', 'Career', 'Today');
    final firstTask = provider.tasks.first;
    final initialCompletedState = firstTask.isCompleted;

    provider.toggleTaskCompletion(firstTask.id);
    expect(firstTask.isCompleted, !initialCompletedState);
  });
}
