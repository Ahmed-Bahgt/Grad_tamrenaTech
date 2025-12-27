import 'package:flutter/material.dart';
import '../../utils/theme_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_form_field.dart';

/// Patient Login Screen
class PatientLoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const PatientLoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onRegister,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: CustomAppBar(
        title: t('Patient Login', 'تسجيل دخول المريض'),
        onBack: onBack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.person_rounded,
              size: 80,
              color: const Color(0xFF8BC34A),
            ),
            const SizedBox(height: 30),
            Text(
              t('Welcome Patient', 'مرحباً مريض'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('Login to book appointments', 'تسجيل الدخول لحجز المواعيد'),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            CustomFormField(
              t('Email', 'البريد الإلكتروني'),
              keyboardType: TextInputType.emailAddress,
            ),
            CustomFormField(
              t('Password', 'كلمة المرور'),
              isPassword: true,
            ),
            const SizedBox(height: 30),
            GradientButton(
              text: t('Login', 'تسجيل الدخول'),
              onPressed: onLoginSuccess,
              startColor: const Color(0xFF8BC34A),
              endColor: const Color(0xFF689F38),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t('Don\'t have an account? ', 'ليس لديك حساب؟ '),
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
                GestureDetector(
                  onTap: onRegister,
                  child: Text(
                    t('Register', 'التسجيل'),
                    style: const TextStyle(
                      color: Color(0xFF8BC34A),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
