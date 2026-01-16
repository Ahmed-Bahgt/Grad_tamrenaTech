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
  }

  late String _patientName;
  late String _patientNotes;
  final List<VoidCallback> _listeners = [];

  String get patientName => _patientName;
  String get patientNotes => _patientNotes;

  void setPatientName(String name) {
    _patientName = name;
    _notifyListeners();
  }

  void setPatientNotes(String notes) {
    _patientNotes = notes;
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
        
        debugPrint('[PatientProfileManager] Loaded profile: $_patientName, Notes: ${_patientNotes.isEmpty ? "empty" : "present"}');
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('[PatientProfileManager] Error loading patient profile: $e');
    }
  }
}
