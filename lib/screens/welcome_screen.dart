import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/gradient_button.dart';

/// Welcome Screen - App entry point with branding and action buttons
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLoginDoctor;
  final VoidCallback onLoginPatient;

  const WelcomeScreen({
    super.key,
    required this.onCreateAccount,
    required this.onLoginDoctor,
    required this.onLoginPatient,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to theme provider changes to rebuild the screen
    globalThemeProvider.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    globalThemeProvider.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Background_app.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.horizontalPadding(context).copyWith(
                top: ResponsiveUtils.verticalSpacing(context, 32),
                bottom: ResponsiveUtils.verticalSpacing(context, 32),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.maxContentWidth(context),
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Logo (Replaced with provided runner logo)
                        Image.asset(
                          'assets/runner_logo.png',
                          height: ResponsiveUtils.height(context) * 0.4,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.healing_rounded,
                                size: ResponsiveUtils.height(context) * 0.4, 
                                color: Theme.of(context).colorScheme.primary);
                          },
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context, 16)),
                        // App Name (Arabic and English)
                        Text(
                          'Tamrena-Tech تَمْرِينَتُكَ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 34),
                            fontWeight: FontWeight.w900,
                            color: const Color.fromARGB(230, 0, 255, 166),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        // Slogan
                        Text(
                          t('Your path to recovery, in your hands.', 'طريقك للشفاء في يديك.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 18),
                            color: const Color(0xFF8BC34A),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context, 48)),
                        // Buttons
                        GradientButton(
                          text: t('Create Account', 'إنشاء حساب'),
                          onPressed: widget.onCreateAccount,
                          textColor: const Color.fromARGB(255, 255, 255, 255),
                          startColor: const Color(0xFF8BC34A),
                          endColor: const Color(0xFFB3E5FC),
                          icon: const Icon(Icons.person_add_alt_1_rounded,
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                        GradientButton(
                          text: t('Login as Doctor', 'تسجيل الدخول كطبيب'),
                          onPressed: widget.onLoginDoctor,
                          textColor: const Color.fromARGB(255, 255, 255, 255),
                          startColor: const Color(0xFF4DD0E1),
                          endColor: const Color(0xFF00BCD4),
                          icon: const Icon(Icons.medical_services_rounded,
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                        GradientButton(
                          text: t('Login as Patient', 'تسجيل الدخول كمريض'),
                          onPressed: widget.onLoginPatient,
                          textColor: Colors.white,
                          startColor: const Color(0xFF4DD0E1),
                          endColor: const Color(0xFF00BCD4),
                          icon: const Icon(Icons.accessibility_new_rounded,
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ],
                    ),
                    Positioned(
                      top: ResponsiveUtils.isMobile(context) ? 0 : ResponsiveUtils.spacing(context, 16),
                      right: ResponsiveUtils.isMobile(context) ? 0 : ResponsiveUtils.spacing(context, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.settings, 
                            color: Colors.white,
                            size: ResponsiveUtils.iconSize(context, 24),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('Settings'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Theme Section
                                            Text(
                                              'Theme',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                title: const Text('Dark Mode'),
                                                trailing: Switch(
                                                  value: globalThemeProvider.isDarkMode,
                                                  onChanged: (value) {
                                                    globalThemeProvider.toggleTheme();
                                                    setState(() {});
                                                  },
                                                  activeThumbColor: const Color(0xFF00BCD4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            // Language Section
                                            Text(
                                              'Language',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Wrap(
                                                spacing: 12,
                                                children: [
                                                  ChoiceChip(
                                                    label: const Text('English'),
                                                    selected: globalThemeProvider.language == 'en',
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        globalThemeProvider.setLanguage('en');
                                                        setState(() {});
                                                      }
                                                    },
                                                    selectedColor: const Color(0x3300BCD4),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text('العربية (Arabic)'),
                                                    selected: globalThemeProvider.language == 'ar',
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        globalThemeProvider.setLanguage('ar');
                                                        setState(() {});
                                                      }
                                                    },
                                                    selectedColor: const Color(0x3300BCD4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          tooltip: 'Settings',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
