// Fed the real backend's responses for team 13115 (captured from the API
// repo's fake backend, see test/fixtures/team_13115.json and team_search.json).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/screens/match_detail_screen.dart';
import 'package:task_tracker/screens/team_lookup_screen.dart';
import 'package:task_tracker/theme/app_theme.dart';
import 'package:task_tracker/widgets/match_card.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  testWidgets('searching by name shows the team, and a match opens its detail screen', (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/teams/search')) return http.Response(fixture('team_search.json'), 200);
      if (path.contains('/matches/')) return http.Response(fixture('match_q1.json'), 200);
      if (path.contains('/teams/13115')) return http.Response(fixture('team_13115.json'), 200);
      return http.Response('{"error":"unexpected"}', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const TeamLookupScreen()));

      await tester.enterText(find.byType(TextField), 'brave');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('Brave Robotics'), findsWidgets);
      expect(find.text('Englishtown, NJ, USA'), findsOneWidget);
      expect(find.byType(MatchCard), findsWidgets);

      await tester.tap(find.byType(MatchCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(MatchDetailScreen), findsOneWidget);
    }, () => client);
  });

  testWidgets('searching by number with no name skips straight to the team', (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/teams/search')) {
        return http.Response('{"results":[{"number":13115,"name":null}]}', 200);
      }
      return http.Response(fixture('team_13115.json'), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const TeamLookupScreen()));
      await tester.enterText(find.byType(TextField), '13115');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.textContaining('Brave Robotics'), findsWidgets);
    }, () => client);
  });

  testWidgets('a team with no events this season says so', (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/teams/search')) return http.Response('{"results":[{"number":1,"name":null}]}', 200);
      return http.Response(
        '{"season":2026,"teamNumber":1,"info":{"teamNumber":1},"events":[]}',
        200,
      );
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const TeamLookupScreen()));
      await tester.enterText(find.byType(TextField), '1');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.textContaining('No matches found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
