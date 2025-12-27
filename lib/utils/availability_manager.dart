import 'package:flutter/material.dart';

/// Singleton class to manage availability slots across screens
class AvailabilityManager {
  static final AvailabilityManager _instance = AvailabilityManager._internal();

  factory AvailabilityManager() {
    return _instance;
  }

  AvailabilityManager._internal() {
    _initializeTestSlots();
  }

  final List<AvailabilitySlot> _slots = [];
  final List<VoidCallback> _listeners = [];
  int? _editingIndex;

  List<AvailabilitySlot> get slots => List.unmodifiable(_slots);
  int? get editingIndex => _editingIndex;

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

  void addSlot(AvailabilitySlot slot) {
    _slots.add(slot);
    _sortSlots();
    _notifyListeners();
  }

  void updateSlot(int index, AvailabilitySlot slot) {
    if (index >= 0 && index < _slots.length) {
      _slots[index] = slot;
      _sortSlots();
      _notifyListeners();
    }
  }

  void removeSlot(int index) {
    if (index >= 0 && index < _slots.length) {
      _slots.removeAt(index);
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

  void _initializeTestSlots() {
    final now = DateTime.now();
    
    // Today's slots
    _slots.add(AvailabilitySlot(
      date: now,
      timeFrom: const TimeOfDay(hour: 9, minute: 0),
      timeTo: const TimeOfDay(hour: 9, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: now,
      timeFrom: const TimeOfDay(hour: 10, minute: 0),
      timeTo: const TimeOfDay(hour: 10, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: now,
      timeFrom: const TimeOfDay(hour: 14, minute: 0),
      timeTo: const TimeOfDay(hour: 14, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: now,
      timeFrom: const TimeOfDay(hour: 15, minute: 30),
      timeTo: const TimeOfDay(hour: 16, minute: 0),
    ));

    // Tomorrow's slots
    final tomorrow = now.add(const Duration(days: 1));
    _slots.add(AvailabilitySlot(
      date: tomorrow,
      timeFrom: const TimeOfDay(hour: 8, minute: 30),
      timeTo: const TimeOfDay(hour: 9, minute: 0),
    ));
    _slots.add(AvailabilitySlot(
      date: tomorrow,
      timeFrom: const TimeOfDay(hour: 11, minute: 0),
      timeTo: const TimeOfDay(hour: 11, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: tomorrow,
      timeFrom: const TimeOfDay(hour: 13, minute: 0),
      timeTo: const TimeOfDay(hour: 13, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: tomorrow,
      timeFrom: const TimeOfDay(hour: 16, minute: 0),
      timeTo: const TimeOfDay(hour: 16, minute: 30),
    ));

    // Day after tomorrow
    final dayAfterTomorrow = now.add(const Duration(days: 2));
    _slots.add(AvailabilitySlot(
      date: dayAfterTomorrow,
      timeFrom: const TimeOfDay(hour: 9, minute: 30),
      timeTo: const TimeOfDay(hour: 10, minute: 0),
    ));
    _slots.add(AvailabilitySlot(
      date: dayAfterTomorrow,
      timeFrom: const TimeOfDay(hour: 10, minute: 30),
      timeTo: const TimeOfDay(hour: 11, minute: 0),
    ));
    _slots.add(AvailabilitySlot(
      date: dayAfterTomorrow,
      timeFrom: const TimeOfDay(hour: 14, minute: 30),
      timeTo: const TimeOfDay(hour: 15, minute: 0),
    ));

    // 4 days from now
    final in4Days = now.add(const Duration(days: 4));
    _slots.add(AvailabilitySlot(
      date: in4Days,
      timeFrom: const TimeOfDay(hour: 9, minute: 0),
      timeTo: const TimeOfDay(hour: 9, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: in4Days,
      timeFrom: const TimeOfDay(hour: 13, minute: 0),
      timeTo: const TimeOfDay(hour: 13, minute: 30),
    ));
    _slots.add(AvailabilitySlot(
      date: in4Days,
      timeFrom: const TimeOfDay(hour: 15, minute: 0),
      timeTo: const TimeOfDay(hour: 15, minute: 30),
    ));

    _sortSlots();
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
