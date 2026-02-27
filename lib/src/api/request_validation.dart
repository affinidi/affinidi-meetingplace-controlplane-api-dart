import '../utils/date_time.dart';

class RequestValidation {
  static bool isValidUri(String uri) {
    return Uri.tryParse(uri) != null;
  }

  static bool isValidDateTime(String? value) {
    if (value == null || value.isEmpty) return true;
    final iso8601UtcPattern =
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$';
    final iso8601UtcRegex = RegExp(iso8601UtcPattern);
    if (!iso8601UtcRegex.hasMatch(value)) return false;
    try {
      final parsedDate = DateTime.parse(value);
      if (!parsedDate.isUtc) return false;
      if (parsedDate.isBefore(nowUtc())) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
