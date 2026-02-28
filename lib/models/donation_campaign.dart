import 'package:dar_city_app/models/donation_milestone.dart';
import 'package:dar_city_app/models/donation_package.dart';
import 'package:dar_city_app/models/donation_reward.dart';

class DonationCampaign {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final double targetAmount;
  final double totalRaised;
  final double percentage;
  final int donorCount;
  final double remainingAmount;
  final DateTime endDate;
  final bool isFeatured;
  final List<DonationPackage> packages;
  final List<Reward> rewards;
  final List<Milestone> milestones;

  DonationCampaign({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.targetAmount,
    required this.totalRaised,
    required this.percentage,
    required this.donorCount,
    required this.remainingAmount,

    required this.endDate,
    required this.isFeatured,
    required this.packages,
    required this.rewards,
    required this.milestones,
  });

  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    return DonationCampaign(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      targetAmount: double.tryParse(json['goal_amount'].toString()) ?? 0.0,
      totalRaised: double.tryParse(json['total_raised'].toString()) ?? 0.0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      donorCount: json['donor_count'] as int? ?? 0,
      remainingAmount: double.tryParse(json['remaining_amount'].toString()) ?? 0.0,
      endDate: DateTime.parse(json['end_date'] as String),
      isFeatured: (json['is_featured'] == 1 || json['is_featured'] == true),
      packages: (json['packages'] as List? ?? [])
          .map((p) => DonationPackage.fromJson(p))
          .toList(),
      rewards: (json['rewards'] as List? ?? [])
          .map((r) => Reward.fromJson(r))
          .toList(),
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
    );
  }
}
