import 'package:flutter/material.dart';

import 'full_screen_bottom_sheet_bar.dart';
import 'full_screen_bottom_sheet_metrics.dart';
import 'full_screen_bottom_sheet_scope.dart';

/// Builds a widget from the sheet's live [FullScreenBottomSheetMetrics].
typedef FullScreenBottomSheetWidgetBuilder = Widget Function(BuildContext context, FullScreenBottomSheetMetrics metrics);

/// Builds the sheet's scrollable content as slivers.
///
/// The [scrollController] is already attached to the enclosing scroll view; it
/// is handed over so callers can drive pagination or scroll programmatically.
typedef FullScreenBottomSheetSliversBuilder = List<Widget> Function(BuildContext context, ScrollController scrollController);

/// Resolves the pinned header's height for the given metrics.
typedef FullScreenBottomSheetExtentBuilder = double Function(FullScreenBottomSheetMetrics metrics);

/// Decides whether a metrics change is worth rebuilding the sheet's builders.
typedef FullScreenBottomSheetRebuildPredicate = bool Function(FullScreenBottomSheetMetrics previous, FullScreenBottomSheetMetrics current);

/// A draggable bottom sheet that turns into a full-screen page.
///
/// The sheet's content lives in a single [CustomScrollView] driven by the
/// [DraggableScrollableSheet]'s own controller, so dragging anywhere — header
/// included — resizes the sheet, and dragging below [minExtent] dismisses it.
///
/// The header is a pinned sliver rebuilt from [FullScreenBottomSheetMetrics], which is
/// what lets it present as a sheet header while partially open and as an app
/// bar once the sheet covers the status bar. [FullScreenBottomSheetBar] implements that
/// behaviour and is used by default.
///
/// ```dart
/// FullScreenBottomSheet.show(
///   context,
///   builder: (context) => FullScreenBottomSheet(
///     headerBuilder: (context, metrics) => FullScreenBottomSheetBar(
///       metrics: metrics,
///       title: const Text('Happy Hour'),
///     ),
///     slivers: (context, scrollController) => [
///       SliverList.builder(itemBuilder: ..., itemCount: ...),
///     ],
///   ),
/// );
/// ```
///
/// ## Rebuild behaviour
///
/// [headerBuilder] and [footerBuilder] rebuild only when [rebuildWhen] returns
/// true — by default when the header's appearance actually changes, not on
/// every drag pixel — so dragging never rebuilds the sheet's content. To follow
/// the extent continuously (for a custom animation), listen to
/// [FullScreenBottomSheetScope.of] instead, which updates every frame without
/// rebuilding any ancestor.
class FullScreenBottomSheet extends StatefulWidget {
  /// Builds the pinned header. Defaults to no header when null.
  final FullScreenBottomSheetWidgetBuilder? headerBuilder;

  /// Height of the pinned header for the current metrics.
  ///
  /// Defaults to [FullScreenBottomSheetBar.heightOf]. Provide a matching implementation
  /// when [headerBuilder] returns a header of a different height.
  final FullScreenBottomSheetExtentBuilder? headerExtent;

  /// Builds the scrollable content as slivers.
  final FullScreenBottomSheetSliversBuilder? slivers;

  /// Convenience alternative to [slivers] for a single box-model child.
  final Widget? child;

  /// Builds a bar pinned to the bottom of the sheet, above the content.
  ///
  /// Space equal to the footer's measured height is reserved at the end of the
  /// scroll view so the footer never covers the last item.
  final FullScreenBottomSheetWidgetBuilder? footerBuilder;

  /// Fraction of the screen the sheet occupies when first shown.
  final double initialExtent;

  /// Fraction below which dragging dismisses the sheet.
  final double minExtent;

  /// Largest fraction the sheet can be dragged to. `1.0` means full screen.
  final double maxExtent;

  /// Whether the sheet snaps to [snapSizes] when released.
  final bool snap;

  /// Extents the sheet snaps to when [snap] is true.
  final List<double>? snapSizes;

  /// Background behind the sheet's content. Defaults to the theme's surface.
  final Color? backgroundColor;

  /// Corner rounding of the sheet. Defaults to a 16px top-only radius.
  final BorderRadiusGeometry? borderRadius;

  /// Scroll physics for the sheet's scroll view.
  final ScrollPhysics? physics;

  /// Controller for driving the sheet's extent programmatically.
  ///
  /// When null the sheet creates and disposes its own.
  final DraggableScrollableController? controller;

  /// Called on every extent change, including changes that do not rebuild.
  final ValueChanged<FullScreenBottomSheetMetrics>? onMetricsChanged;

  /// Whether a metrics change should rebuild [headerBuilder] and
  /// [footerBuilder]. Defaults to [defaultRebuildWhen].
  final FullScreenBottomSheetRebuildPredicate? rebuildWhen;

  /// Creates a sheet that expands from [initialExtent] into a full-screen page.
  const FullScreenBottomSheet({
    super.key,
    this.headerBuilder,
    this.headerExtent,
    this.slivers,
    this.child,
    this.footerBuilder,
    this.initialExtent = 0.92,
    this.minExtent = 0.5,
    this.maxExtent = 1.0,
    this.snap = false,
    this.snapSizes,
    this.backgroundColor,
    this.borderRadius,
    this.physics,
    this.controller,
    this.onMetricsChanged,
    this.rebuildWhen,
  })  : assert(minExtent <= initialExtent && initialExtent <= maxExtent,
            'initialExtent must be between minExtent and maxExtent'),
        assert(slivers == null || child == null, 'Provide either slivers or child, not both');

