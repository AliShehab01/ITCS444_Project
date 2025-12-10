import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/donation_submission.dart';
import '../../models/equipment_item.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';

class DonationSubmissionForm extends StatefulWidget {
  const DonationSubmissionForm({super.key});

  @override
  State<DonationSubmissionForm> createState() => _DonationSubmissionFormState();
}

class _DonationSubmissionFormState extends State<DonationSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _donationService = DonationService();
  final _authService = AuthService();

  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  EquipmentType? _selectedType;
  ItemCondition? _selectedCondition;
  String? _selectedIcon;
  bool _isSubmitting = false;

  // Map equipment types to icons
  final Map<EquipmentType, IconData> _typeIcons = {
    EquipmentType.wheelchair: Icons.accessible,
    EquipmentType.walker: Icons.elderly,
    EquipmentType.crutches: Icons.assist_walker,
    EquipmentType.hospitalBed: Icons.bed,
    EquipmentType.oxygenMachine: Icons.air,
    EquipmentType.commode: Icons.chair,
    EquipmentType.bathChair: Icons.bathtub,
    EquipmentType.ramp: Icons.moving,
    EquipmentType.liftChair: Icons.event_seat,
    EquipmentType.other: Icons.medical_services,
  };

  // Available icons for selection
  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.accessible, 'name': 'wheelchair'},
    {'icon': Icons.elderly, 'name': 'walker'},
    {'icon': Icons.assist_walker, 'name': 'crutches'},
    {'icon': Icons.bed, 'name': 'hospital_bed'},
    {'icon': Icons.air, 'name': 'oxygen'},
    {'icon': Icons.chair, 'name': 'chair'},
    {'icon': Icons.bathtub, 'name': 'bath'},
    {'icon': Icons.event_seat, 'name': 'seat'},
    {'icon': Icons.medical_services, 'name': 'medical'},
    {'icon': Icons.healing, 'name': 'healing'},
    {'icon': Icons.health_and_safety, 'name': 'health'},
    {'icon': Icons.medication, 'name': 'medication'},
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment type')),
      );
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item condition')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Check if user is authenticated
      if (_authService.currentUser == null) {
        throw Exception('Please login to submit donations');
      }

      final user = await _authService.getUserData(
        _authService.currentUser!.uid,
      );
      if (user == null) throw Exception('User data not found');

      final donation = DonationSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donorId: user.uid,
        donorName: user.name,
        donorEmail: user.email,
        donorContact: user.contact,
        itemType: _selectedType!.displayName,
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _selectedCondition!.displayName,
        imageUrls: [],
        selectedIcon: _selectedIcon,
        quantity: int.parse(_quantityController.text),
        location: _locationController.text.trim(),
        status: DonationStatus.pending,
        submittedAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _donationService.submitDonation(donation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.orange[400],
        title: const Text('Donate Equipment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.orange[400],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thank You for Donating!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your donation will help those in need',
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
                ),
              ),
              const SizedBox(height: 24),

              // Equipment Type
              Text(
                'Equipment Type *',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EquipmentType>(
                value: _selectedType,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    _selectedType != null
                        ? _typeIcons[_selectedType]
                        : Icons.category,
                    color: Colors.grey[400],
                  ),
                ),
                items: EquipmentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _typeIcons[type],
                          color: Colors.orange[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    // Auto-select matching icon
                    if (value != null && _typeIcons.containsKey(value)) {
                      _selectedIcon = _availableIcons.firstWhere(
                        (i) => i['icon'] == _typeIcons[value],
                        orElse: () => _availableIcons.first,
                      )['name'];
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Text(
                'Select Icon for Item',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((iconData) {
                        final isSelected = _selectedIcon == iconData['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIcon = iconData['name']);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange[400]
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.orange[300]!,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              iconData['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[400],
                              size: 28,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedIcon != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Selected: ${_selectedIcon!.replaceAll('_', ' ')}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Item Name
              Text(
                'Item Name *',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Standard Wheelchair',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.label, color: Colors.grey[400]),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Description *',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the item, its features, and condition...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              // Condition
              Text(
                'Condition *',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ItemCondition>(
                value: _selectedCondition,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.check_circle, color: Colors.grey[400]),
                ),
                items: ItemCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.displayName),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCondition = value),
              ),
              const SizedBox(height: 16),

              // Quantity and Location Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity *',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.numbers,
                              color: Colors.grey[400],
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            final num = int.tryParse(value!);
                            if (num == null || num < 1) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location *',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'City, Area',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: Colors.grey[400],
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Notes
              Text(
                'Additional Notes (Optional)',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any additional information...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit Donation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
