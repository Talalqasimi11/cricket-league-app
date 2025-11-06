import 'package:flutter/material.dart';
import '../core/theme/theme_config.dart';
import '../core/theme/theme_extensions.dart';

/// A custom dropdown menu with modern UI/UX characteristics
class CustomDropdownMenu extends StatelessWidget {
  final List<Widget> items;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final BoxShadow? shadow;

  const CustomDropdownMenu({
    super.key,
    required this.items,
    this.margin,
    this.width,
    this.padding,
    this.borderRadius,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width ?? 280,
      margin: margin ?? const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          shadow ?? const BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced dropdown menu item with better UX
class CustomDropdownMenuItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showDivider;
  final Color? iconColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const CustomDropdownMenuItem({
    super.key,
    required this.label,
    this.icon,
    this.customIcon,
    this.onTap,
    this.enabled = true,
    this.showDivider = false,
    this.iconColor,
    this.textColor,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Icon with proper sizing and color
                  if (customIcon != null) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: customIcon,
                    ),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? theme.colorScheme.primary,
                    ),
                  ] else ...[
                    const SizedBox(width: 20), // Placeholder for alignment
                  ],

                  const SizedBox(width: 12),

                  // Label with proper typography
                  Expanded(
                    child: Text(
                      label,
                      style: textStyle ?? AppTypographyExtended.bodyLarge.copyWith(
                        color: enabled
                            ? (textColor ?? theme.colorScheme.onSurface)
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Optional trailing indicator for interactive items
                  if (onTap != null && enabled)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A complete dropdown menu overlay with proper positioning
class CustomDropdownOverlay extends StatelessWidget {
  final Widget child;
  final Offset offset;
  final bool dismissOnTap;
  final VoidCallback? onDismiss;

  const CustomDropdownOverlay({
    super.key,
    required this.child,
    this.offset = const Offset(0, 8),
    this.dismissOnTap = true,
    this.onDismiss,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Offset offset = const Offset(0, 8),
    bool dismissOnTap = true,
    VoidCallback? onDismiss,
  }) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset, ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    return showMenu<T>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      elevation: 0,
      color: Colors.transparent,
      items: [
        PopupMenuItem(
          enabled: false,
          child: Builder(builder: builder),
        ),
      ],
    ).then((value) {
      onDismiss?.call();
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Pre-built app menu for common use cases with proper button styling
class AppMenu extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback? onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onAccount;
  final VoidCallback? onContact;
  final VoidCallback? onFeedback;
  final VoidCallback? onThemeToggle;

  const AppMenu({
    super.key,
    required this.isAuthenticated,
    this.onLogin,
    this.onLogout,
    this.onAccount,
    this.onContact,
    this.onFeedback,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomDropdownMenu(
      width: 320, // Wider for buttons
      items: [
        // Login Button - Prominent action
        if (!isAuthenticated) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: Icon(
                Icons.login,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: const Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Account menu item
          CustomDropdownMenuItem(
            label: 'Account',
            icon: Icons.account_circle,
            iconColor: theme.colorScheme.primary,
            onTap: onAccount,
          ),
          // Logout menu item with divider
          CustomDropdownMenuItem(
            label: 'Logout',
            icon: Icons.logout,
            iconColor: theme.colorScheme.error,
            onTap: onLogout,
            showDivider: true,
          ),
        ],



        // Support section with divider
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
        ),

        // Support menu items
        CustomDropdownMenuItem(
          label: 'Contact Us',
          icon: Icons.contact_support,
          iconColor: theme.colorScheme.secondary,
          onTap: onContact,
        ),
        CustomDropdownMenuItem(
          label: 'Feedback',
          icon: Icons.feedback,
          iconColor: theme.colorScheme.secondary,
          onTap: onFeedback,
        ),
      ],
    );
  }
}
