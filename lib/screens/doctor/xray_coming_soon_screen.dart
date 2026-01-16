import 'package:flutter/material.dart';

/// X-Ray Coming Soon Screen - Placeholder for future X-ray feature
class XrayComingSoonScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const XrayComingSoonScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        title: const Text(
          'X-Ray Analysis',
          style: TextStyle(
            color: Color(0xFF00BCD4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // X-Ray Icon
            Icon(
              Icons.image_search,
              size: 100,
              color: const Color(0xFF00BCD4),
            ),
            const SizedBox(height: 32),

            // Coming Soon Text
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'X-Ray analysis feature will be available soon. This feature will allow you to upload and analyze X-ray images with AI assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Optional: Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00BCD4),
                  width: 1,
                ),
              ),
              child: const Text(
                '🚀 In Development',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
