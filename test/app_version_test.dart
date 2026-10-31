// Forced updates: the app sends its build with every request, a 426 from
// the server locks the whole app behind UpdateRequiredScreen, and admins
// can require the build their phone is on from Profile.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/app_version.dart';
import 'package:task_tracker/screens/profile_screen.dart';
import 'package:task_tracker/screens/update_required_screen.dart';
import 'package:task_tracker/services/api_service.dart';
import 'package:task_tracker/theme/app_theme.dart';

/// A fake server that requires [minimum] and records what it was sent.
class FakeServer {
  FakeServer(this.minimum);
  int minimum;
  final requests = <http.Request>[];

  MockClient get client => MockClient((r) async {
        requests.add(r);
        if (r.url.path.endsWith('/app-version')) {
          if (r.method == 'PUT') minimum = (jsonDecode(r.body) as Map)['minimumBuild'] as int;
          return http.Response(jsonEncode({'minimumBuild': minimum}), 200);
        }
        final build = int.tryParse(r.headers['X-App-Build'] ?? '') ?? 0;
        if (build < minimum) return http.Response('{"error":"out of date","updateRequired":true}', 426);
        return http.Response('[]', 200);
      });
}

void main() {
  setUp(() {
    AppVersion.build = 9;
    AppVersion.updateRequired.value = false;
  });

  test('every request carries the build number', () async {
    final server = FakeServer(0);
    await http.runWithClient(() async {
      await ApiService().fetchTasks();
      await ApiService().fetchUsers();
    }, () => server.client);
    expect(server.requests.map((r) => r.headers['X-App-Build']), ['9', '9']);
  });

  test('a 426 from any request locks the app', () async {
    AppVersion.build = 8;
    final server = FakeServer(9);
    await http.runWithClient(() async {
      await expectLater(ApiService().fetchTasks(), throwsA(isA<UpdateRequiredException>()));
    }, () => server.client);
    expect(AppVersion.updateRequired.value, isTrue);
  });

  test('the check at launch compares this build with the minimum', () async {
    final server = FakeServer(10);
    await http.runWithClient(AppVersion.check, () => server.client);
    expect(AppVersion.updateRequired.value, isTrue);
    server.minimum = 9; // an admin lowered it again
    await http.runWithClient(AppVersion.check, () => server.client);
    expect(AppVersion.updateRequired.value, isFalse);
  });

  testWidgets('the update screen covers every screen, and fits at 2x text', (tester) async {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: lockWhenUpdateRequired(context, child),
        ),
        home: const Scaffold(body: Text('Task board')),
      ));
      expect(find.text('Task board'), findsOneWidget);

      AppVersion.updateRequired.value = true;
      await tester.pump();
      expect(find.text('Task board'), findsNothing);
      expect(find.text('Update required'), findsOneWidget);
      expect(find.textContaining('TestFlight'), findsOneWidget); // iOS: TestFlight, not the Play Store
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android sees Play Store instructions, not TestFlight', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => lockWhenUpdateRequired(context, child),
        home: const Scaffold(body: Text('Task board')),
      ));
      AppVersion.updateRequired.value = true;
      await tester.pump();
      expect(find.textContaining('Play Store'), findsOneWidget);
      expect(find.textContaining('TestFlight'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('an admin requires the build on their phone, after confirming', (tester) async {
    final server = FakeServer(8);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: RequiredVersionCard()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('This app: build 9. Required: build 8 or newer.'), findsOneWidget);

      await tester.tap(find.text('Require build 9'));
      await tester.pumpAndSettle();
      expect(find.text('Require build 9?'), findsOneWidget);
      await tester.tap(find.text('Require update'));
      await tester.pumpAndSettle();
    }, () => server.client);

    expect(server.minimum, 9);
    expect(find.textContaining('Required: build 9 or newer.'), findsOneWidget);
    expect(find.text('Require build 9'), findsNothing); // already required
    expect(find.text('Allow older builds'), findsOneWidget);
  });
}
