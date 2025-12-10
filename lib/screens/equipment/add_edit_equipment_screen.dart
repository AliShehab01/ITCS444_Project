import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/equipment_item.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';

class AddEditEquipmentScreen extends StatefulWidget {
  final EquipmentItem? item;

  const AddEditEquipmentScreen({super.key, this.item});

  @override
  State<AddEditEquipmentScreen> createState() => _AddEditEquipmentScreenState();
}

class _AddEditEquipmentScreenState extends State<AddEditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentalPriceController = TextEditingController();
  final _tagsController = TextEditingController();

  EquipmentType _selectedType = EquipmentType.wheelchair;
  ItemCondition _selectedCondition = ItemCondition.good;
  ItemStatus _selectedStatus = ItemStatus.available;
  bool _isDonated = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _loadItemData();
    }
  }

  void _loadItemData() {
    final item = widget.item!;
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _quantityController.text = item.quantity.toString();
    _locationController.text = item.location;
    _rentalPriceController.text = item.rentalPricePerDay?.toString() ?? '';
    _tagsController.text = item.tags.join(', ');
    _selectedType = item.type;
    _selectedCondition = item.condition;
    _selectedStatus = item.status;
    _isDonated = item.isDonated;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _rentalPriceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) throw 'User not authenticated';

        final userData = await _authService.getUserData(user.uid);
        if (userData == null) throw 'User data not found';

        final tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        final equipment = EquipmentItem(
          id: widget.item?.id ?? '',
          name: _nameController.text.trim(),
          type: _selectedType,
          description: _descriptionController.text.trim(),
          imageUrls: widget.item?.imageUrls ?? [],
          condition: _selectedCondition,
          quantity: int.parse(_quantityController.text),
          location: _locationController.text.trim(),
          tags: tags,
          status: _selectedStatus,
          rentalPricePerDay: _rentalPriceController.text.isNotEmpty
              ? double.parse(_rentalPriceController.text)
              : null,
          ownerId: user.uid,
          ownerName: userData.name,
          createdAt: widget.item?.createdAt ?? DateTime.now(),
          isDonated: _isDonated,
        );

        if (widget.item == null) {
          await _equipmentService.addEquipment(equipment);
        } else {
          await _equipmentService.updateEquipment(equipment);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.item == null
                    ? 'Equipment added successfully!'
                    : 'Equipment updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(widget.item == null ? 'Add Equipment' : 'Edit Equipment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Equipment Name *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter equipment name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<EquipmentType>(
                value: _selectedType,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Equipment Type *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: EquipmentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              // Condition Dropdown
              DropdownButtonFormField<ItemCondition>(
                value: _selectedCondition,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Condition *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ItemCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCondition = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter quantity';
                  if (int.tryParse(value!) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Location *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),

              // Rental Price Field
              TextFormField(
                controller: _rentalPriceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Rental Price Per Day (Optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tags Field
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'e.g., mobility, senior, lightweight',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<ItemStatus>(
                value: _selectedStatus,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Status *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ItemStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Is Donated Checkbox
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'This is a donated item',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _isDonated,
                  activeColor: Colors.blue[400],
                  onChanged: (value) {
                    setState(() {
                      _isDonated = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEquipment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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
                    : Text(
                        widget.item == null
                            ? 'Add Equipment'
                            : 'Update Equipment',
                        style: const TextStyle(
                          fontSize: 16,
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
