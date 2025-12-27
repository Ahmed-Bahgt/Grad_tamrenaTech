import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  const CustomAppBar({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);
    final shouldShowBack = onBack != null || canPop;
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: Theme.of(context).appBarTheme.elevation ?? 0,
      leading: shouldShowBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: shouldShowBack,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
