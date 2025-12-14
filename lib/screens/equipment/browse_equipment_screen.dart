import 'package:flutter/material.dart';
import '../../models/equipment_item.dart';
import '../../models/user_role.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';
import 'equipment_detail_screen.dart';
import 'add_edit_equipment_screen.dart';

class BrowseEquipmentScreen extends StatefulWidget {
  final bool showMyItemsOnly;
  final String? initialSearchQuery;
  final bool forceRenterView;

  const BrowseEquipmentScreen({
    super.key,
    this.showMyItemsOnly = false,
    this.initialSearchQuery,
    this.forceRenterView = false,
  });

  @override
  State<BrowseEquipmentScreen> createState() => _BrowseEquipmentScreenState();
}

class _BrowseEquipmentScreenState extends State<BrowseEquipmentScreen> {
  final _equipmentService = EquipmentService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  EquipmentType? _filterType;
  ItemStatus? _filterStatus;
  bool _showDonatedOnly = false;
  bool _showMyItemsOnly = false;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _showMyItemsOnly = widget.showMyItemsOnly;
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await _authService.getUserData(
      _authService.currentUser?.uid ?? '',
    );
    if (user != null && mounted) {
      setState(() {
        _userRole = user.role;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<EquipmentItem>> _getFilteredEquipment() {
    if (_showMyItemsOnly) {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId != null) {
        return _equipmentService.getEquipmentByOwner(currentUserId);
      }
    }

    if (_showDonatedOnly) {
      return _equipmentService.getDonatedItems();
    } else if (_filterType != null) {
      return _equipmentService.filterByType(_filterType!);
    } else if (_filterStatus != null) {
      return _equipmentService.filterByStatus(_filterStatus!);
    } else {
      return _equipmentService.getAllEquipmentStream();
    }
  }

  List<EquipmentItem> _applySearchFilter(List<EquipmentItem> items) {
    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
      final searchLower = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(searchLower) ||
          item.description.toLowerCase().contains(searchLower) ||
          item.type.displayName.toLowerCase().contains(searchLower);
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Filter Equipment',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type Filter
              DropdownButtonFormField<EquipmentType?>(
                value: _filterType,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Equipment Type',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...EquipmentType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filterType = value),
              ),
              const SizedBox(height: 16),

              // Status Filter
              DropdownButtonFormField<ItemStatus?>(
                value: _filterStatus,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...ItemStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filterStatus = value),
              ),
              const SizedBox(height: 16),

              // My Items Only Checkbox
              CheckboxListTile(
                title: const Text(
                  'My Items Only',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showMyItemsOnly,
                activeColor: Colors.purple[400],
                onChanged: (value) =>
                    setState(() => _showMyItemsOnly = value ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterStatus = null;
                _showDonatedOnly = false;
                _showMyItemsOnly = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Browse Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Chips
          if (_filterType != null ||
              _filterStatus != null ||
              _showDonatedOnly ||
              _showMyItemsOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterType != null)
                    Chip(
                      label: Text(_filterType!.displayName),
                      onDeleted: () => setState(() => _filterType = null),
                    ),
                  if (_filterStatus != null)
                    Chip(
                      label: Text(_filterStatus!.displayName),
                      onDeleted: () => setState(() => _filterStatus = null),
                    ),
                  if (_showDonatedOnly)
                    Chip(
                      label: const Text('Donated'),
                      onDeleted: () => setState(() => _showDonatedOnly = false),
                    ),
                  if (_showMyItemsOnly)
                    Chip(
                      label: const Text('My Items'),
                      backgroundColor: Colors.purple[400]!.withOpacity(0.2),
                      labelStyle: TextStyle(color: Colors.purple[400]),
                      onDeleted: () => setState(() => _showMyItemsOnly = false),
                    ),
                ],
              ),
            ),

          // Equipment List
          Expanded(
            child: StreamBuilder<List<EquipmentItem>>(
              stream: _getFilteredEquipment(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No equipment found',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredItems = _applySearchFilter(snapshot.data!);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildEquipmentCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(EquipmentItem item) {
    final isAdmin = _userRole == UserRole.admin && !widget.forceRenterView;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(
                item: item,
                forceRenterView: widget.forceRenterView,
              ),
            ),
          ).then((_) => setState(() {})); // Refresh list when returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEquipmentIcon(item.type),
                  color: _getStatusColor(item.status),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.type.displayName,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(item.status),
                        const SizedBox(width: 8),
                        if (item.isDonated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[400]!.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Donated',
                              style: TextStyle(
                                color: Colors.orange[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Admin actions or arrow
              if (isAdmin) ...[
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue[400]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditEquipmentScreen(item: item),
                      ),
                    ).then((_) => setState(() {})); // Refresh list
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400]),
                  onPressed: () => _showDeleteConfirmation(item),
                ),
              ] else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ItemStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getStatusColor(status),
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

  void _showDeleteConfirmation(EquipmentItem item) {
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
                await _equipmentService.deleteEquipment(item.id);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh list
                }
              } catch (e) {
                if (mounted) {
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
