import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

/// Placeholder for doctor slot listing
class DoctorSlotsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const DoctorSlotsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(title: 'Doctor Slots', onBack: onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: Center(
        child: Text(
          'Slots',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
