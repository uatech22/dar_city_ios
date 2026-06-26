class Milestone {
  final int id;
  final String title;
  final String description;
  final double targetAmount;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      targetAmount: double.tryParse(json['target_amount'].toString()) ?? 0.0,
    );
  }
}
