import 'dart:async';
import 'package:dar_city_app/models/team.dart';
import 'package:dar_city_app/services/team_service.dart';
import 'package:flutter/material.dart';

class TeamDetailPage extends StatefulWidget {
  final int teamId;
  const TeamDetailPage({Key? key, required this.teamId}) : super(key: key);

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  late Future<Team> _teamFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _teamFuture = TeamService.getTeamDetails(widget.teamId);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          _teamFuture = TeamService.getTeamDetails(widget.teamId);
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _teamFuture = TeamService.getTeamDetails(widget.teamId);
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.9),
                  Colors.redAccent.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.sports_basketball_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading Team Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fetching team information...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF151515),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 50,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Failed to Load',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.redAccent.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.1),
            ),
            child: Icon(
              _getIconForLabel(label),
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'city':
        return Icons.location_city_rounded;
      case 'region':
        return Icons.map_rounded;
      case 'country':
        return Icons.public_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Team>(
        future: _teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return _buildErrorState('Team not found.');
          }

          final team = snapshot.data!;

          return RefreshIndicator(
            backgroundColor: Colors.redAccent,
            color: Colors.white,
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // AppBar with logo
                SliverAppBar(
                  expandedHeight: 280,
                  collapsedHeight: kToolbarHeight, // Fixed: Set to toolbar height
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.redAccent.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: team.logo != null
                          ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Image.network(
                          team.logo!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.redAccent,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.redAccent.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.sports_basketball_rounded,
                                color: Colors.redAccent.withOpacity(0.7),
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                      )
                          : Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.sports_basketball_rounded,
                            color: Colors.redAccent.withOpacity(0.7),
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      onPressed: _refreshData,
                    ),
                  ],
                ),

                // Content
                SliverList(
                  delegate: SliverChildListDelegate([
                    // TEAM NAME
                    Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 30),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        team.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),



                    // TEAM DETAILS
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF121212),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION TITLE
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.redAccent,
                                  Colors.redAccent.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'TEAM INFORMATION',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // DETAIL ITEMS
                          _buildDetailItem('City', team.city),
                          _buildDetailItem('Region', team.region),
                          _buildDetailItem('Country', team.country),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}