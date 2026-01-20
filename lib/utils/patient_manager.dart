import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Singleton class to manage patients across screens
class PatientManager extends ChangeNotifier {
  static final PatientManager _instance = PatientManager._internal();

  factory PatientManager() {
    return _instance;
  }

  PatientManager._internal() {
    _loadPatientsFromFirestore();
    // Ensure patient lists are scoped to the signed-in doctor
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _myPatients.clear();
        _allPatients.clear();
        notifyListeners();
      } else {
        _loadPatientsFromFirestore();
      }
    });
  }

  // Patients assigned to current doctor
  final List<PatientData> _myPatients = [];
  // All patients with accounts (available to add to care)
  final List<PatientData> _allPatients = [];
  bool _isLoading = false;
  // ignore: unused_field
  StreamSubscription<User?>? _authSub;

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
      final allSnapshot =
          await FirebaseFirestore.instance.collection('patients').get();

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
          assignedMode: data['assignedMode'] as String? ?? '',
          notes: data['notes'] as String? ?? '',
          lastSession: data['lastSession'] as String? ?? '',
          nextAppointment: data['nextAppointment'] as String? ?? '',
          sessions: (data['sessions'] as num?)?.toInt() ?? 0,
          completedSessions: (data['completedSessions'] as num?)?.toInt() ?? 0,
          sets: (data['sets'] as num?)?.toInt() ?? 3,
          reps: (data['reps'] as num?)?.toInt() ?? 10,
        );

        // Check if assigned to current doctor or anyone else
        final assignedDoctorId = data['assignedDoctorId'] as String? ?? '';

        if (assignedDoctorId == user.uid) {
          // Patient assigned to current doctor - add to myPatients
          _myPatients.add(patient);
          myPatientIds.add(patient.id);
        } else if (assignedDoctorId.isEmpty) {
          // Patient unassigned - add to allPatients for discovery
          _allPatients.add(patient);
        }
        // If assigned to another doctor, don't show in either list (hidden from this doctor)
      }
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

  /// Ensure all data is persisted to Firestore
  Future<void> syncAllData() async {
    await _loadPatientsFromFirestore();
    debugPrint('[PatientManager] Data synced with Firestore');
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
      // Remove from allPatients since it's now assigned
      _allPatients.removeWhere((p) => p.id == patient.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding patient to care: $e');
    }
  }

  /// Remove patient from current doctor's care (save to Firestore)
  Future<void> removeFromMyCare(PatientData patient) async {
    try {
      // Set assignedDoctorId to empty string in Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patient.id)
          .update({'assignedDoctorId': ''});

      // Update local lists
      _myPatients.removeWhere((p) => p.id == patient.id);
      // Add back to allPatients since it's now unassigned
      if (!_allPatients.any((p) => p.id == patient.id)) {
        _allPatients.add(patient);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing patient from care: $e');
    }
  }

  /// Auto-add patient to doctor's care when they book an appointment
  Future<void> autoAddPatientOnBooking(
      String patientId, String patientName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if already in myPatients
      if (_myPatients.any((p) => p.id == patientId)) return;

      // Update Firestore: set assignedDoctorId
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .update({'assignedDoctorId': user.uid});

      // Find in allPatients and add to myPatients
      final patient = _allPatients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => PatientData(
          id: patientId,
          name: patientName,
          diagnosis: 'Rehabilitation',
          progress: 0.0,
          phone: '',
          email: '',
          assignedPlan: '',
          assignedMode: '',
          notes: '',
          lastSession: '',
          nextAppointment: '',
          completedSessions: 0,
        ),
      );

      if (!_myPatients.any((p) => p.id == patientId)) {
        _myPatients.add(patient);
      }
      // Remove from allPatients since it's now assigned
      _allPatients.removeWhere((p) => p.id == patientId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-adding patient on booking: $e');
    }
  }

  /// Static method to assign a patient to a specific doctor (called from patient's booking)
  static Future<void> assignPatientToDoctor(
      String patientId, String doctorId, String patientName) async {
    try {
      // First, check if patient already has a doctor
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        debugPrint('[PatientManager] Patient $patientId not found');
        return;
      }

      final currentDoctorId =
          patientDoc.data()?['assignedDoctorId'] as String? ?? '';

      // Only assign if not already assigned to this doctor
      if (currentDoctorId != doctorId) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .update({'assignedDoctorId': doctorId});

        debugPrint(
            '[PatientManager] Patient $patientId assigned to doctor $doctorId');
      } else {
        debugPrint(
            '[PatientManager] Patient $patientId already assigned to doctor $doctorId');
      }
    } catch (e) {
      debugPrint('[PatientManager] Error assigning patient to doctor: $e');
    }
  }

  Future<void> updatePatient(PatientData updatedPatient) async {
    // Update in local lists
    final myIndex = _myPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (myIndex != -1) {
      _myPatients[myIndex] = updatedPatient;
    }

    final allIndex = _allPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (allIndex != -1) {
      _allPatients[allIndex] = updatedPatient;
    }
    notifyListeners();

    // Save to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(updatedPatient.id)
          .update({
        'assignedPlan': updatedPatient.assignedPlan,
        'assignedMode': updatedPatient.assignedMode,
        'notes': updatedPatient.notes,
        'sessions': updatedPatient.sessions,
        'completedSessions': updatedPatient.completedSessions,
        'sets': updatedPatient.sets,
        'reps': updatedPatient.reps,
        'progress': updatedPatient.calculatedProgress,
        'lastSession': updatedPatient.lastSession,
        'nextAppointment': updatedPatient.nextAppointment,
      });
      debugPrint('Patient ${updatedPatient.id} updated in Firestore');
    } catch (e) {
      debugPrint('Error updating patient in Firestore: $e');
    }
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
  final String assignedMode;
  final String notes;
  final String lastSession;
  final String nextAppointment;
  final int sessions; // Total sessions set by doctor
  final int completedSessions; // Sessions completed by patient
  final int sets;
  final int reps;

  PatientData({
    required this.id,
    required this.name,
    required this.diagnosis,
    required this.progress,
    required this.phone,
    required this.email,
    required this.assignedPlan,
    required this.assignedMode,
    required this.notes,
    required this.lastSession,
    required this.nextAppointment,
    this.sessions = 0,
    this.completedSessions = 0,
    this.sets = 3,
    this.reps = 10,
  });

  /// Calculate progress based on completed sessions vs total sessions
  double get calculatedProgress {
    if (sessions <= 0) return 0.0;
    return ((completedSessions / sessions) * 100).clamp(0.0, 100.0);
  }

  PatientData copyWith({
    String? id,
    String? name,
    String? diagnosis,
    double? progress,
    String? phone,
    String? email,
    String? assignedPlan,
    String? assignedMode,
    String? notes,
    String? lastSession,
    String? nextAppointment,
    int? sessions,
    int? sets,
    int? reps,
  }) {
    return PatientData(
      id: id ?? this.id,
      name: name ?? this.name,
      diagnosis: diagnosis ?? this.diagnosis,
      progress: progress ?? this.progress,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedPlan: assignedPlan ?? this.assignedPlan,
      assignedMode: assignedMode ?? this.assignedMode,
      notes: notes ?? this.notes,
      lastSession: lastSession ?? this.lastSession,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      sessions: sessions ?? this.sessions,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }
}
