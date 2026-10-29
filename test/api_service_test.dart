import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_tracker/services/api_service.dart';

void main() {
  tearDown(() => ApiService.sessionToken = null);

  test('login keeps the session token and every later request sends it', () async {
    final seen = <http.BaseRequest>[];
    final client = MockClient((request) async {
      seen.add(request);
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'id': 'a@x.com',
            'name': 'A',
            'email': 'a@x.com',
            'authProvider': 'google',
            'role': 'member',
            'subteams': ['programming'],
            'sessionToken': 'tok-123',
          }),
          200,
        );
      }
      return http.Response('[]', 200);
    });

    await http.runWithClient(() async {
      final api = ApiService();
      await api.login(provider: 'google', idToken: 'google-id-token');
      await api.fetchTasks();
      await api.approveUser('b@x.com');
    }, () => client);

    expect(ApiService.sessionToken, 'tok-123');
    expect(seen.first.headers['Authorization'], isNull);
    for (final request in seen.skip(1)) {
      expect(request.headers['Authorization'], 'Bearer tok-123', reason: request.url.path);
    }
  });

  test('an expired session reads as signed out', () async {
    final client = MockClient((_) async => http.Response('{"error":"Session expired"}', 401));
    ApiService.sessionToken = 'old';
    await http.runWithClient(() async {
      await expectLater(ApiService().fetchUserById('a@x.com'), throwsA(isA<ApiUserGoneException>()));
    }, () => client);
  });
}
