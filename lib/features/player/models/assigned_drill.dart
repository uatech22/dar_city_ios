import 'package:dar_city_app/features/shared/json_parse.dart';

/// Drill assignment status values from API spec.
const drillAssignmentStatuses = [
  'pending',
  'in_progress',
  'completed',
  'overdue',
];

/// Screens #8, #9 — Player drills
class AssignedDrill {
  const AssignedDrill({
    required this.assignmentId,
    required this.drillId,
    required this.drillName,
    required this.dueDate,
    required this.reps,
    required this.sets,
    required this.timeMinutes,
    required this.status,
  });

  final String assignmentId;
  final String drillId;
  final String drillName;
  final String dueDate;
  final int reps;
  final int sets;
  final int timeMinutes;
  final String status;

  factory AssignedDrill.fromJson(Map<String, dynamic> json) {
    return AssignedDrill(
      assignmentId: uuidFromJson(json['assignment_id']),
      drillId: uuidFromJson(json['drill_id']),
      drillName: json['drill_name'] as String,
      dueDate: json['due_date'] as String,
      reps: json['reps'] as int,
      sets: json['sets'] as int,
      timeMinutes: json['time_minutes'] as int,
      status: json['status'] as String,
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

  bool get isCompleted => status == 'completed';
}

class DrillCompletionItem {
  const DrillCompletionItem({
    required this.assignmentId,
    required this.title,
    required this.category,
    required this.isCompleted,
  });

  final String assignmentId;
  final String title;
  final String category;
  final bool isCompleted;

  factory DrillCompletionItem.fromJson(Map<String, dynamic> json) {
    return DrillCompletionItem(
      assignmentId: uuidFromJson(json['assignment_id']),
      title: json['title'] as String,
      category: json['category'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

class MarkDrillCompletePayload {
  const MarkDrillCompletePayload({
    required this.assignmentIds,
    this.notes,
  });

  final List<String> assignmentIds;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'assignment_ids': assignmentIds,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class PlayerDrillSummary {
  const PlayerDrillSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.overdue,
    this.nextDueDate,
  });

  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int overdue;
  final String? nextDueDate;

  int get completionPercent =>
      total == 0 ? 0 : ((completed / total) * 100).round();

  factory PlayerDrillSummary.fromDrills(List<AssignedDrill> drills) {
    var completed = 0;
    var pending = 0;
    var inProgress = 0;
    var overdue = 0;
    String? nextDue;

    for (final drill in drills) {
      switch (drill.status) {
        case 'completed':
          completed++;
        case 'in_progress':
          inProgress++;
        case 'overdue':
          overdue++;
        default:
          pending++;
      }
      if (!drill.isCompleted) {
        if (nextDue == null || drill.dueDate.compareTo(nextDue) < 0) {
          nextDue = drill.dueDate;
        }
      }
    }

    return PlayerDrillSummary(
      total: drills.length,
      completed: completed,
      pending: pending,
      inProgress: inProgress,
      overdue: overdue,
      nextDueDate: nextDue,
    );
  }
}
