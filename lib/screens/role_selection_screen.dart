import 'package:flutter/material.dart';
import '../utils/theme_provider.dart';
import '../widgets/custom_app_bar.dart';

/// Role Selection Screen - Choose between doctor and patient registration
class RoleSelectionScreen extends StatelessWidget {
  final VoidCallback onSelectDoctor;
  final VoidCallback onSelectPatient;
  final VoidCallback onBack;

  const RoleSelectionScreen({
    super.key,
    required this.onSelectDoctor,
    required this.onSelectPatient,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: CustomAppBar(title: t('Choose Your Role', 'اختر دورك'), onBack: onBack),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                t('Are you registering as a Doctor or a Patient?',
                    'هل تسجل كطبيب أم كمريض؟'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RoleCard(
                        title: t("I'm a Doctor", "أنا طبيب"),
                        icon: Icons.local_hospital_rounded,
                        onTap: onSelectDoctor,
                        color: const Color(0xFF00BCD4),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RoleCard(
                        title: t("I'm a Patient", "أنا مريض"),
                        icon: Icons.self_improvement_rounded,
                        onTap: onSelectPatient,
                        color: const Color(0xFF8BC34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Role Card Widget - Selectable card for doctor/patient choice
class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorWithOpacity(color, 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: colorWithOpacity(color, 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
