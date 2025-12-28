import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/theme_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_form_field.dart';

/// Patient Login Screen
class PatientLoginScreen extends StatefulWidget {
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
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack(t('Please enter email and password', 'الرجاء إدخال البريد وكلمة المرور'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user profile data
      await globalThemeProvider.loadUserProfile();

      if (!mounted) return;
      widget.onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = t('No account found with this email. Please register first.', 'لم يتم العثور على حساب. يرجى التسجيل أولاً.');
      } else if (e.code == 'wrong-password') {
        message = t('Incorrect password', 'كلمة مرور خاطئة');
      } else if (e.code == 'invalid-email') {
        message = t('Invalid email address', 'بريد إلكتروني غير صالح');
      } else if (e.code == 'invalid-credential') {
        message = t('Invalid email or password. Please check and try again.', 'بريد إلكتروني أو كلمة مرور خاطئة.');
      } else {
        message = e.message ?? t('Login failed', 'فشل تسجيل الدخول');
      }
      _showSnack(message);
    } catch (e) {
      _showSnack(t('An error occurred. Please try again.', 'حدث خطأ. يرجى المحاولة مرة أخرى.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: CustomAppBar(
        title: t('Patient Login', 'تسجيل دخول المريض'),
        onBack: widget.onBack,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.horizontalPadding(context).copyWith(
            top: ResponsiveUtils.verticalSpacing(context, 24),
            bottom: ResponsiveUtils.verticalSpacing(context, 24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.maxContentWidth(context),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: ResponsiveUtils.iconSize(context, 80),
                  color: const Color(0xFF8BC34A),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context, 30)),
                Text(
                  t('Welcome Patient', 'مرحباً مريض'),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 28),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 10)),
                Text(
                  t('Login to book appointments', 'تسجيل الدخول لحجز المواعيد'),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context, 40)),
                CustomFormField(
                  t('Email', 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailCtrl,
                ),
                CustomFormField(
                  t('Password', 'كلمة المرور'),
                  isPassword: true,
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  controller: _passwordCtrl,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context, 30)),
                SizedBox(
                  height: ResponsiveUtils.buttonHeight(context),
                  child: GradientButton(
                    text: _isLoading ? t('Logging in...', 'جاري تسجيل الدخول...') : t('Login', 'تسجيل الدخول'),
                    onPressed: _isLoading ? () {} : _handleLogin,
                    startColor: const Color(0xFF8BC34A),
                    endColor: const Color(0xFF689F38),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      t('Don\'t have an account? ', 'ليس لديك حساب؟ '),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onRegister,
                      child: Text(
                        t('Register', 'التسجيل'),
                        style: TextStyle(
                          color: const Color(0xFF8BC34A),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
