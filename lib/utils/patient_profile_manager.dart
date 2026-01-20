import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton to manage patient profile data
class PatientProfileManager {
  static final PatientProfileManager _instance = PatientProfileManager._internal();

  factory PatientProfileManager() {
    return _instance;
  }

  PatientProfileManager._internal() {
    _patientName = 'Ahmed';
    _patientNotes = '';
    _exerciseType = '';
    _exerciseSets = 0;
    _exerciseReps = 0;
    _exerciseMode = '';
  }

  late String _patientName;
  late String _patientNotes;
  late String _exerciseType;
  late int _exerciseSets;
  late int _exerciseReps;
  late String _exerciseMode;
  final List<VoidCallback> _listeners = [];

  String get patientName => _patientName;
  String get patientNotes => _patientNotes;
  String get exerciseType => _exerciseType;
  int get exerciseSets => _exerciseSets;
  int get exerciseReps => _exerciseReps;
  String get exerciseMode => _exerciseMode;

  void setPatientName(String name) {
    _patientName = name;
    _notifyListeners();
  }

  void setPatientNotes(String notes) {
    _patientNotes = notes;
    _notifyListeners();
  }

  void setExercisePlan({required String type, required int sets, required int reps}) {
    _exerciseType = type;
    _exerciseSets = sets;
    _exerciseReps = reps;
    _notifyListeners();
  }

  void setExerciseMode(String mode) {
    _exerciseMode = mode;
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Load patient profile data from Firebase, including notes
  Future<void> loadPatientProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[PatientProfileManager] No user logged in, skipping profile load');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final fullName = firstName.isNotEmpty && lastName.isNotEmpty
            ? '$firstName $lastName'
            : data['fullName'] as String? ?? 'Patient';
        
        _patientName = fullName;
        _patientNotes = data['notes'] as String? ?? '';
        _exerciseType = data['assignedPlan'] as String? ?? '';
        _exerciseSets = (data['sets'] as num?)?.toInt() ?? 0;
        _exerciseReps = (data['reps'] as num?)?.toInt() ?? 0;
        _exerciseMode = data['assignedMode'] as String? ?? '';
        
        debugPrint('[PatientProfileManager] Loaded profile: $_patientName, Notes: ${_patientNotes.isEmpty ? "empty" : "present"}');
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('[PatientProfileManager] Error loading patient profile: $e');
    }
  }
}
