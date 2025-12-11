import 'package:flutter/material.dart';

class LocationResult {
  final String address;

  LocationResult({required this.address});
}

// Simple text-based location picker
class LocationPickerScreen extends StatefulWidget {
  final String? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialLocation ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Enter Location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pop(LocationResult(address: _controller.text));
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter address, city or area...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick location suggestions
            Text(
              'Quick Select',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickLocationChip('Manama, Bahrain'),
                _quickLocationChip('Muharraq, Bahrain'),
                _quickLocationChip('Riffa, Bahrain'),
                _quickLocationChip('Isa Town, Bahrain'),
                _quickLocationChip('Hamad Town, Bahrain'),
                _quickLocationChip('Sitra, Bahrain'),
              ],
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(LocationResult(address: _controller.text));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLocationChip(String location) {
    return ActionChip(
      label: Text(location),
      backgroundColor: Colors.grey[700],
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () {
        _controller.text = location;
      },
    );
  }
}

// Location Field Widget for easy integration
class LocationPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final Function(LocationResult)? onLocationSelected;

  const LocationPickerField({
    super.key,
    required this.controller,
    this.labelText = 'Location *',
    this.validator,
    this.onLocationSelected,
  });

  void _openLocationPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerScreen(initialLocation: controller.text),
      ),
    );

    if (result != null) {
      controller.text = result.address;
      onLocationSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.edit_location_alt, color: Colors.blue[400]),
          onPressed: () => _openLocationPicker(context),
        ),
      ),
      onTap: () => _openLocationPicker(context),
      validator: validator,
    );
  }
}
