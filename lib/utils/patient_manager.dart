import 'package:flutter/material.dart';

/// Singleton class to manage patients across screens
class PatientManager {
  static final PatientManager _instance = PatientManager._internal();

  factory PatientManager() {
    return _instance;
  }

  PatientManager._internal();

  final List<PatientData> _myPatients = [
    PatientData(
      id: '1',
      name: 'Ahmed Hassan',
      diagnosis: 'Knee Replacement Recovery',
      progress: 0.75,
      phone: '+20 123 456 7890',
      email: 'ahmed.hassan@email.com',
      assignedPlan: 'Squat',
      notes: 'Patient showing excellent progress. Continue current regimen.',
      lastSession: '2025-12-10',
      nextAppointment: 'Today 4:00 PM',
    ),
    PatientData(
      id: '2',
      name: 'Sara Mohamed',
      diagnosis: 'Shoulder Injury',
      progress: 0.50,
      phone: '+20 111 222 3333',
      email: 'sara.mohamed@email.com',
      assignedPlan: '',
      notes: 'Needs to focus on range of motion exercises.',
      lastSession: '2025-12-12',
      nextAppointment: 'Tomorrow 10:30 AM',
    ),
    PatientData(
      id: '3',
      name: 'Omar Ali',
      diagnosis: 'Post-Stroke Rehabilitation',
      progress: 0.30,
      phone: '+20 100 555 4444',
      email: 'omar.ali@email.com',
      assignedPlan: 'Squat',
      notes: 'Initial assessment completed. Starting basic mobility exercises.',
      lastSession: '2025-12-14',
      nextAppointment: '—',
    ),
  ];

  final List<PatientData> _allPatients = [
    PatientData(
      id: '4',
      name: 'Fatima Ibrahim',
      diagnosis: 'Back Pain',
      progress: 0.0,
      phone: '+20 122 333 5555',
      email: 'fatima.ibrahim@email.com',
      assignedPlan: '',
      notes: '',
      lastSession: '',
      nextAppointment: '',
    ),
    PatientData(
      id: '5',
      name: 'Mahmoud Sayed',
      diagnosis: 'Hip Replacement',
      progress: 0.0,
      phone: '+20 112 444 6666',
      email: 'mahmoud.sayed@email.com',
      assignedPlan: '',
      notes: '',
      lastSession: '',
      nextAppointment: '',
    ),
    PatientData(
      id: '6',
      name: 'Nour Hassan',
      diagnosis: 'Sports Injury',
      progress: 0.0,
      phone: '+20 101 777 8888',
      email: 'nour.hassan@email.com',
      assignedPlan: '',
      notes: '',
      lastSession: '',
      nextAppointment: '',
    ),
    PatientData(
      id: '7',
      name: 'Khaled Ahmed',
      diagnosis: 'Arthritis',
      progress: 0.0,
      phone: '+20 120 888 9999',
      email: 'khaled.ahmed@email.com',
      assignedPlan: '',
      notes: '',
      lastSession: '',
      nextAppointment: '',
    ),
  ];

  final List<VoidCallback> _listeners = [];

  List<PatientData> get myPatients => List.unmodifiable(_myPatients);
  List<PatientData> get allPatients => List.unmodifiable(_allPatients);

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

  void addToMyCare(PatientData patient) {
    _myPatients.add(patient);
    _allPatients.removeWhere((p) => p.id == patient.id);
    _notifyListeners();
  }

  void removeFromMyCare(PatientData patient) {
    _myPatients.removeWhere((p) => p.id == patient.id);
    _allPatients.add(patient);
    _notifyListeners();
  }

  void updatePatient(PatientData updatedPatient) {
    final index = _myPatients.indexWhere((p) => p.id == updatedPatient.id);
    if (index != -1) {
      _myPatients[index] = updatedPatient;
      _notifyListeners();
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
