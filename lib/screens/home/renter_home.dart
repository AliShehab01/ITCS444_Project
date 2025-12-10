import 'package:flutter/material.dart';
import '../profile_page.dart';
import '../equipment/browse_equipment_screen.dart';
import '../rental/rental_tracking_screen.dart';
import '../donation/donation_submission_form.dart';
import '../notifications/notifications_screen.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class RenterHome extends StatefulWidget {
  const RenterHome({super.key});

  @override
  State<RenterHome> createState() => _RenterHomeState();
}

class _RenterHomeState extends State<RenterHome> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData(_authService.currentUser!.uid);
    if (user != null && mounted) {
      setState(() {
        _userId = user.uid;
        _userName = user.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: const Text('Renter Dashboard'),
        actions: [
          // Notification Bell with Badge
          if (_userId != null)
            StreamBuilder<int>(
              stream: _notificationService.getUnreadCount(_userId!),
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
                              userId: _userId!,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              color: Colors.green[400],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_bag, size: 40, color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Renter Portal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Browse and rent items',
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

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Renter Actions Section
            Text(
              'Quick Actions',
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
                  icon: Icons.storefront,
                  title: 'Browse Items',
                  subtitle: 'View available items',
                  color: Colors.blue[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BrowseEquipmentScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  title: 'My Rentals',
                  subtitle: 'View rental history',
                  color: Colors.purple[400]!,
                  onTap: () {
                    if (_userId != null && _userName != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RentalTrackingScreen(
                            renterId: _userId!,
                            renterName: _userName!,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.volunteer_activism,
                  title: 'Donate',
                  subtitle: 'Donate equipment',
                  color: Colors.orange[400]!,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DonationSubmissionForm(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.favorite,
                  title: 'Favorites',
                  subtitle: 'Saved items',
                  color: Colors.red[400]!,
                  onTap: () {
                    // TODO: Navigate to favorites
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favorites - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Stats Section
            Text(
              'My Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Rentals',
                    '0',
                    Icons.schedule,
                    Colors.green[400]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '0',
                    Icons.check_circle,
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Card(
      color: Colors.grey[850],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
