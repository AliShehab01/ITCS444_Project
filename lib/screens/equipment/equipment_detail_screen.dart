import 'package:flutter/material.dart';
import '../../models/equipment_item.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/equipment_service.dart';
import '../rental/rental_request_form.dart';
import 'add_edit_equipment_screen.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final EquipmentItem item;
  final bool forceRenterView;

  const EquipmentDetailScreen({
    super.key,
    required this.item,
    this.forceRenterView = false,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final equipmentService = EquipmentService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Equipment Details'),
        actions: [
          // Show edit/delete buttons for admins
          FutureBuilder(
            future: authService.getUserData(authService.currentUser!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final user = snapshot.data!;
              final isAdmin = user.role == UserRole.admin && !forceRenterView;

              if (!isAdmin) return const SizedBox.shrink();

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditEquipmentScreen(item: item),
                        ),
                      ).then((_) {
                        // Refresh the screen when returning
                        Navigator.pop(context);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        _showDeleteConfirmation(context, equipmentService),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Icon Section
            Container(
              width: double.infinity,
              height: 200,
              color: _getStatusColor(item.status).withOpacity(0.1),
              child: Icon(
                _getEquipmentIcon(item.type),
                size: 100,
                color: _getStatusColor(item.status),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(item.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    item.type.displayName,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Details Cards
                  _buildInfoCard(
                    'Description',
                    item.description,
                    Icons.description,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Condition',
                          item.condition.displayName,
                          Icons.grade,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Quantity',
                          '${item.quantity}',
                          Icons.numbers,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard('Location', item.location, Icons.location_on),
                  const SizedBox(height: 16),

                  if (item.rentalPricePerDay != null)
                    _buildInfoCard(
                      'Rental Price',
                      '\$${item.rentalPricePerDay!.toStringAsFixed(2)} per day',
                      Icons.attach_money,
                    ),
                  const SizedBox(height: 16),

                  // Tags
                  if (item.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue[400]!.withOpacity(0.2),
                          labelStyle: TextStyle(color: Colors.blue[400]),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Owner Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Owner',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                item.ownerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.isDonated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[400],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'DONATED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  FutureBuilder(
                    future: authService.getUserData(
                      authService.currentUser!.uid,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      final user = snapshot.data!;

                      // Show rent button for renters if item is available or reserved
                      // (reserved items may have available dates)
                      if (user.role == UserRole.renter &&
                          (item.status == ItemStatus.available ||
                              item.status == ItemStatus.reserved)) {
                        return ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RentalRequestForm(item: item),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(
                                item.status == ItemStatus.reserved
                                    ? 'Check Availability'
                                    : 'Request Rental',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ItemStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.available:
        return Colors.green;
      case ItemStatus.rented:
        return Colors.blue;
      case ItemStatus.reserved:
        return Colors.orange;
      case ItemStatus.donated:
        return Colors.purple;
      case ItemStatus.underMaintenance:
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
        return Icons.healing;
      case EquipmentType.hospitalBed:
        return Icons.bed;
      case EquipmentType.oxygenMachine:
        return Icons.air;
      case EquipmentType.commode:
        return Icons.chair;
      case EquipmentType.bathChair:
        return Icons.bathtub;
      case EquipmentType.ramp:
        return Icons.stairs;
      case EquipmentType.liftChair:
        return Icons.event_seat;
      case EquipmentType.other:
        return Icons.medical_services;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    EquipmentService equipmentService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await equipmentService.deleteEquipment(item.id);
                if (context.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
