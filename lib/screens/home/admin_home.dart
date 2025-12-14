import 'package:flutter/material.dart';
import '../profile_page.dart';
import '../equipment/add_edit_equipment_screen.dart';
import '../equipment/browse_equipment_screen.dart';
import '../rental/admin_rental_list.dart';
import '../donation/admin_donation_review.dart';
import '../notifications/notifications_screen.dart';
import '../reports/reports_dashboard.dart';
import '../../services/notification_service.dart';
import '../../services/equipment_service.dart';
import '../../services/rental_service.dart';
import '../../services/auth_service.dart';
import '../../utils/page_transitions.dart';
import 'renter_home.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _notificationService = NotificationService();
  final _equipmentService = EquipmentService();
  final _rentalService = RentalService();
  final _authService = AuthService();
  bool _isRenterView = false;

  @override
  void initState() {
    super.initState();
    // Check for overdue rentals when admin opens the app
    _notificationService.checkRentalDueDates();
    // Update reservation statuses for items with upcoming rentals within 30 days
    _rentalService.updateUpcomingReservationStatuses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRenterView) {
      return _buildFullRenterView();
    }
    return _buildAdminScaffold();
  }

  Widget _buildFullRenterView() {
    final userId = _authService.currentUser?.uid;
    final userName = _authService.currentUser?.displayName ?? 'Admin';
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: const Text('Renter Dashboard'),
        actions: [
          // Notification Bell with Badge
          if (userId != null)
            StreamBuilder<int>(
              stream: _notificationService.getUnreadCount(userId),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(
                              userId: userId,
                              isAdmin: false,
                            ),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Switch back to Admin view
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Switch to Admin View',
            onPressed: () {
              setState(() {
                _isRenterView = false;
              });
            },
          ),
        ],
      ),
      body: RenterHomeContent(
        userId: userId,
        userName: userName,
        forceRenterView: true,
      ),
    );
  }

  Widget _buildAdminScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        title: const Text('Admin Dashboard'),
        actions: [
          // Notification Bell with Badge
          StreamBuilder<int>(
            stream: _notificationService.getAdminUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(
                            userId: 'admin',
                            isAdmin: true,
                          ),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Toggle to Renter view
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Switch to Renter View',
            onPressed: () {
              setState(() {
                _isRenterView = true;
              });
            },
          ),
        ],
      ),
      body: _buildAdminView(),
    );
  }

  Widget _buildAdminView() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              color: Colors.purple[400],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Portal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Donor Management',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Admin Actions Section
            Text(
              'Admin Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Action Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.add_box,
                  title: 'Add Item',
                  subtitle: 'Donate new items',
                  color: Colors.green[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const AddEditEquipmentScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.inventory,
                  title: 'My Items',
                  subtitle: 'Manage donations',
                  color: Colors.blue[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const BrowseEquipmentScreen(showMyItemsOnly: true),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.pending_actions,
                  title: 'Rental Requests',
                  subtitle: 'View pending requests',
                  color: Colors.orange[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const AdminRentalList(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.volunteer_activism,
                  title: 'Donations',
                  subtitle: 'Review submissions',
                  color: Colors.orange[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const AdminDonationReview(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Reports',
                  subtitle: 'View analytics',
                  color: Colors.purple[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const ReportsDashboard(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.search,
                  title: 'Browse All',
                  subtitle: 'Search inventory',
                  color: Colors.teal[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      FadeSlidePageRoute(
                        page: const BrowseEquipmentScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Stats Section
            Text(
              'Quick Stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards with real data
            StreamBuilder<Map<String, int>>(
              stream: _equipmentService.getEquipmentStatsStream(),
              builder: (context, equipmentSnapshot) {
                return StreamBuilder<Map<String, int>>(
                  stream: _rentalService.getRentalStatisticsStream(),
                  builder: (context, rentalSnapshot) {
                    final totalItems = equipmentSnapshot.data?['total'] ?? 0;
                    final activeRentals = rentalSnapshot.data?['active'] ?? 0;
                    final pendingRequests =
                        rentalSnapshot.data?['pending'] ?? 0;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Items',
                                totalItems.toString(),
                                Icons.inventory_2,
                                Colors.blue[400]!,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Active Rentals',
                                activeRentals.toString(),
                                Icons.schedule,
                                Colors.green[400]!,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Pending Requests',
                                pendingRequests.toString(),
                                Icons.pending_actions,
                                Colors.orange[400]!,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Completed',
                                (rentalSnapshot.data?['completed'] ?? 0)
                                    .toString(),
                                Icons.check_circle,
                                Colors.purple[400]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _AnimatedCard(
      onTap: onTap,
      child: Card(
        color: Colors.grey[850],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple animated card with scale effect on tap
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedCard({required this.child, required this.onTap});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
