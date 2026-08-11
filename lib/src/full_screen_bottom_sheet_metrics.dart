import 'package:flutter/widgets.dart';

/// A live snapshot of how far an [FullScreenBottomSheet] is opened.
///
/// Passed to every builder on the sheet so headers, footers and content can
/// react to the sheet growing from a partial sheet into a full-screen page.
@immutable
class FullScreenBottomSheetMetrics {
  /// Slack allowed when comparing the sheet's edge against the safe area, so
  /// accumulated floating-point error in `screenSize.height * (1 - extent)`
  /// cannot leave the sheet a fraction of a pixel short of full screen.
  static const double _edgeTolerance = 0.01;

  /// Fraction of the screen height the sheet currently occupies.
  final double extent;

  /// Smallest fraction the sheet can be dragged to before it is dismissed.
  final double minExtent;

  /// Largest fraction the sheet can be dragged to.
  final double maxExtent;

  /// The device's top safe-area inset (status bar / notch), in logical pixels.
  ///
  /// Read from the physical view rather than the ambient `MediaQuery`, because
  /// a modal route removes the top inset from the `MediaQuery` it provides to
  /// its child.
  final double topInset;

  /// Size of the screen the sheet is presented on.
  final Size screenSize;

  /// Creates a snapshot of a sheet's position.
  const FullScreenBottomSheetMetrics({
    required this.extent,
    required this.minExtent,
    required this.maxExtent,
    required this.topInset,
    required this.screenSize,
  });

  /// Distance from the top of the screen to the top of the sheet, in pixels.
  double get topOffset => screenSize.height * (1 - extent);

  /// How much of the top safe area the sheet currently covers, in pixels.
  ///
  /// Grows from `0` to [topInset] as the sheet slides under the status bar.
  /// Use it as top padding on a header so its content clears the status bar
  /// exactly when the sheet reaches it.
  double get statusBarPadding => (topInset - topOffset).clamp(0.0, topInset);

  /// Whether the sheet's top edge has reached the top safe area, meaning it now
  /// covers the screen and should present itself as a page.
  bool get isFullScreen => topOffset <= topInset + _edgeTolerance;

  /// Progress between [minExtent] and [maxExtent], from `0.0` to `1.0`.
  double get expansion {
    if (maxExtent <= minExtent) return 1;
    return ((extent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);
  }

  /// Progress of the sheet moving into the top safe area, from `0.0` to `1.0`.
  ///
  /// Useful for cross-fading a sheet header into an app bar.
  double get safeAreaProgress {
    if (topInset <= 0) return isFullScreen ? 1 : 0;
    return (statusBarPadding / topInset).clamp(0.0, 1.0);
  }

  /// A copy of these metrics with the given fields replaced.
  FullScreenBottomSheetMetrics copyWith({
    double? extent,
    double? minExtent,
    double? maxExtent,
    double? topInset,
    Size? screenSize,
  }) {
    return FullScreenBottomSheetMetrics(
      extent: extent ?? this.extent,
      minExtent: minExtent ?? this.minExtent,
      maxExtent: maxExtent ?? this.maxExtent,
      topInset: topInset ?? this.topInset,
      screenSize: screenSize ?? this.screenSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FullScreenBottomSheetMetrics
        && other.extent == extent
        && other.minExtent == minExtent
        && other.maxExtent == maxExtent
        && other.topInset == topInset
        && other.screenSize == screenSize;
  }

  @override
  int get hashCode => Object.hash(extent, minExtent, maxExtent, topInset, screenSize);

  @override
  String toString() => 'FullScreenBottomSheetMetrics(extent: $extent, isFullScreen: $isFullScreen)';
}
