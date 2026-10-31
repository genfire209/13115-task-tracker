// Guards for the design pass (Apple HIG review, 2026-10-29): contrast of the
// theme's text-on-color pairs, the bottom tab bar per role, task cards at
// large text sizes, and Reduce Motion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/user.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/services/auth_service.dart';
import 'package:task_tracker/state/task_repository.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/widgets/pulsing_badge.dart';
import 'package:task_tracker/widgets/task_list.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Color tint(Color c, double alpha, Color over) => Color.alphaBlend(c.withValues(alpha: alpha), over);

class FakeAuth extends AuthService {
  FakeAuth(this.user);
  final AppUser user;
  @override
  AppUser? get currentUser => user;
  @override
  bool get isLoggedIn => true;
  @override
  bool get isRestoring => false;
}

AppUser person({UserRole role = UserRole.member, bool junior = false}) => AppUser(
      id: 'a@x.com',
      name: 'A',
      email: 'a@x.com',
      authProvider: 'google',
      role: role,
      isJunior: junior,
      subteams: const [Subteam.systemIntegration],
    );

/// Shows HomeScreen for [user] with an empty fake backend, then runs [then]
/// (still inside the fake backend, so any screen it opens loads from it too).
Future<void> pumpHome(WidgetTester tester, AppUser user, [Future<void> Function()? then]) async {
  await http.runWithClient(() async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: FakeAuth(user)),
        ChangeNotifierProvider(create: (_) => TaskRepository()),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    await then?.call();
  }, () => MockClient((r) async => http.Response(r.url.path.endsWith('/active') ? '{"active":null}' : '[]', 200)));
}

List<String> tabLabels(WidgetTester tester) =>
    tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((d) => d.label).toList();

Task task(TaskStatus status) => Task(
      id: 't',
      title: 'Re-tension intake belts on the left side',
      description: '',
      category: TaskCategory.mechanical,
      createdBy: 'c',
      assignedTo: 'a@x.com',
      status: status,
      dueDate: DateTime(2030),
    );

void main() {
  test('white button labels and status chips meet 4.5:1', () {
    expect(contrast(Colors.white, AppTheme.primaryFill), greaterThanOrEqualTo(4.5));
    expect(contrast(AppTheme.primary, AppTheme.surface), greaterThanOrEqualTo(4.5));
    for (final s in TaskStatus.values) {
      final c = AppTheme.statusColor(s);
      expect(contrast(c, tint(c, 0.18, AppTheme.surface)), greaterThanOrEqualTo(4.5), reason: '$s');
    }
  });

  testWidgets('members get Tasks, Meets, Team, Profile tabs', (tester) async {
    await pumpHome(tester, person());
    expect(tabLabels(tester), ['Tasks', 'Meets', 'Team', 'Profile']);
  });

  testWidgets('juniors get no Team tab', (tester) async {
    await pumpHome(tester, person(junior: true));
    expect(tabLabels(tester), ['Tasks', 'Meets', 'Profile']);
  });

  testWidgets('a captain\'s Team tab is the captain portal', (tester) async {
    await pumpHome(tester, person(role: UserRole.captain), () async {
      await tester.tap(find.text('Team'));
      await tester.pump(const Duration(milliseconds: 200));
    });
    expect(find.text('Captain portal'), findsOneWidget);
  });

  testWidgets('task cards fit a small phone at 2x text', (tester) async {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: Scaffold(
          body: TaskList(
            tasks: [task(TaskStatus.pendingAcceptance), task(TaskStatus.inProgress)],
            nameFor: (id) => 'Sam Builder',
            showCategoryLabel: true,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion: no pulsing, no slide-in', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: TaskList(tasks: [task(TaskStatus.pendingAcceptance)], nameFor: (id) => id, showCategoryLabel: true),
        ),
      ),
    ));
    expect(find.descendant(of: find.byType(PulsingBadge), matching: find.byType(ScaleTransition)), findsNothing);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0); // no animation ticking
  });
}
