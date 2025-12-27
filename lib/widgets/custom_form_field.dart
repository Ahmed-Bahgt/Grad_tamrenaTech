import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String labelText;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? initialValue;

  const CustomFormField(
    this.labelText, {
    super.key,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        obscureText: isPassword,
        style: TextStyle(color: isDark ? const Color(0xFFDEE2E6) : Colors.black87),
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    );
  }
}
