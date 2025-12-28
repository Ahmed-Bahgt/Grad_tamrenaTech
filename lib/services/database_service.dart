import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/squat_logic.dart';

/// Centralized Firestore operations for roles, slots, and workout logging.
class DatabaseService {
  DatabaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Save patient profile in `patients/{uid}`.
  Future<void> savePatientProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    await _db.collection('patients').doc(uid).set({
      'fullName': fullName,
      'phone': phone,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save doctor profile in `doctors/{uid}` with isVerified flag.
  Future<void> saveDoctorProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String email,
    String? degree,
    String? certificateUrl,
    String? additionalQualifications,
    String? firstName,
    String? lastName,
    List<Map<String, String>>? qualifications,
  }) async {
    await _db.collection('doctors').doc(uid).set({
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'degree': degree,
      'certificateUrl': certificateUrl,
      'additionalQualifications': additionalQualifications,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (qualifications != null) 'qualifications': qualifications,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Doctors add available slots to `available_slots`.
  Future<String> addAvailableSlot({
    required DateTime startTime,
    required DateTime endTime,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    final doc = await _db.collection('available_slots').add({
      'doctorId': user.uid,
      'startTime': Timestamp.fromDate(startTime.toUtc()),
      'endTime': Timestamp.fromDate(endTime.toUtc()),
      'note': note,
      'isBooked': false,
      'patientId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Patients book an available slot.
  Future<void> bookSlot({required String slotId}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    final ref = _db.collection('available_slots').doc(slotId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data();
      if (data == null) throw StateError('Slot not found');
      if ((data['isBooked'] as bool?) == true) throw StateError('Slot already booked');
      txn.update(ref, {
        'isBooked': true,
        'patientId': user.uid,
        'bookedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Log a workout session under `users/{uid}/workouts/{autoId}`.
  Future<void> logWorkout({
    required SquatResult result,
    int? targetSets,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // Skip if not signed in
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .add(result.toWorkoutMap(targetSets: targetSets));
  }
}
