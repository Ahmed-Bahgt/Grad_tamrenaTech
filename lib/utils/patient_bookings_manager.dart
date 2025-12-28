import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton to manage patient bookings across the app
class PatientBookingsManager {
  static final PatientBookingsManager _instance =
      PatientBookingsManager._internal();

  factory PatientBookingsManager() {
    return _instance;
  }

  PatientBookingsManager._internal() {
    _loadBookingsFromFirestore();
  }

  final List<PatientBooking> _bookings = [];
  final List<VoidCallback> _listeners = [];

  List<PatientBooking> get bookings => List.unmodifiable(_bookings);
  List<PatientBooking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings.where((booking) => booking.dateTime.isAfter(now)).toList()
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

  /// Load bookings from Firestore for current patient
  Future<void> _loadBookingsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
          doctorName: data['doctorName'] as String,
          specialty: data['specialty'] as String,
          dateTime: dateTime,
          endTime: endTime,
          doctorImage: data['doctorImage'] as String,
          status: data['status'] as String? ?? 'upcoming',
        ));
      }
      _bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookings from Firestore: $e');
    }
  }

  /// Save booking to Firestore
  Future<void> _saveBookingToFirestore(PatientBooking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('bookings')
          .doc(booking.id)
          .set({
        'doctorName': booking.doctorName,
        'specialty': booking.specialty,
        'dateTime': booking.dateTime,
        'endTime': booking.endTime,
        'doctorImage': booking.doctorImage,
        'status': booking.status,
      });
    } catch (e) {
      debugPrint('Error saving booking to Firestore: $e');
    }
  }

  void addBooking(PatientBooking booking) {
    debugPrint('PatientBookingsManager: Adding booking ${booking.doctorName} at ${booking.dateTime}');
    _bookings.add(booking);
    debugPrint('PatientBookingsManager: Total bookings: ${_bookings.length}');
    debugPrint('PatientBookingsManager: Upcoming bookings: ${upcomingBookings.length}');
    _saveBookingToFirestore(booking);
    _notifyListeners();
  }

  void removeBooking(int index) {
    if (index >= 0 && index < _bookings.length) {
      _bookings.removeAt(index);
      _notifyListeners();
    }
  }

  void removeBookingById(String id) {
    _bookings.removeWhere((booking) => booking.id == id);
    _notifyListeners();
  }

  void clearBookings() {
    _bookings.clear();
    _notifyListeners();
  }
}

class PatientBooking {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final DateTime endTime;
  final String doctorImage;
  final String status; // upcoming, completed, cancelled

  PatientBooking({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.endTime,
    required this.doctorImage,
    this.status = 'upcoming',
  });
}
