import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'en';
  String _displayName = '';
  String _userRole = '';
  bool _isLoading = false;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get displayName => _displayName;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setDisplayName(String name) {
    _displayName = name.trim();
    notifyListeners();
  }

  /// Load user profile data from Firestore
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _displayName = '';
      _userRole = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Try to fetch from doctors collection first
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data()!;
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        _displayName = firstName.isNotEmpty && lastName.isNotEmpty
            ? '$firstName $lastName'
            : data['fullName'] as String? ?? 'Doctor';
        _userRole = 'doctor';
      } else {
        // Try patients collection
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .get();

        if (patientDoc.exists) {
          final data = patientDoc.data()!;
          final firstName = data['firstName'] as String? ?? '';
          final lastName = data['lastName'] as String? ?? '';
          _displayName = firstName.isNotEmpty && lastName.isNotEmpty
              ? '$firstName $lastName'
              : data['fullName'] as String? ?? 'Patient';
          _userRole = 'patient';
        } else {
          _displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
          _userRole = 'unknown';
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
      _userRole = 'unknown';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear user data on logout
  void clearUserData() {
    _displayName = '';
    _userRole = '';
    notifyListeners();
  }
}

/// Global instance used across the app for localization helper `t()`
final ThemeProvider globalThemeProvider = ThemeProvider();

String t(String enText, String arText) {
  return globalThemeProvider.language == 'ar' ? arText : enText;
}

Color colorWithOpacity(Color color, double opacity) => color.withOpacity(opacity);
