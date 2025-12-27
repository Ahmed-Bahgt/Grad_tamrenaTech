// =============================================================================
// PATIENT PROFILE SCREEN - DETAILED PATIENT VIEW & EDITING
// =============================================================================
// Purpose: View and edit comprehensive patient information
// Displays:
// - Patient basic info: Name, diagnosis, phone, email
// - Progress overview with visual progress bar
// - Last session, next appointment, doctor's notes
// Editable Fields:
// - Assigned Treatment Plan (dropdown with options: None, Squat, More coming soon...)
// - Doctor's Notes (multi-line text area)
// Actions:
// - Submit button to save all changes
// - Changes sync back to PatientManager (updates everywhere)
// =============================================================================

import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';
import '../../utils/patient_manager.dart';

/// Patient Profile Screen - View and edit patient details
class PatientProfileScreen extends StatefulWidget {
  final PatientData patient;
  final Function(PatientData) onUpdate;

  const PatientProfileScreen({
    super.key,
    required this.patient,
    required this.onUpdate,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late TextEditingController _notesController;
  late String _selectedPlan;

  final List<String> _planOptions = [
    '',
    'Squat',
    'More plans coming soon...',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.patient.notes);
    _selectedPlan = widget.patient.assignedPlan;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitChanges() {
    final updatedPatient = widget.patient.copyWith(
      assignedPlan: _selectedPlan,
      notes: _notesController.text,
    );

    widget.onUpdate(updatedPatient);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('Patient details updated', 'تم تحديث بيانات المريض')),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.patient.name,
        onBack: () => Navigator.pop(context),
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient Avatar and Basic Info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  child: Text(
                    widget.patient.name
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.patient.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Section
          _buildSectionCard(
            isDark: isDark,
            title: t('Progress Overview', 'نظرة عامة على التقدم'),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('Overall Progress', 'التقدم الإجمالي'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Text(
                      '${(widget.patient.progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8BC34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.patient.progress,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Patient Details Section
          _buildSectionCard(
            isDark: isDark,
            title: t('Patient Details', 'تفاصيل المريض'),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.medical_services,
                  label: t('Diagnosis', 'التشخيص'),
                  value: widget.patient.diagnosis,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.phone,
                  label: t('Phone', 'الهاتف'),
                  value: widget.patient.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.email,
                  label: t('Email', 'البريد الإلكتروني'),
                  value: widget.patient.email,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assign Plan Section
          _buildSectionCard(
            isDark: isDark,
            title: t('Assign Treatment Plan', 'تعيين خطة العلاج'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Select a plan for this patient', 'اختر خطة لهذا المريض'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlan.isEmpty ? null : _selectedPlan,
                  decoration: InputDecoration(
                    hintText: t('Select a plan...', 'اختر خطة...'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                  ),
                  dropdownColor:
                      isDark ? const Color(0xFF161B22) : Colors.white,
                  items: _planOptions.map((plan) {
                    return DropdownMenuItem(
                      value: plan.isEmpty ? null : plan,
                      child: Text(
                        plan.isEmpty ? t('None', 'لا شيء') : plan,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlan = value ?? '';
                    });
                  },
                ),
                if (_selectedPlan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center,
                            color: Color(0xFF00BCD4), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('Current plan: ', 'الخطة الحالية: ') +
                                _selectedPlan,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notes Section
          _buildSectionCard(
            isDark: isDark,
            title: t('Doctor\'s Notes', 'ملاحظات الطبيب'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Add notes about this patient',
                      'أضف ملاحظات حول هذا المريض'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        t('Enter your notes here...', 'أدخل ملاحظاتك هنا...'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitChanges,
              icon: const Icon(Icons.save),
              label: Text(
                t('Submit Changes', 'حفظ التغييرات'),
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
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
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
