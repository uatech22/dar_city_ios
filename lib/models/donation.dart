class Donation {
  final int id;
  final String referenceCode;
  final double amount;
  final String status;

  Donation({
    required this.id,
    required this.referenceCode,
    required this.amount,
    required this.status,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as int,
      referenceCode: json['reference_code'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
