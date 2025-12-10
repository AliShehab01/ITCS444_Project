import 'package:flutter/material.dart';
import '../../models/rental_request.dart';
import '../../services/rental_service.dart';

class AdminRentalList extends StatelessWidget {
  const AdminRentalList({super.key});

  @override
  Widget build(BuildContext context) {
    final rentalService = RentalService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('Rental Management'),
          bottom: TabBar(
            indicatorColor: Colors.purple[400],
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RentalTab(
              stream: rentalService.getPendingRentals(),
              type: 'pending',
            ),
            _RentalTab(
              stream: rentalService.getActiveRentals(),
              type: 'active',
            ),
            _RentalTab(stream: rentalService.getAllRentals(), type: 'history'),
          ],
        ),
      ),
    );
  }
}

class _RentalTab extends StatelessWidget {
  final Stream<List<RentalRequest>> stream;
  final String type;

  const _RentalTab({required this.stream, required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalRequest>>(
      stream: stream,
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
                  'No ${type} rentals',
                  style: TextStyle(color: Colors.grey[400], fontSize: 18),
                ),
              ],
            ),
          );
        }

        List<RentalRequest> rentals = snapshot.data!;
        if (type == 'history') {
          rentals = rentals
              .where(
                (r) =>
                    r.status == RentalStatus.returned ||
                    r.status == RentalStatus.rejected ||
                    r.status == RentalStatus.cancelled,
              )
              .toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rentals.length,
          itemBuilder: (context, index) => _RentalCard(rental: rentals[index]),
        );
      },
    );
  }
}

class _RentalCard extends StatelessWidget {
  final RentalRequest rental;

  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final rentalService = RentalService();
    final isOverdue = rental.isOverdue;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rental.renterName,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(rental.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Duration',
              '${rental.durationDays} days',
            ),
            _buildInfoRow(Icons.event, 'Start', _formatDate(rental.startDate)),
            _buildInfoRow(Icons.event_busy, 'End', _formatDate(rental.endDate)),
            if (rental.totalCost != null)
              _buildInfoRow(
                Icons.attach_money,
                'Cost',
                '\$${rental.totalCost!.toStringAsFixed(2)}',
              ),

            if (isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'OVERDUE by ${-rental.daysRemaining} days!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons based on status
            if (rental.status == RentalStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await rentalService.approveRentalRequest(rental.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rental approved!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await rentalService.rejectRentalRequest(
                          rental.id,
                          rental.itemId,
                          null,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rental rejected'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ] else if (rental.status == RentalStatus.approved) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await rentalService.checkOutItem(rental.id, rental.itemId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item checked out!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 40),
                ),
                icon: const Icon(Icons.check_box),
                label: const Text('Check Out'),
              ),
            ] else if (rental.status == RentalStatus.checkedOut) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await rentalService.returnItem(rental.id, rental.itemId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item returned successfully!'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 40),
                ),
                icon: const Icon(Icons.assignment_return),
                label: const Text('Mark as Returned'),
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
          fontSize: 12,
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
