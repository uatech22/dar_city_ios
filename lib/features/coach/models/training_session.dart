import 'package:dar_city_app/features/shared/json_parse.dart';

/// Screen #7 — Manage Training Session
class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.title,
    required this.location,
    this.scheduledAt,
    this.focus,
    this.description,
    this.startDate,
    this.endDate,
    this.numberOfDays,
    this.durationMinutes,
    this.intensity,
    this.type,
    this.teamId,
    this.teamName,
    this.coachId,
    this.coachName,
    this.isPast = false,
  });

  final String id;
  final String title;
  final String location;
  final String? scheduledAt;
  final String? focus;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int? numberOfDays;
  final int? durationMinutes;
  final String? intensity;
  final String? type;
  final int? teamId;
  final String? teamName;
  final int? coachId;
  final String? coachName;
  final bool isPast;

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: uuidFromJson(json['id']),
      title: json['title'] as String? ?? 'Session',
      location: json['location'] as String? ?? '',
      scheduledAt: json['scheduled_at'] as String?,
      focus: json['focus'] as String?,
      description: json['description'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      numberOfDays: intFromJsonNullable(json['number_of_days']),
      durationMinutes: intFromJsonNullable(json['duration_minutes']),
      intensity: json['intensity'] as String?,
      type: json['type'] as String?,
      teamId: intFromJsonNullable(json['team_id']),
      teamName: json['team_name'] as String?,
      coachId: intFromJsonNullable(json['coach_id']),
      coachName: json['coach_name'] as String?,
      isPast: json['is_past'] as bool? ?? false,
    );
  }

  String get subtitle {
    final parts = <String>[location];
    if (type != null && type!.isNotEmpty) parts.add(_label(type!));
    if (scheduledAt != null && scheduledAt!.length >= 16) {
      parts.add(scheduledAt!.substring(0, 16).replaceFirst('T', ' '));
    } else if (startDate != null) {
      parts.add(startDate!);
    }
    return parts.join(' · ');
  }

  String? get metaLine {
    final parts = <String>[];
    if (teamName != null && teamName!.isNotEmpty) parts.add(teamName!);
    if (coachName != null && coachName!.isNotEmpty) parts.add(coachName!);
    if (numberOfDays != null && numberOfDays! > 1) {
      parts.add('$numberOfDays days');
    }
    if (durationMinutes != null) parts.add('$durationMinutes min');
    if (intensity != null && intensity!.isNotEmpty) {
      parts.add(_label(intensity!));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _label(String value) =>
      value[0].toUpperCase() + value.substring(1);
}

/// Backend validation enums for POST /coach/training-sessions
const trainingSessionTypes = [
  'fitness',
  'shooting',
  'tactics',
  'scrimmage',
  'recovery',
];

const trainingSessionIntensities = ['low', 'medium', 'high'];

class CreateTrainingSessionPayload {
  const CreateTrainingSessionPayload({
    required this.title,
    required this.location,
    this.scheduledAt,
    this.focus,
    this.description,
    this.startDate,
    this.endDate,
    this.durationMinutes,
    this.intensity,
    this.type,
    this.teamId,
    this.coachId,
  });

  final String title;
  final String location;
  final String? scheduledAt;
  final String? focus;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int? durationMinutes;
  final String? intensity;
  final String? type;
  final int? teamId;
  final int? coachId;

  Map<String, dynamic> toJson() => {
        'title': title,
        'location': location,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        if (focus != null) 'focus': focus,
        if (description != null) 'description': description,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (intensity != null) 'intensity': intensity,
        if (type != null) 'type': type,
        if (teamId != null) 'team_id': teamId,
        if (coachId != null) 'coach_id': coachId,
      };
}

DateTime? parseTrainingSessionDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Each calendar day between session start and end (inclusive).
List<DateTime> trainingSessionDates(TrainingSession session) {
  var start = parseTrainingSessionDate(session.startDate);
  var end = parseTrainingSessionDate(session.endDate);

  if (start == null && session.scheduledAt != null && session.scheduledAt!.length >= 10) {
    start = parseTrainingSessionDate(session.scheduledAt!.substring(0, 10));
  }
  if (start == null) {
    return [_dateOnly(DateTime.now())];
  }

  start = _dateOnly(start);
  end = end != null ? _dateOnly(end) : start;
  if (end.isBefore(start)) end = start;

  final days = <DateTime>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    days.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
    if (days.length > 366) break;
  }
  return days;
}

String formatSessionDateIso(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

CreateTrainingSessionPayload trainingSessionToPayload(TrainingSession session) {
  return CreateTrainingSessionPayload(
    title: session.title,
    location: session.location,
    scheduledAt: session.scheduledAt,
    focus: session.focus,
    description: session.description,
    startDate: session.startDate,
    endDate: session.endDate,
    durationMinutes: session.durationMinutes,
    intensity: session.intensity,
    type: session.type,
    teamId: session.teamId,
    coachId: session.coachId,
  );
}
