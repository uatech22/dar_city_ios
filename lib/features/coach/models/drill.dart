import 'package:dar_city_app/features/shared/json_parse.dart';

/// Screens #4, #5, #6 — Drills
class Drill {
  const Drill({
    required this.id,
    required this.name,
    this.category,
    this.objective,
    this.equipment,
    this.setupInstructions,
    this.executionSteps,
    this.priority,
    this.trainingId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? category;
  final String? objective;
  final String? equipment;
  final String? setupInstructions;
  final String? executionSteps;
  final String? priority;
  final String? trainingId;
  final DateTime? createdAt;

  factory Drill.fromJson(Map<String, dynamic> json) {
    return Drill(
      id: uuidFromJson(json['id']),
      name: json['name'] as String,
      category: json['category'] as String?,
      objective: json['objective'] as String?,
      equipment: json['equipment'] as String?,
      setupInstructions: json['setup_instructions'] as String?,
      executionSteps: json['execution_steps'] as String?,
      priority: json['priority'] as String?,
      trainingId: json['training_id']?.toString(),
      createdAt: _parseDrillDate(json['created_at']),
    );
  }
}

DateTime? _parseDrillDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<Drill> filterDrillsBySession(List<Drill> drills, String? sessionId) {
  if (sessionId == null) return drills;
  return drills.where((d) => d.trainingId == sessionId).toList();
}

List<Drill> sortDrillsNewestFirst(List<Drill> drills) {
  if (drills.any((d) => d.createdAt != null)) {
    return List<Drill>.from(drills)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }
  return drills.reversed.toList();
}

int countHighPriorityDrills(List<Drill> drills) {
  return drills.where((d) => d.priority?.toLowerCase() == 'high').length;
}

class CreateDrillPayload {
  const CreateDrillPayload({
    required this.name,
    required this.objective,
    required this.equipment,
    required this.setupInstructions,
    required this.executionSteps,
    required this.priority,
    required this.trainingId,
  });

  final String name;
  final String objective;
  final String equipment;
  final String setupInstructions;
  final String executionSteps;
  final String priority;
  final String trainingId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'objective': objective,
        'equipment': equipment,
        'setup_instructions': setupInstructions,
        'execution_steps': executionSteps,
        'priority': priority,
        'training_id': trainingId,
      };
}

class DrillReminderPlayer {
  const DrillReminderPlayer({
    required this.playerId,
    required this.playerName,
    required this.status,
    this.avatarUrl,
  });

  final int playerId;
  final String playerName;
  final String status;
  final String? avatarUrl;

  factory DrillReminderPlayer.fromJson(Map<String, dynamic> json) {
    return DrillReminderPlayer(
      playerId: intFromJson(json['player_id']),
      playerName: json['player_name']?.toString() ?? 'Player',
      status: json['status']?.toString() ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  bool get needsReminder {
    final s = status.toLowerCase();
    return !s.contains('complete');
  }
}

/// Aggregated row for reminders list — built client-side from per-drill targets.
class DrillReminderOverviewItem {
  const DrillReminderOverviewItem({
    required this.drillId,
    required this.drillName,
    required this.playerId,
    required this.playerName,
    required this.status,
  });

  final String drillId;
  final String drillName;
  final int playerId;
  final String playerName;
  final String status;

  String get statusLabel => status;
}

class AssignDrillsPayload {
  const AssignDrillsPayload({
    required this.playerIds,
    required this.drillIds,
    required this.reps,
    required this.sets,
    required this.timeMinutes,
    required this.dueDate,
    this.trainingId,
  });

  final List<int> playerIds;
  final List<String> drillIds;
  final int reps;
  final int sets;
  final int timeMinutes;
  final String dueDate;
  final String? trainingId;

  Map<String, dynamic> toJson() => {
        'player_ids': playerIds,
        'drill_ids': drillIds,
        'reps': reps,
        'sets': sets,
        'time_minutes': timeMinutes,
        'due_date': dueDate,
        if (trainingId != null) 'training_id': trainingId,
      };
}

/// Coach view of team drill assignments — GET /coach/drills/assignments
class CoachDrillAssignment {
  const CoachDrillAssignment({
    required this.assignmentId,
    required this.drillId,
    required this.drillName,
    required this.playerId,
    required this.playerName,
    required this.dueDate,
    required this.reps,
    required this.sets,
    required this.timeMinutes,
    required this.status,
  });

  final String assignmentId;
  final String drillId;
  final String drillName;
  final int playerId;
  final String playerName;
  final String dueDate;
  final int reps;
  final int sets;
  final int timeMinutes;
  final String status;

  factory CoachDrillAssignment.fromJson(Map<String, dynamic> json) {
    return CoachDrillAssignment(
      assignmentId: uuidFromJson(json['assignment_id']),
      drillId: uuidFromJson(json['drill_id']),
      drillName: json['drill_name'] as String? ?? json['drill_title'] as String? ?? 'Drill',
      playerId: intFromJson(json['player_id']),
      playerName: json['player_name'] as String? ?? 'Player',
      dueDate: json['due_date'] as String? ?? '',
      reps: intFromJson(json['reps']),
      sets: intFromJson(json['sets']),
      timeMinutes: intFromJson(json['time_minutes']),
      status: json['status'] as String? ?? 'pending',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }
}
