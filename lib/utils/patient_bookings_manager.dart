import 'package:flutter/material.dart';

/// Singleton to manage patient bookings across the app
class PatientBookingsManager {
  static final PatientBookingsManager _instance =
      PatientBookingsManager._internal();

  factory PatientBookingsManager() {
    return _instance;
  }

  PatientBookingsManager._internal() {
    _initializeTestBooking();
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

  void addBooking(PatientBooking booking) {
    _bookings.add(booking);
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

  void _initializeTestBooking() {
    // Add a test booking for today at 2:00 PM
    final now = DateTime.now();
    final todayBooking = DateTime(now.year, now.month, now.day, 14, 0);

    if (todayBooking.isAfter(now)) {
      _bookings.add(PatientBooking(
        id: 'booking_1',
        doctorName: 'Dr. Sarah Ali',
        specialty: 'Sports Medicine',
        dateTime: todayBooking,
        endTime: DateTime(now.year, now.month, now.day, 14, 30),
        doctorImage: '👩‍⚕️',
      ));
    }

    // Add a test booking for tomorrow at 10:00 AM
    final tomorrow = now.add(const Duration(days: 1));
    _bookings.add(PatientBooking(
      id: 'booking_2',
      doctorName: 'Dr. Ahmed Hassan',
      specialty: 'Physiotherapy Specialist',
      dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
      endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 30),
      doctorImage: '👨‍⚕️',
    ));

    _bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
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
