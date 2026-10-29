import 'package:http/http.dart' as http;

/// Turns an exception into a sentence for the screen: no "Exception:"
/// prefix, and a plain "check your connection" when the phone can't reach
/// the server at all (HIG: say what went wrong and what to do about it).
String friendlyError(Object error) {
  if (error is http.ClientException) {
    return "Couldn't reach the server. Check your connection and try again.";
  }
  final text = '$error'.replaceFirst(RegExp(r'^Exception:\s*'), '');
  return text.isEmpty ? 'Something went wrong. Try again.' : text;
}
