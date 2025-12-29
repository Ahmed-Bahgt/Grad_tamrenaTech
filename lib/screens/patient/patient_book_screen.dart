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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme_provider.dart';
import '../../utils/availability_manager.dart';
import '../../utils/patient_bookings_manager.dart';
import '../../utils/patient_manager.dart';

class PatientBookScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const PatientBookScreen({super.key, this.onBack});

  @override
  State<PatientBookScreen> createState() => _PatientBookScreenState();
}

class _PatientBookScreenState extends State<PatientBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AvailabilityManager _availabilityManager = AvailabilityManager();
  List<DoctorInfo> _allDoctors = [];
  List<DoctorInfo> _filteredDoctors = [];
  bool _isLoadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorsFromFirestore();
  }

  Future<void> _loadDoctorsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('doctors').get();

      final doctors = snapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final fullName = firstName.isNotEmpty && lastName.isNotEmpty
            ? 'Dr. $firstName $lastName'
            : data['fullName'] as String? ?? 'Dr. Unknown';

        return DoctorInfo(
          id: doc.id,
          name: fullName,
          specialty: data['degree'] as String? ?? 'Physiotherapy Specialist',
          rating: 4.8, // Default rating, can be calculated from reviews
          experience: '5 years', // Can be calculated from graduation date
          image: '👨‍⚕️',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allDoctors = doctors;
          _isLoadingDoctors = false;
        });
        _filterDoctors('');
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted) {
        setState(() {
          _isLoadingDoctors = false;
        });
      }
    }
  }

  String _searchQuery = '';

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
        _filteredDoctors = List.from(_allDoctors);
      } else {
        _filteredDoctors = _allDoctors
            .where((doctor) =>
                doctor.name.toLowerCase().contains(query.toLowerCase()) ||
                doctor.specialty.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showSlotSelection(BuildContext context, DoctorInfo doctor) {
    // Keep a stable reference to the page context for navigations/dialogs
    final pageContext = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                  onPressed: () => Navigator.pop(sheetContext),
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
            child: StreamBuilder<List<AvailabilitySlot>>(
              stream: AvailabilityManager.watchDoctorSlots(doctor.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDark
                          ? const Color(0xFF29B6F6)
                          : const Color(0xFF8BC34A),
                    ),
                  );
                }
                final slots = snapshot.data ?? const [];
                if (slots.isEmpty) {
                  return Center(
                    child: Text(
                      t('No available slots', 'لا توجد مواعيد متاحة'),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: slots.length,
                  itemBuilder: (itemContext, index) {
                    final slot = slots[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF0D1117) : Colors.grey[50],
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
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF29B6F6)
                                  : const Color(0xFF8BC34A),
                            ),
                            onPressed: () {
                              _bookAppointment(
                                  pageContext, sheetContext, doctor, slot);
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

  void _bookAppointment(BuildContext pageContext, BuildContext sheetContext,
      DoctorInfo doctor, AvailabilitySlot slot) {
    final isDark = Theme.of(pageContext).brightness == Brightness.dark;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF29B6F6) : const Color(0xFF8BC34A),
            ),
            onPressed: () async {
              // Save booking data before closing any dialogs
              final bookingDate =
                  DateTime(slot.date.year, slot.date.month, slot.date.day);
              final bookingDateTime = bookingDate.add(Duration(
                hours: slot.timeFrom.hour,
                minutes: slot.timeFrom.minute,
              ));
              final endDateTime = bookingDate.add(Duration(
                hours: slot.timeTo.hour,
                minutes: slot.timeTo.minute,
              ));

              final booking = PatientBooking(
                id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
                doctorId: doctor.id,
                doctorName: doctor.name,
                specialty: doctor.specialty,
                dateTime: bookingDateTime,
                endTime: endDateTime,
                doctorImage: doctor.image,
              );

              // Close confirmation dialog first
              if (mounted) Navigator.of(dialogContext).pop();

              // Capture navigator before async gap
              final sheetNavigator = Navigator.of(sheetContext);

              // Wait a frame
              await Future.delayed(const Duration(milliseconds: 100));

              // Close bottom sheet using captured navigator to avoid context across async gap
              if (mounted) sheetNavigator.pop();

              // Save booking data
              if (mounted) {
                final patientId = FirebaseAuth.instance.currentUser?.uid ?? '';
                final patientDoc = await FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .get();

                final patientData = patientDoc.data();
                final firstName = patientData?['firstName'] as String? ?? '';
                final lastName = patientData?['lastName'] as String? ?? '';
                final patientName = firstName.isNotEmpty && lastName.isNotEmpty
                    ? '$firstName $lastName'
                    : patientData?['fullName'] as String? ?? 'Patient';

                // Add booking
                PatientBookingsManager().addBooking(booking);

                // Remove slot from doctor's availability
                await AvailabilityManager.removeSlotForDoctor(doctor.id, slot);

                // Assign patient to doctor's care (this will remove from "All Patients" tab)
                await PatientManager.assignPatientToDoctor(
                    patientId, doctor.id, patientName);

                debugPrint(
                    '[PatientBook] Booking completed - Patient: $patientName, Doctor: ${doctor.name}');

                // Show success dialog on next frame using stable page context
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showBookingSuccess(pageContext, doctor, slot);
                  }
                });
              }
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

  void _showBookingSuccess(
      BuildContext context, DoctorInfo doctor, AvailabilitySlot slot) {
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
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
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
        actions: [
          IconButton(
            tooltip: t('All Slots', 'كل المواعيد'),
            icon: const Icon(Icons.calendar_month, color: Color(0xFF8BC34A)),
            onPressed: () => _showAllSlots(context),
          ),
        ],
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
                hintStyle:
                    TextStyle(color: isDark ? Colors.white38 : Colors.black38),
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
            child: _isLoadingDoctors
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8BC34A),
                    ),
                  )
                : _filteredDoctors.isEmpty
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

  void _showAllSlots(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final pageContext = context;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    t('All Available Slots', 'كل المواعيد المتاحة'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<GlobalAvailabilityItem>>(
                stream: AvailabilityManager.watchAllSlots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8BC34A)));
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        t('No available slots', 'لا توجد مواعيد متاحة'),
                        style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final slot = item.slot;
                      final doctor = DoctorInfo(
                        id: item.doctorId,
                        name: item.doctorName,
                        specialty: item.doctorDegree,
                        rating: 4.8,
                        experience: '5 years',
                        image: '👨‍⚕️',
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D1117)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  isDark ? Colors.white12 : Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDate(slot.date)} · ${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF29B6F6)
                                    : const Color(0xFF8BC34A),
                              ),
                              onPressed: () {
                                _bookAppointment(
                                    pageContext, sheetContext, doctor, slot);
                              },
                              child: Text(t('Book', 'احجز'),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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
                      const Icon(Icons.star,
                          color: Color(0xFFFFB300), size: 16),
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
                backgroundColor:
                    isDark ? const Color(0xFF29B6F6) : const Color(0xFF8BC34A),
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
