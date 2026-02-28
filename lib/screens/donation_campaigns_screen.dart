import 'dart:async';

import 'package:dar_city_app/models/donation_campaign.dart';
import 'package:dar_city_app/screens/donation_campaign_details_screen.dart';
import 'package:dar_city_app/screens/donate_form_screen.dart';
import 'package:dar_city_app/services/donation_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:flutter/material.dart';

class DonationCampaignsScreen extends StatefulWidget {
  const DonationCampaignsScreen({Key? key}) : super(key: key);

  @override
  State<DonationCampaignsScreen> createState() => _DonationCampaignsScreenState();
}

class _DonationCampaignsScreenState extends State<DonationCampaignsScreen> {
  final DonationService _donationService = DonationService();
  late Future<List<DonationCampaign>> _campaignsFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCampaigns();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchCampaigns() {
    setState(() {
      _campaignsFuture = _donationService.getCampaigns();
    });
  }

  Future<void> _showDonateDialog(BuildContext context, DonationCampaign campaign) async {
    final token = await SessionManager().getToken();
    if (!mounted) return; 

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
                Navigator.of(context).pop(); 
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
        builder: (context) => DonateFormScreen(campaign: campaign),
      ),
    );
  }

  void _showCampaignDetails(DonationCampaign campaign) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DonationCampaignDetailsScreen(campaign: campaign)));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donation Campaigns',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000), // Dark red
                Color(0xFF660000), // Deeper red
                Color(0xFF330000), // Very dark red (almost black)
                Color(0xFF1A0000), // Blackish red
              ],
              stops: [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCampaigns,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF121212),
            ],
          ),
        ),
        child: FutureBuilder<List<DonationCampaign>>(
          future: _campaignsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _campaignsFuture == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchCampaigns,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No campaigns found.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new campaigns',
                      style: TextStyle(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final campaigns = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  final percentage = campaign.percentage.clamp(0, 100);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2A2A2A),
                          Color(0xFF1E1E1E),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showCampaignDetails(campaign),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (campaign.imageUrl != null)
                                Stack(
                                  children: [
                                    Image.network(
                                      campaign.imageUrl!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 180,
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
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF8B0000),
                                              Color(0xFF330000),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      campaign.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      campaign.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[800],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _buildStat(
                                            'Raised',
                                            'Tsh ${_formatNumber(campaign.totalRaised)} ',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStat(
                                            'Goal',
                                            'Tsh ${_formatNumber(campaign.targetAmount)}',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStat('Donors', campaign.donorCount.toString()),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatDate(campaign.endDate),
                                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () => _showDonateDialog(context, campaign),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Donate'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _showCampaignDetails(campaign),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Details', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
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
