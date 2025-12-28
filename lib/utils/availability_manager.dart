import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton class to manage availability slots across screens
class AvailabilityManager implements Listenable {
  static final AvailabilityManager _instance = AvailabilityManager._internal();

  factory AvailabilityManager() {
    return _instance;
  }

  AvailabilityManager._internal() {
    _loadSlotsFromFirestore();
  }

  final List<AvailabilitySlot> _slots = [];
  final List<VoidCallback> _listeners = [];
  int? _editingIndex;
  int _bookedCount = 0;

  List<AvailabilitySlot> get slots => List.unmodifiable(_slots);
  int? get editingIndex => _editingIndex;
  int get bookedCount => _bookedCount;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Load slots from Firestore for current doctor
  Future<void> _loadSlotsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .collection('availability_slots')
          .get();

      _slots.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final timeFromHour = data['timeFromHour'] as int;
        final timeFromMinute = data['timeFromMinute'] as int;
        final timeToHour = data['timeToHour'] as int;
        final timeToMinute = data['timeToMinute'] as int;

        _slots.add(AvailabilitySlot(
          date: date,
          timeFrom: TimeOfDay(hour: timeFromHour, minute: timeFromMinute),
          timeTo: TimeOfDay(hour: timeToHour, minute: timeToMinute),
        ));
      }
      _sortSlots();
      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading slots from Firestore: $e');
    }
  }

  /// Save slot to Firestore
  Future<void> _saveSlotsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid);

      // First, delete all existing slots
      final existingSlots = await docRef.collection('availability_slots').get();
      for (final doc in existingSlots.docs) {
        await doc.reference.delete();
      }

      // Then, add all current slots
      for (final slot in _slots) {
        await docRef.collection('availability_slots').add({
          'date': slot.date,
          'timeFromHour': slot.timeFrom.hour,
          'timeFromMinute': slot.timeFrom.minute,
          'timeToHour': slot.timeTo.hour,
          'timeToMinute': slot.timeTo.minute,
        });
      }
    } catch (e) {
      debugPrint('Error saving slots to Firestore: $e');
    }
  }

  /// Remove a slot after booking and increment booked counter
  void bookSlot(AvailabilitySlot slot) {
    _slots.removeWhere((s) => _isSameSlot(s, slot));
    _bookedCount++;
    _saveSlotsToFirestore();
    _notifyListeners();
  }

  void addSlot(AvailabilitySlot slot) {
    _slots.add(slot);
    _sortSlots();
    _saveSlotsToFirestore();
    _notifyListeners();
  }

  void updateSlot(int index, AvailabilitySlot slot) {
    if (index >= 0 && index < _slots.length) {
      _slots[index] = slot;
      _sortSlots();
      _saveSlotsToFirestore();
      _notifyListeners();
    }
  }

  void removeSlot(int index) {
    if (index >= 0 && index < _slots.length) {
      _slots.removeAt(index);
      _saveSlotsToFirestore();
      _notifyListeners();
    }
  }

  void setEditingIndex(int index) {
    _editingIndex = index;
    _notifyListeners();
  }

  void clearEditingIndex() {
    _editingIndex = null;
    _notifyListeners();
  }

  void _sortSlots() {
    _slots.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.timeFrom.hour * 60 +
          a.timeFrom.minute -
          (b.timeFrom.hour * 60 + b.timeFrom.minute);
    });
  }

  bool _isSameSlot(AvailabilitySlot a, AvailabilitySlot b) {
    return a.date.year == b.date.year &&
        a.date.month == b.date.month &&
        a.date.day == b.date.day &&
        a.timeFrom.hour == b.timeFrom.hour &&
        a.timeFrom.minute == b.timeFrom.minute &&
        a.timeTo.hour == b.timeTo.hour &&
        a.timeTo.minute == b.timeTo.minute;
  }
}

class AvailabilitySlot {
  final DateTime date;
  final TimeOfDay timeFrom;
  final TimeOfDay timeTo;

  AvailabilitySlot({
    required this.date,
    required this.timeFrom,
    required this.timeTo,
  });
}
