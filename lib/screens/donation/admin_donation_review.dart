import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/donation_submission.dart';
import '../../models/equipment_item.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';

class AdminDonationReview extends StatelessWidget {
  const AdminDonationReview({super.key});

  @override
  Widget build(BuildContext context) {
    final donationService = DonationService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        title: const Text('Review Donations'),
      ),
      body: StreamBuilder<List<DonationSubmission>>(
        stream: donationService.getPendingDonationsStream(),
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
                    'No pending donations',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final donations = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) =>
                _DonationCard(donation: donations[index]),
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationSubmission donation;

  const _DonationCard({required this.donation});

  // Map icon names to IconData
  IconData _getIconFromName(String? iconName) {
    final iconMap = {
      'wheelchair': Icons.accessible,
      'walker': Icons.elderly,
      'crutches': Icons.assist_walker,
      'hospital_bed': Icons.bed,
      'oxygen': Icons.air,
      'chair': Icons.chair,
      'bath': Icons.bathtub,
      'seat': Icons.event_seat,
      'medical': Icons.medical_services,
      'healing': Icons.healing,
      'health': Icons.health_and_safety,
      'medication': Icons.medication,
    };
    return iconMap[iconName] ?? Icons.volunteer_activism;
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconFromName(donation.selectedIcon),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        donation.itemType,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Donor', donation.donorName),
            _buildInfoRow(Icons.email, 'Contact', donation.donorEmail),
            _buildInfoRow(Icons.phone, 'Phone', donation.donorContact),
            _buildInfoRow(Icons.check_circle, 'Condition', donation.condition),
            _buildInfoRow(Icons.numbers, 'Quantity', '${donation.quantity}'),
            _buildInfoRow(Icons.location_on, 'Location', donation.location),
            const SizedBox(height: 12),
            Text(
              'Description:',
              style: TextStyle(
                color: Colors.grey[300],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              donation.description,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (donation.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${donation.notes}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectionDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ApprovalDialog(donation: donation),
    );
  }

  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Reject Donation',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Rejection reason...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                final authService = AuthService();
                final donationService = DonationService();
                await donationService.rejectDonation(
                  donation.id,
                  authService.currentUser!.uid,
                  reasonController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Donation rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _ApprovalDialog extends StatefulWidget {
  final DonationSubmission donation;

  const _ApprovalDialog({required this.donation});

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _priceController = TextEditingController(text: '0');
  final _tagsController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Approve Donation',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approving: ${widget.donation.itemName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set rental price (optional):',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: '0 for free',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tags (comma-separated):',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., donated, medical, mobility',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _approveAndAddToInventory,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Approve & Add to Inventory'),
        ),
      ],
    );
  }

  Future<void> _approveAndAddToInventory() async {
    setState(() => _isProcessing = true);

    try {
      final authService = AuthService();
      final donationService = DonationService();
      final currentUser = await authService.getUserData(
        authService.currentUser!.uid,
      );

      // Parse equipment type from donation
      final equipmentType = EquipmentType.values.firstWhere(
        (e) => e.displayName == widget.donation.itemType,
        orElse: () => EquipmentType.other,
      );

      // Parse condition from donation
      final condition = ItemCondition.values.firstWhere(
        (e) => e.displayName == widget.donation.condition,
        orElse: () => ItemCondition.good,
      );

      // Create equipment item
      final equipment = EquipmentItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: widget.donation.itemName,
        type: equipmentType,
        description: widget.donation.description,
        imageUrls: widget.donation.imageUrls,
        condition: condition,
        quantity: widget.donation.quantity,
        location: widget.donation.location,
        tags:
            _tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
              ..add('donated'),
        status: ItemStatus.available,
        rentalPricePerDay: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        ownerId: currentUser!.uid,
        ownerName: currentUser.name,
        createdAt: DateTime.now(),
      );

      await donationService.approveDonation(
        widget.donation.id,
        authService.currentUser!.uid,
        equipment,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation approved and added to inventory!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
