// Members get teammates' names but not their emails: other people's ids
// arrive as 'u_...' stand-ins and the roster's email field is empty.
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/user.dart';
import 'package:task_tracker/state/task_repository.dart';

void main() {
  test('a roster entry with an empty or missing email still parses', () {
    for (final json in [
      {'id': 'u_AbCdEfGhIjKlMnOp', 'name': 'Alice', 'email': '', 'authProvider': 'google', 'role': 'member'},
      {'id': 'u_AbCdEfGhIjKlMnOp', 'name': 'Alice', 'authProvider': 'google', 'role': 'member'},
    ]) {
      final user = AppUser.fromJson(json);
      expect(user.name, 'Alice');
      expect(user.email, '');
    }
  });

  test("someone not on the roster shows as a teammate, not a code", () {
    final repo = TaskRepository();
    expect(repo.nameFor('u_AbCdEfGhIjKlMnOp'), 'A teammate');
    expect(repo.nameFor('someone@x.com'), 'someone@x.com');
  });
}
