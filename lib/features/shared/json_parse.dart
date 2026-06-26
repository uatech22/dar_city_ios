/// Parse backend UUID / composite string IDs for V2 API models.
String uuidFromJson(dynamic value) {
  if (value == null) {
    throw FormatException('Expected non-null UUID id');
  }
  return value.toString();
}

/// Parse integer person / legacy IDs (API may return int or string).
int intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String && value.isNotEmpty) return int.parse(value);
  throw FormatException('Expected int id, got $value');
}

int? intFromJsonNullable(dynamic value) {
  if (value == null) return null;
  return intFromJson(value);
}
