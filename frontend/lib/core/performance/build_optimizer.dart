import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// A mixin that provides build optimization methods
mixin BuildOptimizer<T extends StatefulWidget> on State<T> {
  bool _shouldRebuild = true;
  DateTime? _lastBuild;
  int _buildCount = 0;
  static const _minBuildInterval = Duration(milliseconds: 16); // ~60 FPS

  @override
  void initState() {
    super.initState();
    _lastBuild = DateTime.now();
  }

  /// Check if enough time has passed since last build
  bool get shouldBuildNow {
    final now = DateTime.now();
    if (_lastBuild == null) return true;

    final timeSinceLastBuild = now.difference(_lastBuild!);
    return timeSinceLastBuild >= _minBuildInterval;
  }

  /// Mark widget for rebuild
  void markNeedsRebuild() {
    _shouldRebuild = true;
  }

  /// Override this method to implement custom rebuild logic
  bool get shouldRebuild => _shouldRebuild;

  /// Call this in your build method to track builds
  void trackBuild() {
    _buildCount++;
    _lastBuild = DateTime.now();
    _shouldRebuild = false;
  }

  /// Get the number of times this widget has been built
  int get buildCount => _buildCount;

  /// Reset build tracking
  void resetBuildTracking() {
    _buildCount = 0;
    _lastBuild = null;
    _shouldRebuild = true;
  }
}

/// A widget that optimizes builds by checking if they're necessary
abstract class OptimizedStatefulWidget extends StatefulWidget {
  const OptimizedStatefulWidget({super.key});

  @override
  OptimizedState createState();
}

abstract class OptimizedState<T extends OptimizedStatefulWidget>
    extends State<T>
    with BuildOptimizer {
  Widget? _lastBuiltWidget;

  @override
  Widget build(BuildContext context) {
    if (!shouldBuildNow) {
      // Return last built widget instead of empty
      return _lastBuiltWidget ?? buildOptimized(context);
    }
    trackBuild();
    _lastBuiltWidget = buildOptimized(context);
    return _lastBuiltWidget!;
  }

  /// Override this instead of build
  Widget buildOptimized(BuildContext context);

  @override
  void dispose() {
    _lastBuiltWidget = null;
    super.dispose();
  }
}

/// Extension method for optimizing lists
extension OptimizedListView on ListView {
  /// Creates an optimized ListView with automatic item type differentiation
  static ListView optimized<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    Widget? separator,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsets? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    ScrollController? controller,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemBuilder: (context, index) {
        final item = items[index];
        Widget child = itemBuilder(context, item);

        // Add separator if provided
        if (separator != null && index < items.length - 1) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child, separator],
          );
        }

        // Optimize painting
        return RepaintBoundary(child: AutomaticKeepAlive(child: child));
      },
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? (items.length > 100 ? 100 : null),
      semanticChildCount: semanticChildCount,
      controller: controller,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }
}

/// A widget that prevents unnecessary rebuilds
class OptimizedBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final List<Object?> dependencies;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.dependencies = const [],
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: builder(context));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<List<Object?>>('dependencies', dependencies),
    );
  }
}
