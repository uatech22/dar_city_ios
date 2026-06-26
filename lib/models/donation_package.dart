class DonationPackage {
  final int id;
  final String name;
  final double amount;
  final String description;

  DonationPackage({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
  });

  factory DonationPackage.fromJson(Map<String, dynamic> json) {
    return DonationPackage(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }
}
