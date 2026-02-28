import 'package:dar_city_app/models/donation_campaign.dart';
import 'package:dar_city_app/models/donation_milestone.dart';
import 'package:dar_city_app/models/donation_package.dart';
import 'package:dar_city_app/models/donation_reward.dart';
import 'package:dar_city_app/models/top_donor.dart';
import 'package:dar_city_app/screens/donate_form_screen.dart';
import 'package:dar_city_app/services/donation_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:flutter/material.dart';

class DonationCampaignDetailsScreen extends StatefulWidget {
  final DonationCampaign campaign;

  const DonationCampaignDetailsScreen({Key? key, required this.campaign}) : super(key: key);

  @override
  State<DonationCampaignDetailsScreen> createState() => _DonationCampaignDetailsScreenState();
}

class _DonationCampaignDetailsScreenState extends State<DonationCampaignDetailsScreen> {
  late Future<List<TopDonor>> _topDonorsFuture;

  @override
  void initState() {
    super.initState();
    _topDonorsFuture = DonationService().getTopDonors(widget.campaign.id);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.campaign.percentage.clamp(0, 100);
    final daysLeft = widget.campaign.endDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.campaign.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.campaign.imageUrl != null)
                    Image.network(
                      widget.campaign.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campaign.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Stats Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Raised', 'Tsh ${_formatNumber(widget.campaign.totalRaised)}'),
                      _buildStat('Goal', 'Tsh ${_formatNumber(widget.campaign.targetAmount)}'),
                      _buildStat('Donors', widget.campaign.donorCount.toString()),
                      _buildStat('Days Left', daysLeft > 0 ? daysLeft.toString() : 'Ended', isHighlighted: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}% funded',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Top Donors'),
                  _buildTopDonorsList(),
                  const SizedBox(height: 24),
                  
                  if (widget.campaign.packages.isNotEmpty) ...[
                    _buildSectionTitle('Packages'),
                    ...widget.campaign.packages.map((p) => _buildPackageCard(p)).toList(),
                    const SizedBox(height: 24),
                  ],
                  
                  if (widget.campaign.rewards.isNotEmpty) ...[
                    _buildSectionTitle('Rewards'),
                    ...widget.campaign.rewards.map((r) => _buildRewardCard(r)).toList(),
                    const SizedBox(height: 24),
                  ],

                  if (widget.campaign.milestones.isNotEmpty) ...[
                    _buildSectionTitle('Milestones'),
                    ...widget.campaign.milestones.map((m) => _buildMilestoneCard(m)).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
            onPressed: () async {
                final token = await SessionManager().getToken();
                if (token == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text('You must be logged in to make a donation.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonateFormScreen(campaign: widget.campaign),
                  ),
                );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Donate Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTopDonorsList() {
    return FutureBuilder<List<TopDonor>>(
      future: _topDonorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No top donors yet.'));
        } else {
          final topDonors = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topDonors.length,
            itemBuilder: (context, index) {
              final donor = topDonors[index];
              return Card(
                color: const Color(0xFF2A2A2A),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: donor.avatarUrl != null ? NetworkImage(donor.avatarUrl!) : null,
                    child: donor.avatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text('${index + 1}. ${donor.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: Text('Tsh ${_formatNumber(donor.totalAmount)}', style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSectionTitle(String title) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      );
  }

  Widget _buildPackageCard(DonationPackage package) {
      return Card(
          color: const Color(0xFF2A2A2A),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(package.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(package.description, style: const TextStyle(color: Colors.white70)),
            trailing: Text('Tsh${_formatNumber(package.amount)}', style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
      );
  }

    Widget _buildRewardCard(Reward reward) {
      return Card(
          color: const Color(0xFF2A2A2A),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(reward.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(reward.description, style: const TextStyle(color: Colors.white70)),
          ),
      );
  }

  Widget _buildMilestoneCard(Milestone milestone) {
    final isReached = widget.campaign.totalRaised >= milestone.targetAmount;
    return Card(
        color: const Color(0xFF2A2A2A),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(isReached ? Icons.check_circle : Icons.radio_button_unchecked, color: isReached ? Colors.green : Colors.grey),
          title: Text(milestone.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Goal: Tsh ${_formatNumber(milestone.targetAmount)}', style: const TextStyle(color: Colors.white70)),
        ),
    );
  }

  Widget _buildStat(String label, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.red : Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}
