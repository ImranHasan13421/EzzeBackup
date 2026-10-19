import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ButtonVariant { primary, secondary, outline, danger, gradient }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final bool isFullWidth;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.isFullWidth = false,
    this.padding,
    this.fontSize,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border;
    Gradient? gradient;

    switch (widget.variant) {
      case ButtonVariant.primary:
        bg = AppColors.primaryBlue;
        fg = Colors.white;
        break;
      case ButtonVariant.gradient:
        bg = Colors.transparent;
        fg = Colors.white;
        gradient = AppColors.brandGradient;
        break;
      case ButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.primaryBlue;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBlue.withAlpha(80),
          width: 1.5,
        );
        break;
      case ButtonVariant.danger:
        bg = AppColors.errorRed;
        fg = Colors.white;
        break;
    }

    final isDisabled = widget.isLoading || widget.onPressed == null;

    Widget childWidget;
    if (widget.isLoading) {
      childWidget = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      childWidget = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: fg),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: widget.fontSize ?? 13.5,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      );
    }

    final button = AnimatedBuilder(
      listenable: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled ? null : (_) => _controller.reverse(),
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: isDisabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            splashColor: fg.withAlpha(20),
            highlightColor: fg.withAlpha(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: gradient != null ? null : (isDisabled ? bg.withAlpha(100) : bg),
                gradient: isDisabled ? null : gradient,
                borderRadius: BorderRadius.circular(14),
                border: border != null ? Border.fromBorderSide(border) : null,
                boxShadow: [
                  if (!isDisabled && widget.variant == ButtonVariant.gradient)
                    BoxShadow(
                      color: AppColors.brandStart.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: childWidget,
            ),
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

// Helper widget for AnimatedBuilder since it doesn't exist in Flutter
class AnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
