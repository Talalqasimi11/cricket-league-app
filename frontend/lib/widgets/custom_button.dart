import 'package:flutter/material.dart';
import '../core/theme/theme_config.dart';
import '../core/icons.dart';

/// Enhanced button system for the Cricket League app
/// Provides consistent styling, animations, and loading states
enum ButtonVariant { primary, secondary, success, danger, outline, ghost }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Widget? customIcon;
  final bool fullWidth;
  final double? customWidth;
  final double? customHeight;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.customIcon,
    this.fullWidth = false,
    this.customWidth,
    this.customHeight,
    this.borderRadius,
    this.padding,
    this.textStyle,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimationDuration.short,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine button properties based on variant
    final buttonStyle = _getButtonStyle(context);

    // Determine size properties
    final sizeProps = _getSizeProperties();

    // Handle disabled state
    final effectiveDisabled = widget.isDisabled || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              width:
                  widget.customWidth ??
                  (widget.fullWidth ? double.infinity : null),
              height: widget.customHeight ?? sizeProps.height,
              decoration: buttonStyle.decoration?.copyWith(
                borderRadius:
                    widget.borderRadius ??
                    BorderRadius.circular(sizeProps.borderRadius),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: effectiveDisabled ? null : widget.onPressed,
                  borderRadius:
                      widget.borderRadius ??
                      BorderRadius.circular(sizeProps.borderRadius),
                  child: Container(
                    padding: widget.padding ?? sizeProps.padding,
                    child: Row(
                      mainAxisSize: widget.fullWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: sizeProps.iconSize,
                            height: sizeProps.iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                buttonStyle.textColor ?? Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ] else if (widget.customIcon != null) ...[
                          widget.customIcon!,
                          SizedBox(width: AppSpacing.sm),
                        ] else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: sizeProps.iconSize,
                            color: buttonStyle.textColor,
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style:
                                widget.textStyle ??
                                sizeProps.textStyle.copyWith(
                                  color: buttonStyle.textColor,
                                ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ButtonStyle _getButtonStyle(BuildContext context) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textColor: Colors.white,
        );

      case ButtonVariant.secondary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textColor: AppColors.primary,
        );

      case ButtonVariant.success:
        return _ButtonStyle(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textColor: Colors.white,
        );

      case ButtonVariant.danger:
        return _ButtonStyle(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textColor: Colors.white,
        );

      case ButtonVariant.outline:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textColor: AppColors.primary,
        );

      case ButtonVariant.ghost:
        return _ButtonStyle(
          decoration: const BoxDecoration(color: Colors.transparent),
          textColor: AppColors.primary,
        );
    }
  }

  _ButtonSizeProperties _getSizeProperties() {
    switch (widget.size) {
      case ButtonSize.small:
        return _ButtonSizeProperties(
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 12),
          iconSize: AppIcons.sm,
          borderRadius: AppBorderRadius.sm,
        );

      case ButtonSize.medium:
        return _ButtonSizeProperties(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.button,
          iconSize: AppIcons.md,
          borderRadius: AppBorderRadius.md,
        );

      case ButtonSize.large:
        return _ButtonSizeProperties(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 16),
          iconSize: AppIcons.lg,
          borderRadius: AppBorderRadius.lg,
        );
    }
  }
}

class _ButtonStyle {
  final BoxDecoration? decoration;
  final Color? textColor;

  const _ButtonStyle({this.decoration, this.textColor});
}

class _ButtonSizeProperties {
  final double height;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final double iconSize;
  final double borderRadius;

  const _ButtonSizeProperties({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
    required this.borderRadius,
  });
}

/// Convenience widgets for common button types
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.primary);
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.secondary);
}

class SuccessButton extends CustomButton {
  const SuccessButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.success);
}

class DangerButton extends CustomButton {
  const DangerButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.danger);
}

class OutlineButton extends CustomButton {
  const OutlineButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.outline);
}

class GhostButton extends CustomButton {
  const GhostButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size,
    super.isLoading,
    super.isDisabled,
    super.icon,
    super.customIcon,
    super.fullWidth,
    super.customWidth,
    super.customHeight,
  }) : super(variant: ButtonVariant.ghost);
}
