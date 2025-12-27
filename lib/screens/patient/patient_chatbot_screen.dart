import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

/// Patient Chatbot Screen placeholder
class PatientChatbotScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const PatientChatbotScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(title: 'Chatbot', onBack: onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: Center(
        child: Text(
          'Chatbot',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
