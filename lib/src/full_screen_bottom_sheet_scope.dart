import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'full_screen_bottom_sheet_metrics.dart';

/// Exposes the enclosing sheet's live metrics to its descendants.
///
/// The notifier updates on every extent change, so a descendant can follow the
/// sheet continuously — for a parallax or fade tied to the drag — without the
/// sheet rebuilding its content on every frame.
///
/// ```dart
/// ValueListenableBuilder<FullScreenBottomSheetMetrics>(
///   valueListenable: FullScreenBottomSheetScope.of(context),
///   builder: (context, metrics, _) => Opacity(
///     opacity: metrics.safeAreaProgress,
///     child: const Text('Happy Hour'),
///   ),
/// );
/// ```
class FullScreenBottomSheetScope extends InheritedWidget {
  /// The enclosing sheet's metrics, updated on every extent change.
  final ValueListenable<FullScreenBottomSheetMetrics> metrics;

  /// Exposes [metrics] to the widgets below [child].
  const FullScreenBottomSheetScope({super.key, required this.metrics, required super.child});

  /// The metrics of the nearest enclosing sheet.
  ///
  /// Throws if there is no [FullScreenBottomSheetScope] above [context]; use
  /// [maybeOf] when the widget can also be used outside a sheet.
  static ValueListenable<FullScreenBottomSheetMetrics> of(BuildContext context) {
    final ValueListenable<FullScreenBottomSheetMetrics>? result = maybeOf(context);
    assert(result != null, 'FullScreenBottomSheetScope.of() called with no FullScreenBottomSheet above the given context.');
    return result!;
  }

  /// The metrics of the nearest enclosing sheet, or null if there is none.
  static ValueListenable<FullScreenBottomSheetMetrics>? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FullScreenBottomSheetScope>()?.metrics;
  }

  @override
  bool updateShouldNotify(FullScreenBottomSheetScope oldWidget) => oldWidget.metrics != metrics;
}
