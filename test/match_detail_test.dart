// The match screen, fed the real backend's response for USNJSOM1 Q8
// (captured from the API repo's fake backend; numbers match
// https://ftc-events.firstinspires.org/2026/USNJSOM1/qualifications/8).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/models/ftc_live.dart';
import 'package:task_tracker/screens/match_detail_screen.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/widgets/match_card.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

Future<void> showMatch(WidgetTester tester, String fixtureName, {double textScale = 1.0}) async {
  // A small phone: 360 x 740 logical pixels.
  tester.view.physicalSize = const Size(360, 740) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final client = MockClient((_) async => http.Response(fixture(fixtureName), 200));
  await http.runWithClient(() async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: const MatchDetailScreen(season: 2026, code: 'USNJSOM1', matchKey: 'QUALIFICATION-0-8'),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }, () => client);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('Q8: winner, ranking points, comparison, robots, flowers', (tester) async {
    final semantics = tester.ensureSemantics();
    await showMatch(tester, 'match_q8.json');

    expect(find.text('Qualification 8'), findsOneWidget);
    expect(find.text('WINNER'), findsOneWidget); // red, 37-26
    expect(find.text('37'), findsWidgets);
    expect(find.text('Auto 3 · TeleOp 34 · Pen 0'), findsOneWidget);
    expect(find.text('Auto 8 · TeleOp 18 · Pen 0'), findsOneWidget);

    // Red won without SWARM; blue lost but earned it.
    await scrollTo(tester, find.text('+1 RP'));
    expect(find.text('+3 RP'), findsOneWidget);
    expect(find.text('+1 RP'), findsOneWidget);
    // A Card reads as one node to screen readers, so these are parts of its label.
    expect(find.bySemanticsLabel(RegExp('SWARM ranking point earned')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('SWARM ranking point not earned')), findsOneWidget);

    await scrollTo(tester, find.text('Penalties from opponent'));
    expect(find.text('TeleOp Hive'), findsOneWidget);

    await scrollTo(tester, find.text('Robot 1 · 36975'));
    expect(find.bySemanticsLabel(RegExp('Auto leave: yes')), findsWidgets);

    await scrollTo(tester, find.text('Audience'));
    expect(find.text('Empty'), findsNWidgets(4));
    semantics.dispose();
  });

  testWidgets('fits a small phone at 2x text size (panels stack)', (tester) async {
    await showMatch(tester, 'match_q8.json', textScale: 2.0);
    expect(tester.takeException(), isNull);
    // Stacked: blue's panel is below red's, not beside it.
    expect(tester.getTopLeft(find.text('BLUE')).dy, greaterThan(tester.getBottomLeft(find.text('RED')).dy));
    await scrollTo(tester, find.text('Audience'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a match without a posted breakdown says so', (tester) async {
    await showMatch(tester, 'match_q1.json');
    expect(find.text('+3 RP so far'), findsOneWidget);
    expect(find.textContaining("hasn't posted the full breakdown"), findsOneWidget);
  });

  testWidgets('match cards fit a small phone at 2x text size', (tester) async {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final meet = MeetDetail.fromJson(jsonDecode(fixture('meet_usnjsom1.json')) as Map<String, dynamic>);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: Scaffold(
          body: ListView(children: [
            for (final m in meet.matches.take(8)) MatchCard(match: m, ourTeam: 13115, onTap: () {}),
          ]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
