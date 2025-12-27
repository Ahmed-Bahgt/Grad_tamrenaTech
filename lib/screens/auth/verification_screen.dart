import 'package:flutter/material.dart';
import '../../utils/theme_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_form_field.dart';

/// Verification Screen - SMS/Email Verification
class VerificationScreen extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const VerificationScreen({
    super.key,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: CustomAppBar(
        title: t('Verification', 'التحقق'),
        onBack: onBack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.sms_rounded,
              size: 80,
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(height: 30),
            Text(
              t('Enter Verification Code', 'أدخل رمز التحقق'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('We sent a code to your phone number', 'أرسلنا رمزاً إلى رقم هاتفك'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            CustomFormField(
              t('Verification Code', 'رمز التحقق'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            GradientButton(
              text: t('Submit', 'إرسال'),
              onPressed: onSubmit,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('Code resent successfully', 'تم إعادة إرسال الرمز بنجاح')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                t('Resend Code', 'إعادة إرسال الرمز'),
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
