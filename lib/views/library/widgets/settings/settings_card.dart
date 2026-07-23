import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SettingsCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
