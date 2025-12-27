import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';
import '../../utils/patient_bookings_manager.dart';
import '../../utils/medical_plans_manager.dart';
import '../../utils/patient_profile_manager.dart';
import 'start_session_screen.dart';

/// Patient Home Screen with 4 sections
class PatientHomeScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const PatientHomeScreen({super.key, this.onBack});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late PatientBookingsManager _bookingsManager;
  late MedicalPlansManager _plansManager;
  late PatientProfileManager _profileManager;

  @override
  void initState() {
    super.initState();
    _bookingsManager = PatientBookingsManager();
    _plansManager = MedicalPlansManager();
    _profileManager = PatientProfileManager();
    _bookingsManager.addListener(_onBookingsChanged);
    _plansManager.addListener(_onPlansChanged);
    _profileManager.addListener(_onProfileChanged);
  }

  void _onBookingsChanged() {
    setState(() {});
  }

  void _onPlansChanged() {
    setState(() {});
  }

  void _onProfileChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _bookingsManager.removeListener(_onBookingsChanged);
    _plansManager.removeListener(_onPlansChanged);
    _profileManager.removeListener(_onProfileChanged);
    super.dispose();
  }

  // Accent color helpers: green in light mode, light blue in dark mode
  Color _accentColor(bool isDark) =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF8BC34A);
  Color _accentAltColor(bool isDark) =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF7CB342);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientName = _profileManager.patientName;

    return Scaffold(
      appBar: CustomAppBar(title: t('Home', 'الرئيسية'), onBack: widget.onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Welcome Message (full-bleed)
              _buildWelcomeSection(isDark, patientName),

              // The rest of sections keep horizontal padding
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 2: Upcoming Bookings
                    _buildUpcomingBookingsSection(isDark),
                    const SizedBox(height: 24),

                    // Section 3: Medical Plan
                    _buildMedicalPlanSection(isDark),
                    const SizedBox(height: 24),

                    // Section 4: Doctor Notes
                    _buildDoctorNotesSection(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark, String patientName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      // Add horizontal margins per request
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor(isDark),
            _accentAltColor(isDark),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Full-bleed banner keeps subtle rounding on bottom only
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Welcome back,', 'أهلاً وسهلاً,'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            patientName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('Continue your recovery journey with us.',
                'استمر في رحلة التعافي معنا.'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookingsSection(bool isDark) {
    final upcomingBookings = _bookingsManager.upcomingBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Upcoming Appointments', 'المواعيد القادمة'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (upcomingBookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                t('No upcoming appointments', 'لا توجد مواعيد قادمة'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingBookings.length,
            itemBuilder: (context, index) {
              final booking = upcomingBookings[index];
              return _buildBookingCard(booking, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(PatientBooking booking, bool isDark) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _accentColor(isDark).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                booking.doctorImage,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.specialty,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(booking.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${timeFormat.format(booking.dateTime)} - ${timeFormat.format(booking.endTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t('Cancel booking', 'إلغاء الحجز'),
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.white70 : Colors.black45,
            ),
            onPressed: () => _confirmCancelBooking(booking),
          ),
        ],
      ),
    );
  }

  void _confirmCancelBooking(PatientBooking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t('Cancel booking?', 'إلغاء الحجز؟')),
          content: Text(
            t(
              'Do you want to remove this appointment with ${booking.doctorName}?',
              'هل تريد إلغاء هذا الموعد مع ${booking.doctorName}؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Keep', 'ابقاء')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _bookingsManager.removeBookingById(booking.id);
              },
              child: Text(
                t('Remove', 'إلغاء'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicalPlanSection(bool isDark) {
    final activePlan = _plansManager.activePlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Medical Plan', 'الخطة الطبية'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (activePlan == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                t('No active medical plan', 'لا توجد خطة طبية نشطة'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activePlan.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t('Session', 'الجلسة')} ${activePlan.completedSessions}/${activePlan.totalSessions}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor(isDark).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activePlan.progress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _accentColor(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: activePlan.progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _accentColor(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StartSessionScreen(
                            planName: activePlan.name,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      t('Start Today\'s Session', 'ابدأ جلسة اليوم'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDoctorNotesSection(bool isDark) {
    const doctorNotes = [
      'Continue with the current rehabilitation plan. Progress is excellent.',
      'Focus on improving range of motion during exercises.',
      'Schedule follow-up consultation in 2 weeks.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Doctor\'s Notes', 'ملاحظات الطبيب'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              doctorNotes.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                    bottom: index < doctorNotes.length - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _accentColor(isDark),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doctorNotes[index],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
