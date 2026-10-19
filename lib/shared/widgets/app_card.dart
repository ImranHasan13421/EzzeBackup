import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;
  final bool useGlass;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
    this.useGlass = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedColor = color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final resolvedBorder = border ?? BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1,
    );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: useGlass ? (isDark ? AppColors.glassDark : AppColors.glassLight) : resolvedColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.fromBorderSide(resolvedBorder),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    if (useGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primaryBlue.withAlpha(20),
          highlightColor: AppColors.primaryBlue.withAlpha(10),
          child: content,
        ),
      );
    }

    return content;
  }
}
