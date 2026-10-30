// Parses responses captured from the real backend (test/fakeBackend.js in
// the API repo), so the app and server agree on the shape.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/models/ftc_live.dart';
import 'package:task_tracker/services/api_service.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  tearDown(() => ApiService.sessionToken = null);

  test('team search: a name resolves to a team number', () {
    final results = (fixture('team_search.json')['results'] as List<dynamic>)
        .map((j) => TeamSearchHit.fromJson(j as Map<String, dynamic>))
        .toList();
    expect(results, hasLength(1));
    expect(results.first.number, 13115);
    expect(results.first.name, 'Brave Robotics');
  });

  test('team lookup: info plus every event this season and its matches', () {
    final result = TeamLookupResult.fromJson(fixture('team_13115.json'));
    expect(result.teamNumber, 13115);
    expect(result.info.nameFull, 'Brave Robotics');
    expect(result.info.displayLocation, 'Englishtown, NJ, USA');
    expect(result.events, hasLength(1));

    final event = result.events.first;
    expect(event.code, 'USNJSOM1');
    expect(event.matches, hasLength(6));
    expect(event.matches.every((m) => m.involves(13115)), isTrue);
    expect(result.allMatches, hasLength(6));

    final first = result.allMatches.first;
    expect(first.allianceOf(13115), 'Blue');
    expect(first.winningAlliance, 'Red'); // 34-22
  });

  test('searchTeams and lookupTeam send the session token and parse the result', () async {
    ApiService.sessionToken = 'tok';
    String? searchPath;
    String? lookupPath;
    await http.runWithClient(() async {
      final api = ApiService();
      final hits = await api.searchTeams('brave');
      expect(hits.single.number, 13115);

      final result = await api.lookupTeam(teamNumber: 13115, season: 2026);
      expect(result.info.nameShort, 'Brave Robotics');
    }, () => MockClient((request) async {
          if (request.url.path.contains('/teams/search')) {
            searchPath = request.url.toString();
            return http.Response(jsonEncode(fixture('team_search.json')), 200);
          }
          lookupPath = request.url.toString();
          return http.Response(jsonEncode(fixture('team_13115.json')), 200);
        }));
    expect(searchPath, contains('q=brave'));
    expect(lookupPath, allOf(contains('/teams/13115'), contains('season=2026')));
  });
}
