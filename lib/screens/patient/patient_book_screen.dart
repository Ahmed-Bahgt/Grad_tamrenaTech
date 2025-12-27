// =============================================================================
// PATIENT BOOK SCREEN - DOCTOR APPOINTMENT BOOKING
// =============================================================================
// Purpose: Browse and book available doctor appointments
// Features:
// - List of doctors with their available slots
// - Search by doctor name
// - Filter by date
// - Book appointments
// - View booking confirmation
// Data Source:
// - AvailabilityManager (shared with doctors)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/theme_provider.dart';
import '../../utils/availability_manager.dart';
import '../../utils/patient_bookings_manager.dart';

class PatientBookScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const PatientBookScreen({super.key, this.onBack});

  @override
  State<PatientBookScreen> createState() => _PatientBookScreenState();
}

class _PatientBookScreenState extends State<PatientBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AvailabilityManager _availabilityManager = AvailabilityManager();
  
  // Mock doctor data with availability
  final List<DoctorInfo> _allDoctors = [
    DoctorInfo(
      id: '1',
      name: 'Dr. Ahmed Hassan',
      specialty: 'Physiotherapy Specialist',
      rating: 4.8,
      experience: '10 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '2',
      name: 'Dr. Sarah Ali',
      specialty: 'Sports Medicine',
      rating: 4.9,
      experience: '8 years',
      image: '👩‍⚕️',
    ),
    DoctorInfo(
      id: '3',
      name: 'Dr. Mohammed Khalid',
      specialty: 'Orthopedic Physical Therapy',
      rating: 4.7,
      experience: '12 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '4',
      name: 'Dr. Fatima Noor',
      specialty: 'Rehabilitation Specialist',
      rating: 4.9,
      experience: '7 years',
      image: '👩‍⚕️',
    ),
    DoctorInfo(
      id: '5',
      name: 'Dr. Karim Mansour',
      specialty: 'Sports Injury Recovery',
      rating: 4.6,
      experience: '9 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '6',
      name: 'Dr. Layla Hassan',
      specialty: 'Post-Surgical Rehabilitation',
      rating: 4.8,
      experience: '11 years',
      image: '👩‍⚕️',
    ),
    DoctorInfo(
      id: '7',
      name: 'Dr. Omar Zaki',
      specialty: 'Pediatric Physiotherapy',
      rating: 4.7,
      experience: '6 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '8',
      name: 'Dr. Nadia Karim',
      specialty: 'Neurological Rehabilitation',
      rating: 4.9,
      experience: '10 years',
      image: '👩‍⚕️',
    ),
    DoctorInfo(
      id: '9',
      name: 'Dr. Hassan Ibrahim',
      specialty: 'Back Pain Specialist',
      rating: 4.8,
      experience: '14 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '10',
      name: 'Dr. Amira Amin',
      specialty: 'Geriatric Physiotherapy',
      rating: 4.7,
      experience: '8 years',
      image: '👩‍⚕️',
    ),
    DoctorInfo(
      id: '11',
      name: 'Dr. Youssef Rashid',
      specialty: 'Sports Performance',
      rating: 4.9,
      experience: '9 years',
      image: '👨‍⚕️',
    ),
    DoctorInfo(
      id: '12',
      name: 'Dr. Hana Samir',
      specialty: 'Cardiac Rehabilitation',
      rating: 4.6,
      experience: '7 years',
      image: '👩‍⚕️',
    ),
  ];

  List<DoctorInfo> _filteredDoctors = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _availabilityManager.addListener(_onSlotsChanged);
    // Filter doctors to only those with available slots
    _filteredDoctors = _allDoctors
        .where((doctor) => _availabilityManager.slots.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _availabilityManager.removeListener(_onSlotsChanged);
    super.dispose();
  }

  void _onSlotsChanged() {
    setState(() {});
  }

  void _filterDoctors(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDoctors = _allDoctors
            .where((doctor) => _availabilityManager.slots.isNotEmpty)
            .toList();
      } else {
        _filteredDoctors = _allDoctors
            .where((doctor) =>
                (doctor.name.toLowerCase().contains(query.toLowerCase()) ||
                    doctor.specialty.toLowerCase().contains(query.toLowerCase())) &&
                _availabilityManager.slots.isNotEmpty)
            .toList();
      }
    });
  }

  void _showSlotSelection(BuildContext context, DoctorInfo doctor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  t('Select a Slot', 'اختر موعداً'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Doctor Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Doctor: ', 'الطبيب: '),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  doctor.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Slots List
          Expanded(
            child: _availabilityManager.slots.isEmpty
                ? Center(
                    child: Text(
                      t('No available slots', 'لا توجد مواعيد متاحة'),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availabilityManager.slots.length,
                    itemBuilder: (context, index) {
                      final slot = _availabilityManager.slots[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(slot.date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8BC34A),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _bookAppointment(context, doctor, slot);
                              },
                              child: Text(
                                t('Book', 'احجز'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _bookAppointment(BuildContext context, DoctorInfo doctor, AvailabilitySlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Confirm Booking', 'تأكيد الحجز')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t('Doctor: ', 'الطبيب: ')}${doctor.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${t('Date: ', 'التاريخ: ')}${_formatDate(slot.date)}'),
            const SizedBox(height: 4),
            Text(
              '${t('Time: ', 'الوقت: ')}${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
            ),
            const SizedBox(height: 12),
            Text(
              t('Confirm this appointment?', 'تأكيد هذا الموعد؟'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showBookingSuccess(context, doctor, slot);
            },
            child: Text(
              t('Confirm', 'تأكيد'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSuccess(BuildContext context, DoctorInfo doctor, AvailabilitySlot slot) {
    // Save the booking to the manager
    final bookingDateTime = DateTime(
      slot.date.year,
      slot.date.month,
      slot.date.day,
      slot.timeFrom.hour,
      slot.timeFrom.minute,
    );
    final endDateTime = DateTime(
      slot.date.year,
      slot.date.month,
      slot.date.day,
      slot.timeTo.hour,
      slot.timeTo.minute,
    );

    final booking = PatientBooking(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      doctorName: doctor.name,
      specialty: doctor.specialty,
      dateTime: bookingDateTime,
      endTime: endDateTime,
      doctorImage: doctor.image,
    );

    PatientBookingsManager().addBooking(booking);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8BC34A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF8BC34A),
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('Booking Confirmed!', 'تم تأكيد الحجز!'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('Your appointment with ${doctor.name} has been booked successfully.',
                  'تم حجز موعدك مع ${doctor.name} بنجاح.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '${_formatDate(slot.date)} • ${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('Close', 'إغلاق'),
              style: const TextStyle(color: Color(0xFF8BC34A)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8BC34A)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          t('Book Appointment', 'حجز موعد'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterDoctors,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: t('Search by doctor name...', 'ابحث باسم الطبيب...'),
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8BC34A)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterDoctors('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Doctors List
          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('No doctors found', 'لم يتم العثور على أطباء'),
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _filteredDoctors[index];
                      return _DoctorCard(
                        doctor: doctor,
                        isDark: isDark,
                        onBook: () => _showSlotSelection(context, doctor),
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorInfo doctor;
  final bool isDark;
  final VoidCallback onBook;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;

  const _DoctorCard({
    required this.doctor,
    required this.isDark,
    required this.onBook,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8BC34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  doctor.image,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doctor.experience,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: onBook,
              child: Text(
                t('Book', 'احجز'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorInfo {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String experience;
  final String image;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experience,
    required this.image,
  });
}
