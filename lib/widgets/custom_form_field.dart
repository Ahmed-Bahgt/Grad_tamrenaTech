import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class CustomFormField extends StatelessWidget {
  final String labelText;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? initialValue;
  final TextEditingController? controller;
  final bool? obscureText;

  const CustomFormField(
    this.labelText, {
    super.key,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.initialValue,
    this.controller,
    this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verticalPadding = ResponsiveUtils.spacing(context, 8);
    final fontSize = ResponsiveUtils.fontSize(context, 16);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        keyboardType: keyboardType,
        obscureText: obscureText ?? isPassword,
        style: TextStyle(
          color: isDark ? const Color(0xFFDEE2E6) : Colors.black87,
          fontSize: fontSize,
        ),
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: fontSize * 0.9,
          ),
        ),
      ),
    );
  }
}
