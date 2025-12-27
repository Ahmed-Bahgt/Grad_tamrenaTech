// =============================================================================
// DOCTOR HOME SCREEN - DASHBOARD & OVERVIEW
// =============================================================================
// Purpose: Main dashboard showing doctor's overview and quick access
// Features:
// - Welcome message with doctor's name
// - Summary cards: Total patients, Booked appointments
// - My Patients list with progress tracking
// - Available slots quick view with edit/remove actions
// Data Sources:
// - PatientManager (shared) - Syncs with Patient Management screen
// - AvailabilityManager (shared) - Syncs with Availability screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';
import '../../utils/availability_manager.dart';
import '../../utils/patient_manager.dart';

/// Doctor Home Screen
class DoctorHomeScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(int)? onNavigateToTab;
  const DoctorHomeScreen({super.key, this.onBack, this.onNavigateToTab});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final AvailabilityManager _manager = AvailabilityManager();
  final PatientManager _patientManager = PatientManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onSlotsChanged);
    _patientManager.addListener(_onPatientsChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onSlotsChanged);
    _patientManager.removeListener(_onPatientsChanged);
    super.dispose();
  }

  void _onSlotsChanged() {
    setState(() {});
  }

  void _onPatientsChanged() {
    setState(() {});
  }

  void _removeSlot(int index) {
    _manager.removeSlot(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('Slot removed', 'تم حذف الموعد')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editSlot(int index) {
    // Set the slot to edit in manager
    _manager.setEditingIndex(index);
    // Navigate to availability tab (index 1)
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Go to Availability tab to edit the slot',
              'انتقل إلى تبويب التوفر لتعديل الموعد')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final patients = _patientManager.myPatients;
    final totalPatients = patients.length;
    final bookedSlots = patients
        .where((p) => p.nextAppointment.isNotEmpty && p.nextAppointment != '—')
        .length;

    return Scaffold(
      appBar: CustomAppBar(
          title: t('Doctor Home', 'الصفحة الرئيسية للطبيب'),
          onBack: widget.onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Header
          Text(
            '${t('Welcome back, ', 'مرحباً بعودتك ')}${globalThemeProvider.displayName.isNotEmpty ? globalThemeProvider.displayName : t('Doctor', 'دكتور')}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('Here\'s a quick overview of your clinic today.',
                'إليك نظرة سريعة على عيادتك اليوم.'),
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: t('Patients', 'المرضى'),
                  value: '$totalPatients',
                  color: const Color(0xFF00BCD4),
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: t('Booked', 'محجوز'),
                  value: '$bookedSlots',
                  color: const Color(0xFF8BC34A),
                  icon: Icons.event_available,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            t('My Patients', 'مرضاي'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Patients list
          if (patients.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    t('No patients under your care yet',
                        'لا يوجد مرضى تحت رعايتك بعد'),
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            )
          else
            ...patients
                .map((p) => _PatientTile(patient: p, isDark: isDark))
                .toList(),
          const SizedBox(height: 24),

          // Available Slots Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('Your Available Slots', 'مواعيدك المتاحة'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Clear any editing state and navigate to availability tab
                  _manager.clearEditingIndex();
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('Go to Availability tab to add slots',
                            'انتقل إلى تبويب التوفر لإضافة مواعيد')),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(t('Add', 'إضافة')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00BCD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_manager.slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    t('No availability slots set', 'لم يتم تعيين مواعيد متاحة'),
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_manager.slots.length, (index) {
              final slot = _manager.slots[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_available,
                          color: Color(0xFF00BCD4), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(slot.date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 12,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatTime(slot.timeFrom)} - ${_formatTime(slot.timeTo)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editSlot(index),
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF00BCD4), size: 20),
                      tooltip: t('Edit', 'تعديل'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: () => _removeSlot(index),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      tooltip: t('Remove', 'حذف'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientData patient;
  final bool isDark;
  const _PatientTile({required this.patient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
            child: Text(
              patient.name.split(' ').map((e) => e[0]).take(2).join(),
              style: const TextStyle(
                  color: Color(0xFF00BCD4), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            patient.name,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: patient.progress,
                      minHeight: 8,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF8BC34A)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(patient.progress * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
          trailing: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white70 : Colors.black54),
          children: [
            const SizedBox(height: 6),
            if (patient.lastSession.isNotEmpty)
              _detailRow(Icons.event_note, t('Last Session', 'آخر جلسة'),
                  patient.lastSession, isDark),
            if (patient.lastSession.isNotEmpty) const SizedBox(height: 8),
            if (patient.notes.isNotEmpty)
              _detailRow(Icons.sticky_note_2_outlined, t('Notes', 'ملاحظات'),
                  patient.notes, isDark),
            if (patient.notes.isNotEmpty) const SizedBox(height: 8),
            if (patient.nextAppointment.isNotEmpty)
              _detailRow(Icons.schedule, t('Next', 'التالي'),
                  patient.nextAppointment, isDark),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t('Opening patient profile soon',
                            'سيتم فتح ملف المريض قريباً'))),
                  );
                },
                icon: const Icon(Icons.open_in_new, color: Color(0xFF00BCD4)),
                label: Text(t('View Profile', 'عرض الملف'),
                    style: const TextStyle(color: Color(0xFF00BCD4))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87)),
        Expanded(
          child: Text(value,
              style:
                  TextStyle(color: isDark ? Colors.white60 : Colors.black87)),
        ),
      ],
    );
  }
}
