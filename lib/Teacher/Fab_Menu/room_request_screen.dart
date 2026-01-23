import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Room Request Screen - Request a room for class or meeting
class RoomRequestScreen extends StatefulWidget {
  const RoomRequestScreen({super.key});

  @override
  State<RoomRequestScreen> createState() => _RoomRequestScreenState();
}

class _RoomRequestScreenState extends State<RoomRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  
  String? _selectedRoom;
  String? _selectedTimeSlot;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  final List<Map<String, dynamic>> availableRooms = [
    {'name': 'Room 301', 'capacity': 60, 'type': 'Classroom'},
    {'name': 'Room 401', 'capacity': 80, 'type': 'Classroom'},
    {'name': 'Room 501', 'capacity': 100, 'type': 'Seminar Hall'},
    {'name': 'Lab 201', 'capacity': 30, 'type': 'Computer Lab'},
    {'name': 'Lab 203', 'capacity': 30, 'type': 'Computer Lab'},
    {'name': 'Research Lab', 'capacity': 15, 'type': 'Research'},
  ];

  final List<String> timeSlots = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 01:00',
    '02:00 - 03:00',
    '03:00 - 04:00',
    '04:00 - 05:00',
  ];

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('Room Request'),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.deepOrange[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request a Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Book for class, meeting, or event',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Select Room
              _buildLabel('Select Room', isDarkMode),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(isDarkMode)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoom,
                    isExpanded: true,
                    hint: Text('Choose a room', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
                    dropdownColor: AppColors.surface(isDarkMode),
                    items: availableRooms.map((room) {
                      return DropdownMenuItem(
                        value: room['name'] as String,
                        child: Row(
                          children: [
                            Icon(
                              room['type'] == 'Computer Lab' ? Icons.computer : Icons.meeting_room,
                              size: 18,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${room['name']} (${room['capacity']} seats)',
                              style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRoom = value),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Select Date
              _buildLabel('Select Date', isDarkMode),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(isDarkMode)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkMode),
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary(isDarkMode)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Select Time Slot
              _buildLabel('Select Time Slot', isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlots.map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Purpose
              _buildLabel('Purpose', isDarkMode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Extra class for CSE 3201, Meeting with students...',
                  hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                  filled: true,
                  fillColor: AppColors.surface(isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Purpose is required' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a room'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a time slot'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate request submission
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room request for $_selectedRoom submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context);
    });
  }
}
