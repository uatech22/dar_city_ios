import 'package:dar_city_app/features/shared/json_parse.dart';

/// Screens #15, #16, #17 — Discipline
class DisciplineSummary {
  const DisciplineSummary({
    required this.tokenBalance,
    required this.salaryImpactLabel,
    required this.salaryImpactValue,
    required this.history,
  });

  final int tokenBalance;
  final String salaryImpactLabel;
  final String salaryImpactValue;
  final List<DisciplineHistoryItem> history;

  factory DisciplineSummary.fromJson(Map<String, dynamic> json) {
    return DisciplineSummary(
      tokenBalance: parseTokenBalance(json),
      salaryImpactLabel:
          json['salary_impact_label']?.toString() ?? 'Salary impact',
      salaryImpactValue: json['salary_impact_value']?.toString() ?? '—',
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => DisciplineHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Reads player merit token total from API (`people.token_balance` on backend).
int parseTokenBalance(Map<String, dynamic> json) {
  for (final key in const [
    'token_balance',
    'tokens',
    'balance',
    'merit_tokens',
    'current_tokens',
  ]) {
    final value = json[key];
    if (value == null) continue;
    try {
      return intFromJson(value);
    } catch (_) {}
  }
  final nested = json['player'];
  if (nested is Map<String, dynamic>) {
    return parseTokenBalance(nested);
  }
  return 0;
}

class DisciplineHistoryItem {
  const DisciplineHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tokenChange,
    required this.isPenalty,
    required this.iconKey,
    this.tokens,
    this.totalAmount,
    this.currency,
    this.penaltyStatus,
  });

  final String id;
  final String title;
  final String subtitle;
  final String tokenChange;
  final bool isPenalty;
  final String iconKey;
  final int? tokens;
  final int? totalAmount;
  final String? currency;
  final String? penaltyStatus;

  factory DisciplineHistoryItem.fromJson(Map<String, dynamic> json) {
    return DisciplineHistoryItem(
      id: uuidFromJson(json['id']),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      tokenChange: json['token_change'] as String,
      isPenalty: json['is_penalty'] as bool? ?? false,
      iconKey: json['icon_key'] as String? ?? 'default',
      tokens: intFromJsonNullable(json['tokens']),
      totalAmount: intFromJsonNullable(json['total_amount']),
      currency: json['currency'] as String?,
      penaltyStatus: json['status'] as String?,
    );
  }
}

class IssuePenaltyResult {
  const IssuePenaltyResult({
    required this.message,
    this.penaltyId,
    this.tokensDeducted,
    this.newTokenBalance,
  });

  final String message;
  final String? penaltyId;
  final int? tokensDeducted;
  final int? newTokenBalance;

  factory IssuePenaltyResult.fromJson(Map<String, dynamic> json) {
    return IssuePenaltyResult(
      message: json['message'] as String? ?? 'Penalty issued',
      penaltyId: json['penalty_id']?.toString(),
      tokensDeducted: json['tokens_deducted'] as int?,
      newTokenBalance: json['new_token_balance'] as int?,
    );
  }
}

class IssuePenaltyPayload {
  const IssuePenaltyPayload({
    required this.playerId,
    required this.infraction,
    required this.tokens,
    this.notes,
  });

  final int playerId;
  final String infraction;
  final int tokens;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'infraction': infraction,
        'tokens': tokens,
        if (notes != null) 'notes': notes,
      };
}

class PerformanceAlert {
  const PerformanceAlert({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.accentKey,
    required this.iconKey,
    this.showProgress,
    this.progressValue,
  });

  final String id;
  final String category;
  final String title;
  final String message;
  final String timestamp;
  final String accentKey;
  final String iconKey;
  final bool? showProgress;
  final double? progressValue;

  factory PerformanceAlert.fromJson(Map<String, dynamic> json) {
    return PerformanceAlert(
      id: uuidFromJson(json['id']),
      category: json['category'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] as String,
      accentKey: json['accent_key'] as String? ?? 'default',
      iconKey: json['icon_key'] as String? ?? 'default',
      showProgress: json['show_progress'] as bool?,
      progressValue: (json['progress_value'] as num?)?.toDouble(),
    );
  }

  /// Coach/system audit entries — not shown in the player app.
  bool get isPlayerFacing {
    final cat = category.toUpperCase().trim();
    if (cat.contains('SYSTEM LOG') || cat == 'SYSTEM' || cat.contains('AUDIT')) {
      return false;
    }
    return true;
  }
}
