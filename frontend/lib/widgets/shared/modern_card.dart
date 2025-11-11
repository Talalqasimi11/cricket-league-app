import 'package:flutter/material.dart';
import '../../core/theme/theme_config.dart';

/// A modern card component with gradients, shadows, and interactive states
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double elevation;
  final double borderRadius;
  final Border? border;
  final bool enableHover;
  final bool enablePressEffect;
  final Duration animationDuration;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
    this.gradient,
    this.elevation = AppElevation.level2,
    this.borderRadius = AppBorderRadius.lg,
    this.border,
    this.enableHover = true,
    this.enablePressEffect = true,
    this.animationDuration = AppAnimationDuration.short,
  });



  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;

    return AnimatedContainer(
      duration: widget.animationDuration,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppCardColors.cardSurface(),
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border:
            widget.border ??
            Border.all(
              color: AppCardColors.cardBorder().withValues(alpha: 0.3),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: widget.elevation + (_isHovered ? 4 : 0),
            offset: Offset(0, widget.elevation / 2 + (_isHovered ? 2 : 0)),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: widget.elevation * 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      transform: Matrix4.identity()
        ..scaleByDouble(
          _isPressed && widget.enablePressEffect ? 0.98 : 1.0,
          _isPressed && widget.enablePressEffect ? 0.98 : 1.0,
          _isPressed && widget.enablePressEffect ? 0.98 : 1.0,
          _isPressed && widget.enablePressEffect ? 0.98 : 1.0,
        ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onHover: widget.enableHover && isInteractive
              ? (hovered) => setState(() => _isHovered = hovered)
              : null,
          onTapDown: widget.enablePressEffect && isInteractive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enablePressEffect && isInteractive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enablePressEffect && isInteractive
              ? () => setState(() => _isPressed = false)
              : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A specialized match card with enhanced visual design
class MatchCard extends StatelessWidget {
  final String teamA;
  final String teamB;
  final String dateTime;
  final String status;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const MatchCard({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.dateTime,
    required this.status,
    this.subtitle,
    this.onTap,
    this.actionButton,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'live':
        return AppCardColors.liveStatus;
      case 'finished':
      case 'completed':
        return AppCardColors.finishedStatus;
      case 'upcoming':
        return AppCardColors.upcomingStatus;
      default:
        return Colors.grey;
    }
  }

  Gradient? _getStatusGradient() {
    if (status.toLowerCase() == 'live') {
      return const LinearGradient(
        colors: [AppCardColors.liveStatus, Color(0xFFFF6666)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      onTap: onTap,
      gradient: _getStatusGradient(),
      elevation: status.toLowerCase() == 'live'
          ? AppElevation.level3
          : AppElevation.level2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with teams and status
          Row(
            children: [
              // Team avatars and names
              Expanded(
                child: Row(
                  children: [
                    // Team A Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppCardColors.cardSurfaceLight(),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: AppCardColors.cardBorder(),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_cricket,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Teams text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$teamA vs $teamB',
                            style: AppTypographyExtended.titleLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              style: AppTypographyExtended.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(
                    color: _getStatusColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTypographyExtended.labelSmall.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Date/time and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date/time info
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    dateTime,
                    style: AppTypographyExtended.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              // Action button
              if (actionButton != null) actionButton!,
            ],
          ),
        ],
      ),
    );
  }
}

/// A loading skeleton card for better UX during data fetching
class SkeletonCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.borderRadius = AppBorderRadius.lg,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      elevation: AppElevation.level1,
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        height: height - (padding?.vertical ?? AppSpacing.md * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Bottom skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                ),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
