import 'package:flutter/material.dart';
import '../../models/rental_request.dart';
import '../../models/equipment_item.dart';
import '../../models/donation_submission.dart';
import '../../services/rental_service.dart';
import '../../services/equipment_service.dart';
import '../../services/donation_service.dart';

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() => _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RentalService _rentalService = RentalService();
  final EquipmentService _equipmentService = EquipmentService();
  final DonationService _donationService = DonationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple[400],
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Rentals'),
            Tab(icon: Icon(Icons.volunteer_activism), text: 'Donations'),
            Tab(icon: Icon(Icons.build), text: 'Inventory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRentalsTab(),
          _buildDonationsTab(),
          _buildInventoryTab(),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Grid
          _buildSectionTitle('Quick Overview'),
          const SizedBox(height: 16),
          _buildOverviewStats(),
          const SizedBox(height: 24),

          // Overdue Alerts
          _buildSectionTitle('⚠️ Overdue Alerts'),
          const SizedBox(height: 16),
          _buildOverdueAlerts(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildSectionTitle('📊 Recent Activity'),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    return StreamBuilder<Map<String, int>>(
      stream: _rentalService.getRentalStatisticsStream(),
      builder: (context, rentalSnapshot) {
        return StreamBuilder<Map<String, int>>(
          stream: _equipmentService.getEquipmentStatsStream(),
          builder: (context, equipmentSnapshot) {
            return StreamBuilder<List<DonationSubmission>>(
              stream: _donationService.getAllDonationsStream(),
              builder: (context, donationSnapshot) {
                final rentalStats = rentalSnapshot.data ?? {};
                final equipmentStats = equipmentSnapshot.data ?? {};
                final donations = donationSnapshot.data ?? [];

                final pendingDonations = donations
                    .where((d) => d.status == DonationStatus.pending)
                    .length;
                final approvedDonations = donations
                    .where((d) => d.status == DonationStatus.approved)
                    .length;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Total Items',
                      '${equipmentStats['total'] ?? 0}',
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Active Rentals',
                      '${rentalStats['active'] ?? 0}',
                      Icons.schedule,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Pending Requests',
                      '${rentalStats['pending'] ?? 0}',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Overdue',
                      '${rentalStats['overdue'] ?? 0}',
                      Icons.warning,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Completed Rentals',
                      '${rentalStats['completed'] ?? 0}',
                      Icons.check_circle,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Pending Donations',
                      '$pendingDonations',
                      Icons.volunteer_activism,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'Available Items',
                      '${equipmentStats['available'] ?? 0}',
                      Icons.check_box,
                      Colors.lightGreen,
                    ),
                    _buildStatCard(
                      'Total Donations',
                      '$approvedDonations',
                      Icons.card_giftcard,
                      Colors.pink,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOverdueAlerts() {
    return FutureBuilder<List<RentalRequest>>(
      future: _rentalService.getOverdueRentals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final overdueRentals = snapshot.data ?? [];

        if (overdueRentals.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[400]),
                const SizedBox(width: 12),
                const Text(
                  'No overdue rentals! All items returned on time.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        return Column(
          children: overdueRentals.map((rental) {
            final daysOverdue = DateTime.now()
                .difference(rental.endDate)
                .inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rented by: ${rental.renterName}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$daysOverdue days late',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<List<RentalRequest>>(
      stream: _rentalService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recentRentals = snapshot.data!.take(5).toList();

        if (recentRentals.isEmpty) {
          return _buildEmptyState('No recent activity');
        }

        return Column(
          children: recentRentals.map((rental) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatusIcon(rental.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${rental.renterName} • ${_formatDate(rental.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(rental.status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== RENTALS TAB ====================
  Widget _buildRentalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📈 Rental Statistics'),
          const SizedBox(height: 16),
          _buildRentalStats(),
          const SizedBox(height: 24),

          _buildSectionTitle('🔥 Most Frequently Rented'),
          const SizedBox(height: 16),
          _buildMostRentedItems(),
          const SizedBox(height: 24),

          _buildSectionTitle('📅 Rental Duration Analysis'),
          const SizedBox(height: 16),
          _buildRentalDurationStats(),
          const SizedBox(height: 24),

          _buildSectionTitle('👥 Top Renters'),
          const SizedBox(height: 16),
          _buildTopRenters(),
        ],
      ),
    );
  }

  Widget _buildRentalStats() {
    return StreamBuilder<Map<String, int>>(
      stream: _rentalService.getRentalStatisticsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Total Rentals',
                '${stats['total'] ?? 0}',
                Icons.assignment,
                Colors.blue,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Active Rentals',
                '${stats['active'] ?? 0}',
                Icons.schedule,
                Colors.green,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Pending Requests',
                '${stats['pending'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Completed',
                '${stats['completed'] ?? 0}',
                Icons.check_circle,
                Colors.purple,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Overdue',
                '${stats['overdue'] ?? 0}',
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMostRentedItems() {
    return StreamBuilder<List<RentalRequest>>(
      stream: _rentalService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count rentals per item
        final itemCounts = <String, Map<String, dynamic>>{};
        for (var rental in snapshot.data!) {
          if (itemCounts.containsKey(rental.itemId)) {
            itemCounts[rental.itemId]!['count']++;
          } else {
            itemCounts[rental.itemId] = {'name': rental.itemName, 'count': 1};
          }
        }

        // Sort by count
        final sortedItems = itemCounts.entries.toList()
          ..sort((a, b) => b.value['count'].compareTo(a.value['count']));

        if (sortedItems.isEmpty) {
          return _buildEmptyState('No rental data yet');
        }

        return Column(
          children: sortedItems.take(5).map((entry) {
            final rank = sortedItems.indexOf(entry) + 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value['count']} rentals',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRentalDurationStats() {
    return StreamBuilder<List<RentalRequest>>(
      stream: _rentalService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rentals = snapshot.data!;
        if (rentals.isEmpty) {
          return _buildEmptyState('No rental data');
        }

        // Calculate duration stats
        final durations = rentals.map((r) => r.durationDays).toList();
        final avgDuration =
            durations.reduce((a, b) => a + b) / durations.length;
        final maxDuration = durations.reduce((a, b) => a > b ? a : b);
        final minDuration = durations.reduce((a, b) => a < b ? a : b);

        // Duration distribution
        final shortTerm = rentals.where((r) => r.durationDays <= 3).length;
        final mediumTerm = rentals
            .where((r) => r.durationDays > 3 && r.durationDays <= 7)
            .length;
        final longTerm = rentals.where((r) => r.durationDays > 7).length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDurationStat(
                      'Average',
                      '${avgDuration.toStringAsFixed(1)} days',
                    ),
                  ),
                  Expanded(
                    child: _buildDurationStat('Max', '$maxDuration days'),
                  ),
                  Expanded(
                    child: _buildDurationStat('Min', '$minDuration days'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Duration Distribution',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDurationBar(
                      'Short (1-3)',
                      shortTerm,
                      rentals.length,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDurationBar(
                      'Medium (4-7)',
                      mediumTerm,
                      rentals.length,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDurationBar(
                      'Long (8+)',
                      longTerm,
                      rentals.length,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildDurationBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopRenters() {
    return StreamBuilder<List<RentalRequest>>(
      stream: _rentalService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count rentals per renter
        final renterCounts = <String, Map<String, dynamic>>{};
        for (var rental in snapshot.data!) {
          if (renterCounts.containsKey(rental.renterId)) {
            renterCounts[rental.renterId]!['count']++;
          } else {
            renterCounts[rental.renterId] = {
              'name': rental.renterName,
              'count': 1,
            };
          }
        }

        // Sort by count
        final sortedRenters = renterCounts.entries.toList()
          ..sort((a, b) => b.value['count'].compareTo(a.value['count']));

        if (sortedRenters.isEmpty) {
          return _buildEmptyState('No renter data yet');
        }

        return Column(
          children: sortedRenters.take(5).map((entry) {
            final rank = sortedRenters.indexOf(entry) + 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.grey[700],
                    child: Text(
                      entry.value['name'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value['count']} rentals',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== DONATIONS TAB ====================
  Widget _buildDonationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🎁 Donation Statistics'),
          const SizedBox(height: 16),
          _buildDonationStats(),
          const SizedBox(height: 24),

          _buildSectionTitle('📦 Most Donated Item Types'),
          const SizedBox(height: 16),
          _buildMostDonatedTypes(),
          const SizedBox(height: 24),

          _buildSectionTitle('🌟 Top Donors'),
          const SizedBox(height: 16),
          _buildTopDonors(),
        ],
      ),
    );
  }

  Widget _buildDonationStats() {
    return StreamBuilder<List<DonationSubmission>>(
      stream: _donationService.getAllDonationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final donations = snapshot.data!;
        final pending = donations
            .where((d) => d.status == DonationStatus.pending)
            .length;
        final approved = donations
            .where((d) => d.status == DonationStatus.approved)
            .length;
        final rejected = donations
            .where((d) => d.status == DonationStatus.rejected)
            .length;

        final totalQuantity = donations
            .where((d) => d.status == DonationStatus.approved)
            .fold(0, (sum, d) => sum + d.quantity);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Total Submissions',
                '${donations.length}',
                Icons.volunteer_activism,
                Colors.blue,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Pending Review',
                '$pending',
                Icons.pending_actions,
                Colors.orange,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Approved',
                '$approved',
                Icons.check_circle,
                Colors.green,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow('Rejected', '$rejected', Icons.cancel, Colors.red),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Total Items Donated',
                '$totalQuantity',
                Icons.inventory,
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMostDonatedTypes() {
    return StreamBuilder<List<DonationSubmission>>(
      stream: _donationService.getAllDonationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count donations per item type
        final typeCounts = <String, int>{};
        for (var donation in snapshot.data!.where(
          (d) => d.status == DonationStatus.approved,
        )) {
          typeCounts[donation.itemType] =
              (typeCounts[donation.itemType] ?? 0) + donation.quantity;
        }

        // Sort by count
        final sortedTypes = typeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedTypes.isEmpty) {
          return _buildEmptyState('No approved donations yet');
        }

        return Column(
          children: sortedTypes.take(5).map((entry) {
            final rank = sortedTypes.indexOf(entry) + 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatTypeName(entry.key),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopDonors() {
    return StreamBuilder<List<DonationSubmission>>(
      stream: _donationService.getAllDonationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count donations per donor
        final donorCounts = <String, Map<String, dynamic>>{};
        for (var donation in snapshot.data!.where(
          (d) => d.status == DonationStatus.approved,
        )) {
          if (donorCounts.containsKey(donation.donorId)) {
            donorCounts[donation.donorId]!['count'] += donation.quantity;
          } else {
            donorCounts[donation.donorId] = {
              'name': donation.donorName,
              'count': donation.quantity,
            };
          }
        }

        // Sort by count
        final sortedDonors = donorCounts.entries.toList()
          ..sort((a, b) => b.value['count'].compareTo(a.value['count']));

        if (sortedDonors.isEmpty) {
          return _buildEmptyState('No donors yet');
        }

        return Column(
          children: sortedDonors.take(5).map((entry) {
            final rank = sortedDonors.indexOf(entry) + 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.teal[700],
                    child: Text(
                      entry.value['name'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value['count']} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== INVENTORY TAB ====================
  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📊 Inventory Overview'),
          const SizedBox(height: 16),
          _buildInventoryStats(),
          const SizedBox(height: 24),

          _buildSectionTitle('🏥 Items by Type'),
          const SizedBox(height: 16),
          _buildItemsByType(),
          const SizedBox(height: 24),

          _buildSectionTitle('🔧 Maintenance Status'),
          const SizedBox(height: 16),
          _buildMaintenanceStatus(),
          const SizedBox(height: 24),

          _buildSectionTitle('📍 Items by Location'),
          const SizedBox(height: 16),
          _buildItemsByLocation(),
        ],
      ),
    );
  }

  Widget _buildInventoryStats() {
    return StreamBuilder<Map<String, int>>(
      stream: _equipmentService.getEquipmentStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Total Items',
                '${stats['total'] ?? 0}',
                Icons.inventory_2,
                Colors.blue,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Available',
                '${stats['available'] ?? 0}',
                Icons.check_box,
                Colors.green,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Currently Rented',
                '${stats['rented'] ?? 0}',
                Icons.person,
                Colors.orange,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Reserved',
                '${stats['reserved'] ?? 0}',
                Icons.bookmark,
                Colors.purple,
              ),
              const Divider(color: Colors.grey),
              _buildStatRow(
                'Under Maintenance',
                '${stats['underMaintenance'] ?? 0}',
                Icons.build,
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsByType() {
    return StreamBuilder<List<EquipmentItem>>(
      stream: _equipmentService.getAllEquipmentStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count items per type
        final typeCounts = <EquipmentType, int>{};
        for (var item in snapshot.data!) {
          typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;
        }

        // Sort by count
        final sortedTypes = typeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedTypes.isEmpty) {
          return _buildEmptyState('No items in inventory');
        }

        return Column(
          children: sortedTypes.map((entry) {
            final percentage = (entry.value / snapshot.data!.length * 100)
                .toStringAsFixed(1);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEquipmentIcon(entry.key),
                    color: Colors.blue[400],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: entry.value / snapshot.data!.length,
                          backgroundColor: Colors.grey[700],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[400]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMaintenanceStatus() {
    return StreamBuilder<List<EquipmentItem>>(
      stream: _equipmentService.getAllEquipmentStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count by condition
        final conditionCounts = <ItemCondition, int>{};
        for (var item in snapshot.data!) {
          conditionCounts[item.condition] =
              (conditionCounts[item.condition] ?? 0) + 1;
        }

        final total = snapshot.data!.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: ItemCondition.values.map((condition) {
              final count = conditionCounts[condition] ?? 0;
              final percentage = total > 0
                  ? (count / total * 100).toStringAsFixed(1)
                  : '0.0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getConditionColor(condition),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatConditionName(condition),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      '$count ($percentage%)',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildItemsByLocation() {
    return StreamBuilder<List<EquipmentItem>>(
      stream: _equipmentService.getAllEquipmentStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count items per location
        final locationCounts = <String, int>{};
        for (var item in snapshot.data!) {
          final location = item.location.isEmpty ? 'Unknown' : item.location;
          locationCounts[location] = (locationCounts[location] ?? 0) + 1;
        }

        // Sort by count
        final sortedLocations = locationCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedLocations.isEmpty) {
          return _buildEmptyState('No location data');
        }

        return Column(
          children: sortedLocations.take(10).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value} items',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(RentalStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case RentalStatus.pending:
        icon = Icons.pending_actions;
        color = Colors.orange;
        break;
      case RentalStatus.approved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RentalStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case RentalStatus.checkedOut:
        icon = Icons.directions_walk;
        color = Colors.blue;
        break;
      case RentalStatus.returned:
        icon = Icons.assignment_return;
        color = Colors.purple;
        break;
      case RentalStatus.overdue:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case RentalStatus.cancelled:
        icon = Icons.block;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(RentalStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return Colors.orange;
      case RentalStatus.approved:
        return Colors.green;
      case RentalStatus.rejected:
        return Colors.red;
      case RentalStatus.checkedOut:
        return Colors.blue;
      case RentalStatus.returned:
        return Colors.purple;
      case RentalStatus.overdue:
        return Colors.red[900]!;
      case RentalStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getConditionColor(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.excellent:
        return Colors.green;
      case ItemCondition.good:
        return Colors.lightGreen;
      case ItemCondition.fair:
        return Colors.orange;
      case ItemCondition.needsRepair:
        return Colors.red;
    }
  }

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.wheelchair:
        return Icons.accessible;
      case EquipmentType.walker:
        return Icons.directions_walk;
      case EquipmentType.crutches:
        return Icons.accessibility_new;
      case EquipmentType.hospitalBed:
        return Icons.bed;
      case EquipmentType.oxygenMachine:
        return Icons.air;
      case EquipmentType.commode:
        return Icons.chair;
      case EquipmentType.bathChair:
        return Icons.bathtub;
      case EquipmentType.ramp:
        return Icons.trending_up;
      case EquipmentType.liftChair:
        return Icons.elevator;
      case EquipmentType.other:
        return Icons.medical_services;
    }
  }

  String _formatTypeName(String type) {
    return type
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatConditionName(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.needsRepair:
        return 'Needs Repair';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
