import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/auth/doctor_registration_flow.dart';
import 'screens/auth/patient_registration_flow.dart';
import 'screens/auth/doctor_login.dart';
import 'screens/auth/patient_login.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/auth/success_screen.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/settings_screen.dart';

// --- ENUM FOR NAVIGATION ---
enum Screen {
  welcome,
  roleSelection,
  doctorRegister,
  patientRegister,
  doctorLogin,
  patientLogin,
  verification,
  successPatient,
  successDoctor,
  doctorDashboard,
  patientDashboard,
  settings,
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TamrenaApp());
}

// --- MAIN APPLICATION WIDGET ---
class TamrenaApp extends StatefulWidget {
  const TamrenaApp({super.key});

  @override
  State<TamrenaApp> createState() => _TamrenaAppState();
}

class _TamrenaAppState extends State<TamrenaApp> {
  final ThemeProvider _themeProvider = globalThemeProvider;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tamrena-Tech',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainScreen(themeProvider: _themeProvider),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00BCD4),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFBFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00E5FF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}

class MainScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const MainScreen({super.key, required this.themeProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Screen _currentScreen = Screen.welcome;
  Screen? _previousScreen;

  void navigateTo(Screen screen) {
    setState(() {
      if (screen == Screen.settings) {
        _previousScreen = _currentScreen;
      }
      _currentScreen = screen;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      widget.themeProvider.clearUserData();
      navigateTo(Screen.welcome);
    } catch (e) {
      debugPrint('Error during logout: $e');
      navigateTo(Screen.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case Screen.welcome:
        return WelcomeScreen(
          onCreateAccount: () => navigateTo(Screen.roleSelection),
          onLoginDoctor: () => navigateTo(Screen.doctorLogin),
          onLoginPatient: () => navigateTo(Screen.patientLogin),
        );
      case Screen.roleSelection:
        return RoleSelectionScreen(
          onSelectDoctor: () => navigateTo(Screen.doctorRegister),
          onSelectPatient: () => navigateTo(Screen.patientRegister),
          onBack: () => navigateTo(Screen.welcome),
        );
      case Screen.doctorRegister:
        return DoctorRegistrationFlowPage(
          onBack: () => navigateTo(Screen.roleSelection),
          onDoctorLogin: () => navigateTo(Screen.doctorLogin),
        );
      case Screen.patientRegister:
        return PatientRegistrationFlowPage(
          onBack: () => navigateTo(Screen.roleSelection),
          onSuccess: () => navigateTo(Screen.successPatient),
          onPatientLogin: () => navigateTo(Screen.patientLogin),
        );
      case Screen.doctorLogin:
        return DoctorLoginScreen(
          onBack: () => navigateTo(Screen.welcome),
          onRegister: () => navigateTo(Screen.doctorRegister),
          onLoginSuccess: () => navigateTo(Screen.doctorDashboard),
        );
      case Screen.patientLogin:
        return PatientLoginScreen(
          onBack: () => navigateTo(Screen.welcome),
          onRegister: () => navigateTo(Screen.patientRegister),
          onLoginSuccess: () => navigateTo(Screen.patientDashboard),
        );
      case Screen.verification:
        return VerificationScreen(
          onSubmit: () => navigateTo(Screen.successPatient),
          onBack: () => navigateTo(Screen.patientRegister),
        );
      case Screen.successPatient:
        return SuccessScreen(
          title: 'Registration Successful!',
          message:
              'Your account has been created successfully. Start your Recovery Journey.',
          buttonText: 'Start Recovery Journey',
          onReturn: () => navigateTo(Screen.patientLogin),
        );
      case Screen.successDoctor:
        return SuccessScreen(
          title: 'Registration Complete',
          message:
              'Thank you for registering. Your application and qualifications are now under review. We will notify you by email within 3-5 business days.',
          buttonText: 'Return to Login',
          onReturn: () => navigateTo(Screen.doctorLogin),
        );
      case Screen.doctorDashboard:
        return DoctorDashboard(
          onLogout: _handleLogout,
          themeProvider: widget.themeProvider,
          onBackToWelcome: _handleLogout,
        );
      case Screen.patientDashboard:
        return PatientDashboard(
          onLogout: _handleLogout,
          onSettings: () => navigateTo(Screen.settings),
          themeProvider: widget.themeProvider,
          onBackToWelcome: _handleLogout,
        );
      case Screen.settings:
        return SettingsScreen(
          themeProvider: widget.themeProvider,
          onBack: () => navigateTo(_previousScreen ?? Screen.doctorDashboard),
        );
    }
  }

  @override
  void initState() {
    super.initState();
  }
}
