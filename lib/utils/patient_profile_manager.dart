import 'package:flutter/material.dart';

/// Singleton to manage patient profile data
class PatientProfileManager {
  static final PatientProfileManager _instance = PatientProfileManager._internal();

  factory PatientProfileManager() {
    return _instance;
  }

  PatientProfileManager._internal() {
    _patientName = 'Ahmed';
  }

  late String _patientName;
  final List<VoidCallback> _listeners = [];

  String get patientName => _patientName;

  void setPatientName(String name) {
    _patientName = name;
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
}
