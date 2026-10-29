// Parses responses captured from the real backend (test/fakeBackend.js in
// the API repo, replaying the 2026-10-24 USNJSOM1 meet paused at 13:20 with
// meet mode on), so the app and server agree on the shape.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/models/ftc_live.dart';
import 'package:task_tracker/services/api_service.dart';
import 'package:task_tracker/widgets/match_card.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('meet list: ours starred, meet mode shown', () {
    final list = MeetList.fromJson(fixture('meets.json'));
    expect(list.ourTeam, 13115);
    expect(list.events.map((e) => e.code), ['USNJSOM1', 'USNJSOM4']);
    expect(list.events.first.weAttend, isTrue);
    expect(list.events.first.isActive, isTrue);
    expect(list.events.first.dateStart, DateTime(2026, 10, 24));
    expect(list.active?.eventName, 'P1-1 Southern League Meet');
  });

  test('meet detail: every match, our next one with its estimated start', () {
    final meet = MeetDetail.fromJson(fixture('meet_usnjsom1.json'));
    expect(meet.matches, hasLength(21));
    expect(meet.matches.where((m) => m.hasBeenPlayed), hasLength(6));
    expect(meet.isActive, isTrue);
    expect(meet.waitingForFirstMatch, isFalse);

    final next = meet.ourNextMatch!;
    expect(next.shortLabel, 'Q9');
    expect(next.allianceOf(13115), isNotNull);
    expect(next.estimatedStartTime, DateTime(2026, 10, 24, 13, 37));
    // intl puts a narrow no-break space before AM/PM.
    expect(matchTimeLabel(next).replaceAll('\u202f', ' '), '~1:37 PM');

    final first = meet.matches.first;
    expect(first.winningAlliance, 'Red'); // 48-29
    expect(matchTimeLabel(first), startsWith('Posted '));
    expect(first.teamsOn('Red'), hasLength(2));
  });

  test('active meet: parsed, and no meet comes back as null', () async {
    final active = ActiveMeet.fromJson(fixture('meet_active.json')['active'] as Map<String, dynamic>);
    expect(active.eventName, 'P1-1 Southern League Meet');
    expect(active.nextMatch?.estimatedStartTime, DateTime(2026, 10, 24, 13, 37));

    ApiService.sessionToken = 'tok';
    String? auth;
    await http.runWithClient(() async {
      expect(await ApiService().fetchActiveMeet(), isNull);
    }, () => MockClient((request) async {
          auth = request.headers['Authorization'];
          return http.Response('{"active":null}', 200);
        }));
    expect(auth, 'Bearer tok');
    ApiService.sessionToken = null;
  });
}
