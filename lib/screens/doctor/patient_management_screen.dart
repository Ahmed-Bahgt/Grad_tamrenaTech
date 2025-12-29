// =============================================================================
// PATIENT MANAGEMENT SCREEN - PATIENT LIST & SEARCH
// =============================================================================
// Purpose: Manage doctor's patient list with two-tab interface
// Tab 1 - My Patients:
// - List of patients under doctor's care
// - View patient profiles (opens PatientProfileScreen)
// - Remove patients from care list
// - Progress tracking with visual progress bars
// Tab 2 - All Patients:
// - Search bar for finding patients by name/diagnosis
// - Add patients to doctor's care list
// - Browse all available patients in the system
// Data Source: PatientManager (shared with Home screen)
// =============================================================================

import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';
import '../../utils/patient_manager.dart';
import 'patient_profile_screen.dart';

/// Patient Management Screen with tabs for My Patients and All Patients
class PatientManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const PatientManagementScreen({super.key, this.onBack});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final PatientManager _patientManager = PatientManager();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addPatientToMyCare(PatientData patient) async {
    await _patientManager.addToMyCare(patient);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(t('Patient added to your care', 'تمت إضافة المريض لرعايتك')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removePatientFromMyCare(PatientData patient) async {
    await _patientManager.removeFromMyCare(patient);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            t('Patient removed from your care', 'تم إزالة المريض من رعايتك')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewPatientProfile(PatientData patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfileScreen(
          patient: patient,
          onUpdate: (updatedPatient) async {
            await _patientManager.updatePatient(updatedPatient);
          },
        ),
      ),
    );
  }

  List<PatientData> get _filteredAllPatients {
    if (_searchQuery.isEmpty) return _patientManager.allPatients;
    return _patientManager.allPatients
        .where((patient) =>
            patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            patient.diagnosis
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: t('Patients', 'المرضى'),
        onBack: widget.onBack,
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00BCD4),
              labelColor: const Color(0xFF00BCD4),
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              tabs: [
                Tab(text: t('My Patients', 'مرضاي')),
                Tab(text: t('All Patients', 'جميع المرضى')),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: ListenableBuilder(
              listenable: _patientManager,
              builder: (context, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // My Patients Tab
                    _buildMyPatientsTab(isDark),
                    // All Patients Tab
                    _buildAllPatientsTab(isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPatientsTab(bool isDark) {
    if (_patientManager.myPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              t('No patients under your care yet',
                  'لا يوجد مرضى تحت رعايتك بعد'),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('Add patients from "All Patients" tab',
                  'أضف مرضى من تبويب "جميع المرضى"'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _patientManager.myPatients.length,
      itemBuilder: (context, index) {
        final patient = _patientManager.myPatients[index];
        return _PatientCard(
          patient: patient,
          isDark: isDark,
          isMyPatient: true,
          onView: () => _viewPatientProfile(patient),
          onRemove: () => _removePatientFromMyCare(patient),
        );
      },
    );
  }

  Widget _buildAllPatientsTab(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: t('Search patients...', 'ابحث عن المرضى...'),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Patient List
        Expanded(
          child: _filteredAllPatients.isEmpty
              ? Center(
                  child: Text(
                    t('No patients found', 'لم يتم العثور على مرضى'),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredAllPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _filteredAllPatients[index];
                    return _PatientCard(
                      patient: patient,
                      isDark: isDark,
                      isMyPatient: false,
                      onAdd: () => _addPatientToMyCare(patient),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientData patient;
  final bool isDark;
  final bool isMyPatient;
  final VoidCallback? onView;
  final VoidCallback? onRemove;
  final VoidCallback? onAdd;

  const _PatientCard({
    required this.patient,
    required this.isDark,
    required this.isMyPatient,
    this.onView,
    this.onRemove,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                child: Text(
                  patient.name.split(' ').map((e) => e[0]).take(2).join(),
                  style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.diagnosis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isMyPatient) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('Progress', 'التقدم'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                Text(
                  '${(patient.progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8BC34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: patient.progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMyPatient) ...[
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: Text(t('View', 'عرض')),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00BCD4),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: Text(t('Remove', 'إزالة')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t('Add to My Care', 'إضافة لرعايتي')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
