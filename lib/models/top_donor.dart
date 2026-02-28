class TopDonor {
  final int userId;
  final String name;
  final double totalAmount;
  final String? avatarUrl;

  TopDonor({
    required this.userId,
    required this.name,
    required this.totalAmount,
    this.avatarUrl,
  });

  factory TopDonor.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric values that might be delivered as strings.
    double _parseFlexibleDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final amountValue = json['total_amount'] ?? json['amount'];
    final userName = json['user']?['name'] ?? json['name'];
    final userAvatar = json['user']?['passport_picture'] ?? json['passport_picture'];

    return TopDonor(
      userId: json['user_id'] as int? ?? json['user']?['id'] as int? ?? 0,
      name: userName as String? ?? 'Anonymous',
      totalAmount: _parseFlexibleDouble(amountValue),
      avatarUrl: userAvatar as String?,
    );
  }
}
