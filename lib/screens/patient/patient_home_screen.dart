import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';
import '../../utils/patient_bookings_manager.dart';
import '../../utils/medical_plans_manager.dart';
import '../../utils/patient_profile_manager.dart';
import '../../utils/responsive_utils.dart';
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
    final patientName = globalThemeProvider.displayName.isNotEmpty
        ? globalThemeProvider.displayName
        : _profileManager.patientName;

    return Scaffold(
      appBar: CustomAppBar(title: t('Home', 'الرئيسية'), onBack: widget.onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Welcome Message (full-bleed)
              _buildWelcomeSection(context, isDark, patientName),

              // The rest of sections keep horizontal padding
              Padding(
                padding: ResponsiveUtils.horizontalPadding(context).copyWith(
                  top: ResponsiveUtils.verticalSpacing(context, 24),
                  bottom: ResponsiveUtils.verticalSpacing(context, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 2: Upcoming Bookings
                    _buildUpcomingBookingsSection(context, isDark),
                    SizedBox(height: ResponsiveUtils.verticalSpacing(context, 24)),

                    // Section 3: Medical Plan
                    _buildMedicalPlanSection(context, isDark),
                    SizedBox(height: ResponsiveUtils.verticalSpacing(context, 24)),

                    // Section 4: Doctor Notes
                    _buildDoctorNotesSection(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDark, String patientName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.padding(context, 20),
        vertical: ResponsiveUtils.verticalSpacing(context, 24),
      ),
      margin: ResponsiveUtils.horizontalPadding(context).copyWith(top: 0, bottom: 0),
      // Remove fixed height to allow content to expand naturally
      // height: ResponsiveUtils.isMobile(context)
      //     ? 140
      //     : ResponsiveUtils.verticalSpacing(context, 160),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor(isDark),
            _accentAltColor(isDark),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('Welcome back,', 'أهلاً وسهلاً,'),
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Flexible(
              child: Text(
                patientName,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 32),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              t('Continue your recovery journey with us.',
                  'استمر في رحلة التعافي معنا.'),
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookingsSection(BuildContext context, bool isDark) {
    final upcomingBookings = _bookingsManager.upcomingBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Upcoming Appointments', 'المواعيد القادمة'),
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        if (upcomingBookings.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 24),
            ),
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
                  fontSize: ResponsiveUtils.fontSize(context, 14),
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
              return _buildBookingCard(context, booking, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, PatientBooking booking, bool isDark) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
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
            width: ResponsiveUtils.isMobile(context) ? 40 : 50,
            height: ResponsiveUtils.isMobile(context) ? 40 : 50,
            decoration: BoxDecoration(
              color: _accentColor(isDark).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                booking.doctorImage,
                style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 24)),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.doctorName,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  booking.specialty,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveUtils.iconSize(context, 14),
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      dateFormat.format(booking.dateTime),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Icon(
                      Icons.access_time,
                      size: ResponsiveUtils.iconSize(context, 14),
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      '${timeFormat.format(booking.dateTime)} - ${timeFormat.format(booking.endTime)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12),
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
              size: ResponsiveUtils.iconSize(context, 20),
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
              onPressed: () async {
                Navigator.pop(context);
                await _bookingsManager.cancelBooking(booking);
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

  Widget _buildMedicalPlanSection(BuildContext context, bool isDark) {
    final activePlan = _plansManager.activePlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Medical Plan', 'الخطة الطبية'),
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        if (activePlan == null)
          Container(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 24),
            ),
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
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                ),
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
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
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            '${t('Session', 'الجلسة')} ${activePlan.completedSessions}/${activePlan.totalSessions}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 12),
                        vertical: ResponsiveUtils.spacing(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor(isDark).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activePlan.calculatedProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _accentColor(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: activePlan.calculatedProgress / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _accentColor(isDark),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor(isDark),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 12),
                      ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.fontSize(context, 16),
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

  Widget _buildDoctorNotesSection(BuildContext context, bool isDark) {
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
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
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
                    bottom: index < doctorNotes.length - 1 ? ResponsiveUtils.spacing(context, 12) : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: ResponsiveUtils.spacing(context, 4)),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _accentColor(isDark),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Text(
                        doctorNotes[index],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.5,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
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
