import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';


/// Singleton to manage patient bookings across the app
class PatientBookingsManager {
  static final PatientBookingsManager _instance =
      PatientBookingsManager._internal();

  factory PatientBookingsManager() {
    return _instance;
  }

  PatientBookingsManager._internal() {
    _loadBookingsFromFirestore();
    // Ensure bookings are scoped to the signed-in patient only
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _bookings.clear();
        _notifyListeners();
      } else {
        _loadBookingsFromFirestore();
      }
    });
  }

  final List<PatientBooking> _bookings = [];
  final List<VoidCallback> _listeners = [];
  // ignore: unused_field
  StreamSubscription<User?>? _authSub;

  List<PatientBooking> get bookings => List.unmodifiable(_bookings);
  List<PatientBooking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings
        .where((booking) => booking.status != 'cancelled')
        .where((booking) => booking.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
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

  /// Optionally force a reload
  Future<void> refresh() async => _loadBookingsFromFirestore();

  /// Load bookings from Firestore for current patient
  Future<void> _loadBookingsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
          '[PatientBookingsManager] No user logged in, skipping booking load');
      return;
    }

    try {
      debugPrint(
          '[PatientBookingsManager] Loading bookings for patient: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('bookings')
          .get();

      _bookings.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateTime = (data['dateTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();

        _bookings.add(PatientBooking(
          id: doc.id,
          doctorId: data['doctorId'] as String? ?? '',
          doctorName: data['doctorName'] as String,
          specialty: data['specialty'] as String,
          dateTime: dateTime,
          endTime: endTime,
          doctorImage: data['doctorImage'] as String,
          status: data['status'] as String? ?? 'upcoming',
        ));
      }
      _bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      debugPrint(
          '[PatientBookingsManager] Loaded ${_bookings.length} bookings from Firestore');
      debugPrint(
          '[PatientBookingsManager] Upcoming bookings: ${upcomingBookings.length}');
      _notifyListeners();
    } catch (e) {
      debugPrint(
          '[PatientBookingsManager] Error loading bookings from Firestore: $e');
    }
  }

  /// Save booking to Firestore
  Future<void> _saveBookingToFirestore(PatientBooking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
          '[PatientBookingsManager] No user logged in, skipping booking save');
      return;
    }

    try {
      debugPrint(
          '[PatientBookingsManager] Saving booking to Firestore for patient: ${user.uid}');
      // Save to patient's bookings
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('bookings')
          .doc(booking.id)
          .set({
        'doctorId': booking.doctorId,
        'doctorName': booking.doctorName,
        'specialty': booking.specialty,
        'dateTime': booking.dateTime,
        'endTime': booking.endTime,
        'doctorImage': booking.doctorImage,
        'status': booking.status,
      });
      debugPrint(
          '[PatientBookingsManager] Booking saved to patient collection');

      // Also save to doctor's bookings collection for doctor-side persistence
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(booking.doctorId)
          .collection('bookings')
          .doc(booking.id)
          .set({
        'patientId': user.uid,
        'doctorId': booking.doctorId,
        'doctorName': booking.doctorName,
        'specialty': booking.specialty,
        'dateTime': booking.dateTime,
        'endTime': booking.endTime,
        'status': booking.status,
      });
      debugPrint('[PatientBookingsManager] Booking saved to doctor collection');
    } catch (e) {
      debugPrint(
          '[PatientBookingsManager] Error saving booking to Firestore: $e');
    }
  }

  void addBooking(PatientBooking booking) {
    debugPrint(
      'PatientBookingsManager: Adding booking ${booking.doctorName} at ${booking.dateTime}');
    _bookings.add(booking);
    debugPrint('PatientBookingsManager: Total bookings: ${_bookings.length}');
    debugPrint(
      'PatientBookingsManager: Upcoming bookings: ${upcomingBookings.length}');
    _saveBookingToFirestore(booking);
    _notifyListeners();
  }

  Future<void> cancelBooking(PatientBooking booking) async {
    _bookings.removeWhere((b) => b.id == booking.id);
    _notifyListeners();

    // Remove from patient bookings in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete from patient's bookings
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .collection('bookings')
            .doc(booking.id)
            .delete();

        // Also delete from doctor's bookings collection
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(booking.doctorId)
            .collection('bookings')
            .doc(booking.id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting booking from Firestore: $e');
      }
    }

    // Restore slot to doctor availability if doctorId is available and slot is in the future
    if (booking.doctorId.isNotEmpty &&
        booking.endTime.isAfter(DateTime.now())) {
      await _restoreSlotToDoctor(booking);
    }
  }

  Future<void> _restoreSlotToDoctor(PatientBooking booking) async {
    try {
      final slotDate = DateTime(
          booking.dateTime.year, booking.dateTime.month, booking.dateTime.day);
      final timeFrom = booking.dateTime;
      final timeTo = booking.endTime;

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(booking.doctorId)
          .collection('availability_slots')
          .add({
        'date': slotDate,
        'timeFromHour': timeFrom.hour,
        'timeFromMinute': timeFrom.minute,
        'timeToHour': timeTo.hour,
        'timeToMinute': timeTo.minute,
      });
    } catch (e) {
      debugPrint('Error restoring slot to doctor availability: $e');
    }
  }

  void clearBookings() {
    _bookings.clear();
    _notifyListeners();
  }
}

class PatientBooking {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final DateTime endTime;
  final String doctorImage;
  final String status; // upcoming, completed, cancelled

  PatientBooking({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.endTime,
    required this.doctorImage,
    this.status = 'upcoming',
  });
}
