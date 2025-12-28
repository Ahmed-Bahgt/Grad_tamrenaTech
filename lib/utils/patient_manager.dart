import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton class to manage patients across screens
class PatientManager extends ChangeNotifier {
  static final PatientManager _instance = PatientManager._internal();

  factory PatientManager() {
    return _instance;
  }

  PatientManager._internal() {
    _loadPatientsFromFirestore();
  }

  // Patients assigned to current doctor
  final List<PatientData> _myPatients = [];
  // All patients with accounts (available to add to care)
  final List<PatientData> _allPatients = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Load both assigned and all available patients from Firestore
  Future<void> _loadPatientsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _myPatients.clear();
      _allPatients.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Load all patients first
      final allSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .get();

      _allPatients.clear();
      _myPatients.clear();

      final myPatientIds = <String>{};

      // Process all patients and separate into assigned/unassigned
      for (final doc in allSnapshot.docs) {
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final patientName = firstName.isNotEmpty && lastName.isNotEmpty
            ? '$firstName $lastName'
            : data['fullName'] as String? ?? 'Patient';

        final patient = PatientData(
          id: doc.id,
          name: patientName,
          diagnosis: data['diagnosis'] as String? ?? 'Rehabilitation',
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
          phone: data['phone'] as String? ?? '',
          email: data['email'] as String? ?? '',
          assignedPlan: data['assignedPlan'] as String? ?? '',
          notes: data['notes'] as String? ?? '',
          lastSession: data['lastSession'] as String? ?? '',
          nextAppointment: data['nextAppointment'] as String? ?? '',
        );

        // Add to all patients list
        _allPatients.add(patient);

        // Check if assigned to current doctor
        final assignedDoctorId = data['assignedDoctorId'] as String? ?? '';
        if (assignedDoctorId == user.uid) {
          _myPatients.add(patient);
          myPatientIds.add(patient.id);
        }
      }

      // Remove my patients from all patients list (so they show only in "All Patients" as unassigned)
      // Actually, keep them in all patients list but sorted differently by UI if needed
    } catch (e) {
      debugPrint('Error loading patients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload patients from Firestore
  Future<void> refreshPatients() async {
    await _loadPatientsFromFirestore();
  }

  List<PatientData> get myPatients => List.unmodifiable(_myPatients);
  List<PatientData> get allPatients => List.unmodifiable(_allPatients);

  /// Add patient to current doctor's care (save to Firestore)
  Future<void> addToMyCare(PatientData patient) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update patient document with current doctor's ID
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patient.id)
          .update({'assignedDoctorId': user.uid});

      // Update local lists
      if (!_myPatients.any((p) => p.id == patient.id)) {
        _myPatients.add(patient);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding patient to care: $e');
    }
  }

  /// Remove patient from current doctor's care (save to Firestore)
  Future<void> removeFromMyCare(PatientData patient) async {
    try {
      // Clear assignedDoctorId in Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patient.id)
          .update({'assignedDoctorId': FieldValue.delete()});

      // Update local lists
      _myPatients.removeWhere((p) => p.id == patient.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing patient from care: $e');
    }
  }

  void updatePatient(PatientData updatedPatient) {
    final myIndex = _myPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (myIndex != -1) {
      _myPatients[myIndex] = updatedPatient;
    }
    
    final allIndex = _allPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (allIndex != -1) {
      _allPatients[allIndex] = updatedPatient;
    }
    notifyListeners();
  }
}

class PatientData {
  final String id;
  final String name;
  final String diagnosis;
  final double progress;
  final String phone;
  final String email;
  final String assignedPlan;
  final String notes;
  final String lastSession;
  final String nextAppointment;

  PatientData({
    required this.id,
    required this.name,
    required this.diagnosis,
    required this.progress,
    required this.phone,
    required this.email,
    required this.assignedPlan,
    required this.notes,
    required this.lastSession,
    required this.nextAppointment,
  });

  PatientData copyWith({
    String? id,
    String? name,
    String? diagnosis,
    double? progress,
    String? phone,
    String? email,
    String? assignedPlan,
    String? notes,
    String? lastSession,
    String? nextAppointment,
  }) {
    return PatientData(
      id: id ?? this.id,
      name: name ?? this.name,
      diagnosis: diagnosis ?? this.diagnosis,
      progress: progress ?? this.progress,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedPlan: assignedPlan ?? this.assignedPlan,
      notes: notes ?? this.notes,
      lastSession: lastSession ?? this.lastSession,
      nextAppointment: nextAppointment ?? this.nextAppointment,
    );
  }
}
