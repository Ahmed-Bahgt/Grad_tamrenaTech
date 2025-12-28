import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/theme_provider.dart';
import '../../utils/responsive_utils.dart';

class PatientRegistrationFlowPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess; // navigate to successPatient
  final VoidCallback onPatientLogin;

  const PatientRegistrationFlowPage({
    super.key,
    required this.onBack,
    required this.onSuccess,
    required this.onPatientLogin,
  });

  @override
  State<PatientRegistrationFlowPage> createState() => _PatientRegistrationFlowPageState();
}

class _PatientRegistrationFlowPageState extends State<PatientRegistrationFlowPage> {
  final _authService = AuthService();

  final _primaryFormKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool _submitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    widget.onBack();
  }

  Future<void> _submit() async {
    if (!(_primaryFormKey.currentState?.validate() ?? false)) {
      _showSnack(t('Please complete primary info correctly.', 'يرجى إكمال المعلومات الأساسية بشكل صحيح.'));
      return;
    }

    setState(() => _submitting = true);
    try {
      // دالة التسجيل بالايميل
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      debugPrint('🔥 Firebase: User created with UID: ${userCredential.user!.uid}');

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      debugPrint('🔥 Firebase: Email verification sent');

      // Save to Firestore
      final data = RegistrationData(
        role: RegistrationRole.patient,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phoneNumber: '', // No phone number
      );

      await _authService.saveProfile(
        uid: userCredential.user!.uid,
        data: data,
        certificateUrl: null,
        qualifications: null,
      );

      debugPrint('🔥 Firebase: ✅ Registration complete');

      if (!mounted) return;
      _showSnack(t('Registration successful! Please verify your email.', 'تم التسجيل بنجاح! يرجى تأكيد بريدك الإلكتروني.'));
      // Sign out the user so they can log in
      await FirebaseAuth.instance.signOut();
      widget.onPatientLogin();
    } on FirebaseAuthException catch (e) {
      final msg = '[${e.code}] ${e.message ?? "Unknown Firebase error"}';
      _showSnack(msg);
      debugPrint('❌ Submit Error: $msg');
    } catch (e) {
      _showSnack(e.toString());
      debugPrint('❌ Submit Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Create Account', 'إنشاء حساب')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: _PatientPrimaryInfoScreen(
        formKey: _primaryFormKey,
        firstNameCtrl: _firstNameCtrl,
        lastNameCtrl: _lastNameCtrl,
        emailCtrl: _emailCtrl,
        passwordCtrl: _passwordCtrl,
        confirmPasswordCtrl: _confirmPasswordCtrl,
        onNext: _submit,
        submitting: _submitting,
        showPassword: _showPassword,
        showConfirmPassword: _showConfirmPassword,
        onTogglePassword: () => setState(() => _showPassword = !_showPassword),
        onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PatientPrimaryInfoScreen extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final VoidCallback onNext;
  final bool submitting;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const _PatientPrimaryInfoScreen({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.onNext,
    required this.submitting,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.padding(context, 16);
    final spacing = ResponsiveUtils.spacing(context, 8);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: firstNameCtrl,
              decoration: InputDecoration(labelText: t('First Name', 'الاسم الأول')),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('Required', 'مطلوب') : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: lastNameCtrl,
              decoration: InputDecoration(labelText: t('Last Name', 'اسم العائلة')),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('Required', 'مطلوب') : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t('Email', 'البريد الإلكتروني')),
              validator: (v) => (v == null || !v.contains('@')) ? t('Enter a valid email', 'أدخل بريدًا صالحًا') : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: passwordCtrl,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: t('Password', 'كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? t('Password must be 6+ chars', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل') : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: t('Confirm Password', 'تأكيد كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleConfirmPassword,
                ),
              ),
              validator: (v) => (v != passwordCtrl.text) ? t('Passwords do not match', 'كلمتا المرور غير متطابقتين') : null,
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context, 16)),
            SizedBox(
              height: ResponsiveUtils.buttonHeight(context),
              child: ElevatedButton(
                onPressed: submitting ? null : onNext,
                child: submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t('Submit', 'إرسال')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
