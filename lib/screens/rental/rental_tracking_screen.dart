import 'package:flutter/material.dart';
import '../../models/rental_request.dart';
import '../../services/rental_service.dart';

class RentalTrackingScreen extends StatelessWidget {
  final String renterId;
  final String renterName;

  const RentalTrackingScreen({
    super.key,
    required this.renterId,
    required this.renterName,
  });

  @override
  Widget build(BuildContext context) {
    final rentalService = RentalService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: const Text('My Rentals'),
      ),
      body: StreamBuilder<List<RentalRequest>>(
        stream: rentalService.getRentalsByRenter(renterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No rental requests yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final rentals = snapshot.data!;
          final active = rentals
              .where(
                (r) =>
                    r.status == RentalStatus.approved ||
                    r.status == RentalStatus.checkedOut,
              )
              .toList();
          final pending = rentals
              .where((r) => r.status == RentalStatus.pending)
              .toList();
          final history = rentals
              .where(
                (r) =>
                    r.status == RentalStatus.returned ||
                    r.status == RentalStatus.rejected ||
                    r.status == RentalStatus.cancelled,
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _buildSectionHeader(
                  'Active Rentals',
                  active.length,
                  Colors.blue,
                ),
                ...active.map((rental) => _RentalCard(rental: rental)),
                const SizedBox(height: 24),
              ],
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(
                  'Pending Requests',
                  pending.length,
                  Colors.orange,
                ),
                ...pending.map((rental) => _RentalCard(rental: rental)),
                const SizedBox(height: 24),
              ],
              if (history.isNotEmpty) ...[
                _buildSectionHeader('History', history.length, Colors.grey),
                ...history.map((rental) => _RentalCard(rental: rental)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final RentalRequest rental;

  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final isOverdue = rental.isOverdue;
    final daysRemaining = rental.daysRemaining;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rental.itemName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(rental.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Start',
              _formatDate(rental.startDate),
            ),
            _buildInfoRow(Icons.event, 'End', _formatDate(rental.endDate)),
            _buildInfoRow(
              Icons.access_time,
              'Duration',
              '${rental.durationDays} days',
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Total Cost',
              '\$${rental.totalCost?.toStringAsFixed(2) ?? '0.00'}',
            ),

            if (rental.status == RentalStatus.checkedOut) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red[900] : Colors.blue[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.info,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverdue
                            ? 'OVERDUE by ${-daysRemaining} days!'
                            : '$daysRemaining days remaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (rental.status == RentalStatus.approved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approved! Ready for pickup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (rental.renterNotes != null &&
                rental.renterNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${rental.renterNotes}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RentalStatus status) {
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
          fontSize: 11,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
