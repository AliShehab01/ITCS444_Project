import 'package:flutter/material.dart';
import '../../models/equipment_item.dart';
import '../../models/rental_request.dart';
import '../../services/rental_service.dart';
import '../../services/auth_service.dart';

class RentalRequestForm extends StatefulWidget {
  final EquipmentItem item;

  const RentalRequestForm({super.key, required this.item});

  @override
  State<RentalRequestForm> createState() => _RentalRequestFormState();
}

class _RentalRequestFormState extends State<RentalRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _rentalService = RentalService();
  final _authService = AuthService();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  List<DateTimeRange> _reservedDates = [];
  bool _loadingReservations = true;

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
  }

  Future<void> _loadReservedDates() async {
    try {
      final reserved = await _rentalService.getReservedDatesForItem(
        widget.item.id,
      );
      setState(() {
        _reservedDates = reserved;
        _loadingReservations = false;
      });
    } catch (e) {
      setState(() {
        _loadingReservations = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isDateReserved(DateTime date) {
    for (var reserved in _reservedDates) {
      if (!date.isBefore(reserved.start) && !date.isAfter(reserved.end)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // First, select start date
    final DateTime? startPicked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT START DATE',
      selectableDayPredicate: (date) {
        return !_isDateReserved(date);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green[400]!,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.green[400]),
            ),
          ),
          child: child!,
        );
      },
    );

    if (startPicked == null || !context.mounted) return;

    // Then select end date
    final DateTime? endPicked = await showDatePicker(
      context: context,
      initialDate: startPicked.add(const Duration(days: 1)),
      firstDate: startPicked,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT END DATE',
      selectableDayPredicate: (date) {
        if (date.isBefore(startPicked)) return false;

        DateTime current = startPicked;
        while (!current.isAfter(date)) {
          if (_isDateReserved(current)) {
            return false;
          }
          current = current.add(const Duration(days: 1));
        }
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green[400]!,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.green[400]),
            ),
          ),
          child: child!,
        );
      },
    );

    if (endPicked != null && mounted) {
      setState(() {
        _startDate = startPicked;
        _endDate = endPicked;
      });
    }
  }

  int _calculateDuration() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double? _calculateTotalCost() {
    if (widget.item.rentalPricePerDay == null) return null;
    return widget.item.rentalPricePerDay! * _calculateDuration();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select rental dates'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Check if dates are available
        final isAvailable = await _rentalService.isDateRangeAvailable(
          widget.item.id,
          _startDate!,
          _endDate!,
        );

        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Selected dates are not available. Please choose different dates.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final user = _authService.currentUser;
        if (user == null) throw 'User not authenticated';

        final userData = await _authService.getUserData(user.uid);
        if (userData == null) throw 'User data not found';

        final request = RentalRequest(
          id: '',
          itemId: widget.item.id,
          itemName: widget.item.name,
          renterId: user.uid,
          renterName: userData.name,
          renterContact: userData.contact,
          startDate: _startDate!,
          endDate: _endDate!,
          status: RentalStatus.pending,
          createdAt: DateTime.now(),
          renterNotes: _notesController.text.trim(),
          totalCost: _calculateTotalCost(),
          durationDays: _calculateDuration(),
        );

        await _rentalService.createRentalRequest(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rental request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          Navigator.of(context).pop();
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
        title: const Text('Request Rental'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item Info Card
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 40,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.item.type.displayName,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reserved Dates Info
              if (_loadingReservations)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading availability...',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (_reservedDates.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[400]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange[400]!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reserved Dates',
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._reservedDates.take(3).map((range) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.orange[400],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${range.start.day}/${range.start.month}/${range.start.year} - ${range.end.day}/${range.end.month}/${range.end.year}',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (_reservedDates.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${_reservedDates.length - 3} more reservation(s)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[400]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green[400]!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This item has no reservations - available anytime!',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Start Date
              Text(
                'Rental Period',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Date Range Selector
              InkWell(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green[400]!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, color: Colors.green[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Rental Period',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_reservedDates.isNotEmpty)
                                  Text(
                                    'Reserved dates will be disabled',
                                    style: TextStyle(
                                      color: Colors.orange[400],
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Not selected',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate != null
                                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'Not selected',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
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

              // Duration & Cost Summary
              if (_startDate != null && _endDate != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[400]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[400]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '${_calculateDuration()} days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_calculateTotalCost() != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Cost:',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            Text(
                              '\$${_calculateTotalCost()!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.blue[400],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'Any special requirements or notes...',
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
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
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
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
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