  /// Rebuilds only when the header's appearance changes: when the sheet crosses
  /// into or out of full screen, or while it is sliding through the top safe
  /// area (where the header's status-bar padding grows).
  static bool defaultRebuildWhen(FullScreenBottomSheetMetrics previous, FullScreenBottomSheetMetrics current) {
    return previous.isFullScreen != current.isFullScreen
        || previous.statusBarPadding != current.statusBarPadding;
  }

  /// Presents [builder] as a modal bottom sheet configured for [FullScreenBottomSheet].
  ///
  /// Uses a transparent background and full-height layout so the sheet controls
  /// its own shape, and skips safe-area insets so it can extend under the
  /// status bar when expanded.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = true,
    Color? barrierColor,
    double? maxWidth,
    RouteSettings? routeSettings,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      barrierColor: barrierColor,
      routeSettings: routeSettings,
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
    );
  }

  @override
  State<FullScreenBottomSheet> createState() => _FullScreenBottomSheetState();
}

class _FullScreenBottomSheetState extends State<FullScreenBottomSheet> {
  DraggableScrollableController? _internalController;
  late final ValueNotifier<FullScreenBottomSheetMetrics> _metrics;
  double _footerHeight = 0;

  DraggableScrollableController get _controller =>
      widget.controller ?? (_internalController ??= DraggableScrollableController());

  @override
  void initState() {
    super.initState();
    _metrics = ValueNotifier<FullScreenBottomSheetMetrics>(_metricsFor(widget.initialExtent, const Size(0, 0), 0));
  }

  @override
  void dispose() {
    _metrics.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  FullScreenBottomSheetMetrics _metricsFor(double extent, Size screenSize, double topInset) {
    return FullScreenBottomSheetMetrics(
      extent: extent,
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      topInset: topInset,
      screenSize: screenSize,
    );
  }

  // The modal route strips the top inset from the MediaQuery it provides, so
  // the real inset comes from the view the sheet is rendered into.
  FullScreenBottomSheetMetrics _readMetrics(double extent) {
    final MediaQueryData view = MediaQueryData.fromView(View.of(context));
    return _metricsFor(extent, view.size, view.padding.top);
  }

  void _handleExtent(double extent) {
    final FullScreenBottomSheetMetrics next = _readMetrics(extent);
    final FullScreenBottomSheetMetrics previous = _metrics.value;
    if (next == previous) return;

    _metrics.value = next;
    widget.onMetricsChanged?.call(next);

    final FullScreenBottomSheetRebuildPredicate shouldRebuild = widget.rebuildWhen ?? FullScreenBottomSheet.defaultRebuildWhen;
    if (shouldRebuild(previous, next)) {
      setState(() {});
    }
  }

  void _handleFooterHeight(double height) {
    if (height == _footerHeight) return;
    setState(() => _footerHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadiusGeometry borderRadius =
        widget.borderRadius ?? const BorderRadius.vertical(top: Radius.circular(16));
    final Color background = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _handleExtent(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: widget.initialExtent,
        minChildSize: widget.minExtent,
        maxChildSize: widget.maxExtent,
        snap: widget.snap,
        snapSizes: widget.snapSizes,
        expand: false,
        builder: (context, scrollController) {
          // Metrics are seeded before the first notification arrives so the
          // header opens at the right height instead of snapping into place.
          final FullScreenBottomSheetMetrics metrics = _metrics.value.screenSize.isEmpty
              ? _readMetrics(widget.initialExtent)
              : _metrics.value;

          return FullScreenBottomSheetScope(
            metrics: _metrics,
            child: ClipRRect(
              borderRadius: borderRadius.resolve(Directionality.of(context)),
              child: ColoredBox(
                color: background,
                child: Stack(children: [
                  CustomScrollView(
                    controller: scrollController,
                    physics: widget.physics,
                    slivers: [
                      if (widget.headerBuilder != null)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _FullScreenBottomSheetHeaderDelegate(
                            extent: (widget.headerExtent ?? FullScreenBottomSheetBar.heightOf)(metrics),
                            child: widget.headerBuilder!(context, metrics),
                          ),
                        ),
                      ...?widget.slivers?.call(context, scrollController),
                      if (widget.child != null) SliverToBoxAdapter(child: widget.child),
                      if (_footerHeight > 0) SliverToBoxAdapter(child: SizedBox(height: _footerHeight)),
                    ],
                  ),

                  if (widget.footerBuilder != null)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: _MeasureHeight(
                        onChanged: _handleFooterHeight,
                        child: widget.footerBuilder!(context, metrics),
                      ),
                    ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FullScreenBottomSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  const _FullScreenBottomSheetHeaderDelegate({required this.extent, required this.child});

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FullScreenBottomSheetHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

/// Reports its child's height after layout, so the sheet can reserve scroll
/// space for a pinned footer without the caller hard-coding its height.
class _MeasureHeight extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onChanged;

  const _MeasureHeight({required this.child, required this.onChanged});

  @override
  State<_MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<_MeasureHeight> {
  final GlobalKey _key = GlobalKey();

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double? height = (_key.currentContext?.findRenderObject() as RenderBox?)?.size.height;
      if (height != null) widget.onChanged(height);
    });
  }

  @override
  Widget build(BuildContext context) {
    _report();
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
