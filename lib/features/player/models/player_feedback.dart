/// Suggested feedback categories for POST /player/feedback
const playerFeedbackCategories = [
  'Training Session',
  'Drill Assignment',
  'Team Communication',
  'Facilities',
  'Recovery & Rest',
  'Other',
];

/// Screen #11 — Provide Player Feedback
class PlayerFeedbackPayload {
  const PlayerFeedbackPayload({
    required this.category,
    required this.feedback,
    this.coachId,
  });

  final String category;
  final String feedback;
  final int? coachId;

  Map<String, dynamic> toJson() => {
        'category': category,
        'feedback': feedback,
        if (coachId != null) 'coach_id': coachId,
      };
}

class PlayerFeedback {
  const PlayerFeedback({
    required this.id,
    required this.category,
    required this.feedback,
    required this.submittedAt,
  });

  final String id;
  final String category;
  final String feedback;
  final String submittedAt;

  factory PlayerFeedback.fromJson(Map<String, dynamic> json) {
    return PlayerFeedback(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      feedback: json['feedback']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }
}
