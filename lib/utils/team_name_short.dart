/// Fan-facing short team labels (e.g. DAR @ UDS).
String shortTeamName(String fullName) {
  final name = fullName.trim();
  if (name.isEmpty || name == 'TBD') return 'TBD';

  final lower = name.toLowerCase();
  if (lower.contains('dar city') || lower.contains('darcity')) return 'DC';

  // Already a short code from API.
  if (name.length <= 4 && name == name.toUpperCase()) return name;

  final words = name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .where((w) => !_ignoredWord(w))
      .toList();

  if (words.isEmpty) return name.length <= 4 ? name.toUpperCase() : name.substring(0, 3).toUpperCase();

  if (words.length == 1) {
    final w = words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (w.length <= 4) return w.toUpperCase();
    return w.substring(0, 3).toUpperCase();
  }

  // Multi-word → acronym (OKC, LAL style), max 4 chars.
  return words
      .take(4)
      .map((w) => w.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .join()
      .toUpperCase();
}

bool _ignoredWord(String word) {
  const skip = {'the', 'of', 'fc', 'bc', 'bk', 'basketball', 'club'};
  return skip.contains(word.toLowerCase());
}

String teamNameFromApi(dynamic team, {String fallback = 'TBD'}) {
  if (team is Map) {
    for (final key in ['short_name', 'abbreviation', 'code', 'slug', 'name']) {
      final value = team[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        if (key == 'name') return shortTeamName(value);
        return value.toUpperCase();
      }
    }
    return fallback;
  }
  if (team is String && team.trim().isNotEmpty) {
    return shortTeamName(team);
  }
  return fallback;
}

String teamFullNameFromApi(dynamic team, {String fallback = 'TBD'}) {
  if (team is Map) {
    return team['name']?.toString().trim() ?? fallback;
  }
  if (team is String && team.trim().isNotEmpty) return team.trim();
  return fallback;
}
