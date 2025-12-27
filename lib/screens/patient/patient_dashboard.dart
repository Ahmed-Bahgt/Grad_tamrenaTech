import 'package:flutter/material.dart';
import '../../utils/theme_provider.dart';
import 'patient_home_screen.dart';
import 'patient_book_screen.dart';
import 'patient_community_screen.dart';
import 'nutrition_chatbot_screen.dart';
// Squat live stream now accessed via dedicated page; dashboard has no extra FAB

/// Patient Dashboard - Main navigation hub with tab-based navigation
class PatientDashboard extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;
  final ThemeProvider? themeProvider;
  final VoidCallback? onBackToWelcome;
  
  const PatientDashboard({
    super.key,
    this.onLogout,
    this.onSettings,
    this.themeProvider,
    this.onBackToWelcome,
  });

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
          onPressed: widget.onBackToWelcome ?? () => Navigator.maybePop(context),
        ),
        title: const Text('Patient Dashboard'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == 'settings') {
                widget.onSettings?.call();
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 12),
                    Text(t('Settings', 'الإعدادات')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PatientHomeScreen(onBack: widget.onBackToWelcome),
          PatientBookScreen(onBack: widget.onBackToWelcome),
          PatientCommunityScreen(onBack: widget.onBackToWelcome),
          NutritionChatbotScreen(onBack: widget.onBackToWelcome),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: t('Home', 'الرئيسية'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: t('Book', 'حجز'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: t('Community', 'المجتمع'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: t('Nutrition', 'التغذية'),
          ),
        ],
      ),
      // Removed Squat Exercise FAB to keep UI focused and avoid extra buttons
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('Logout', 'تسجيل الخروج')),
          content: Text(
            t('Are you sure you want to logout?', 'هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Cancel', 'إلغاء')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout?.call();
              },
              child: Text(
                t('Logout', 'تسجيل الخروج'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
