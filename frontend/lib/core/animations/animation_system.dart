import 'package:flutter/material.dart';
import '../theme/theme_config.dart';

/// Custom page transitions for smooth navigation
class AppPageTransitions {
  /// Fade transition for modal dialogs
  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: AppAnimationDuration.medium,
    );
  }

  /// Slide transition from right (standard navigation)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: AppAnimationDuration.medium,
    );
  }

  /// Slide transition from bottom (for bottom sheets)
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: AppAnimationDuration.medium,
    );
  }

  /// Scale transition for modal content
  static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: AppAnimationDuration.medium,
    );
  }
}

/// Success feedback animations
class SuccessAnimations {
  /// Bounce animation for success feedback
  static Widget bounceSuccess({
    required Widget child,
    required AnimationController controller,
  }) {
    final animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));

    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Pulse animation for success states
  static Widget pulseSuccess({
    required Widget child,
    required AnimationController controller,
  }) {
    final animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.7,
        end: 1.0,
      ).animate(controller),
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }

  /// Checkmark animation
  static Widget checkmarkAnimation({
    required AnimationController controller,
    Color color = Colors.green,
    double size = 24.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CheckmarkPainter(
            progress: controller.value,
            color: color,
          ),
          size: Size(size, size),
        );
      },
    );
  }
}

/// Loading skeleton animations
class SkeletonAnimations {
  /// Shimmer effect for loading states
  static Widget shimmerSkeleton({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                controller.value - 0.3,
                controller.value,
                controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  /// Pulse loading animation
  static Widget pulseLoading({
    required Widget child,
    required AnimationController controller,
  }) {
    final animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(controller),
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}

/// Micro-interactions for better UX
class MicroInteractions {
  /// Gentle scale animation for button presses
  static Widget pressEffect({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedScale(
      scale: isPressed ? 0.95 : 1.0,
      duration: AppAnimationDuration.shortest,
      curve: Curves.easeInOut,
      child: child,
    );
  }

  /// Hover lift effect for cards
  static Widget hoverLift({
    required Widget child,
    required bool isHovered,
  }) {
    return AnimatedContainer(
      duration: AppAnimationDuration.short,
      curve: Curves.easeOut,
      transform: Transform.translate(
        offset: Offset(0, isHovered ? -4 : 0),
      ).transform,
      child: child,
    );
  }

  /// Gentle rotation for loading indicators
  static Widget rotatingIndicator({
    required Widget child,
    required AnimationController controller,
  }) {
    return RotationTransition(
      turns: controller,
      child: child,
    );
  }

  /// Fade in animation for new content
  static Widget fadeIn({
    required Widget child,
    required AnimationController controller,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      )),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Custom painter for checkmark animation
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = size.width * 0.2;
    final startY = size.height * 0.5;
    final midX = size.width * 0.4;
    final midY = size.height * 0.7;
    final endX = size.width * 0.8;
    final endY = size.height * 0.3;

    if (progress < 0.5) {
      // Draw first line
      final firstProgress = progress * 2;
      final currentMidX = startX + (midX - startX) * firstProgress;
      final currentMidY = startY + (midY - startY) * firstProgress;

      path.moveTo(startX, startY);
      path.lineTo(currentMidX, currentMidY);
    } else {
      // Draw both lines
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);

      final secondProgress = (progress - 0.5) * 2;
      final currentEndX = midX + (endX - midX) * secondProgress;
      final currentEndY = midY + (endY - midY) * secondProgress;

      path.lineTo(currentEndX, currentEndY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Animation presets for common use cases
class AnimationPresets {
  /// Quick bounce for notifications
  static AnimationController quickBounce(AnimationController controller) {
    controller
      ..reset()
      ..forward();
    return controller;
  }

  /// Smooth fade for content changes
  static AnimationController smoothFade(AnimationController controller) {
    controller
      ..reset()
      ..duration = AppAnimationDuration.medium
      ..forward();
    return controller;
  }

  /// Continuous pulse for loading states
  static AnimationController continuousPulse(AnimationController controller) {
    controller
      ..reset()
      ..repeat(reverse: true);
    return controller;
  }
}
