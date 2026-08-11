import 'package:flutter/material.dart';

import 'full_screen_bottom_sheet_metrics.dart';

/// A header that presents as a bottom-sheet bar while the sheet is partially
/// open and as an app bar once it covers the status bar.
///
/// In sheet form it shows a drag handle above a title row with a trailing close
/// button. In page form it drops the handle, pads itself past the status bar,
/// and shows a leading back button — so an expanded sheet reads as a screen.
///
/// Every part can be replaced. Pass [pageBar] to drop in an existing app bar
/// widget for the expanded state, or [sheetBar] to fully control the collapsed
/// state; the rest of the parameters are ignored for whichever state you
/// override.
///
/// When customising [toolbarHeight], [showDragHandle] or [dragHandleHeight],
/// pass the same values to [heightOf] via `FullScreenBottomSheet.headerExtent` so the
/// pinned header reserves the matching height:
///
/// ```dart
/// FullScreenBottomSheet(
///   headerBuilder: (context, metrics) => FullScreenBottomSheetBar(metrics: metrics, toolbarHeight: 64),
///   headerExtent: (metrics) => FullScreenBottomSheetBar.heightOf(metrics, toolbarHeight: 64),
/// );
/// ```
class FullScreenBottomSheetBar extends StatelessWidget {
  /// Height reserved for the drag handle row in sheet form.
  static const double defaultDragHandleHeight = 20;

  /// The enclosing sheet's current metrics.
  final FullScreenBottomSheetMetrics metrics;

  /// Title shown in both forms.
  final Widget? title;

  /// Replaces the whole bar while the sheet is partially open.
  final Widget? sheetBar;

  /// Replaces the whole bar once the sheet is full screen.
  ///
  /// Use this to reuse an app's own app bar. It is rendered below the
  /// status-bar padding, so it should not add safe-area padding itself.
  final Widget? pageBar;

  /// Leading widget in sheet form. Defaults to nothing.
  final Widget? sheetLeading;

  /// Trailing widget in sheet form. Defaults to a close button.
  final Widget? sheetTrailing;

  /// Leading widget in page form. Defaults to a back button.
  final Widget? pageLeading;

  /// Trailing widgets in page form.
  final List<Widget>? pageActions;

  /// Whether to show the drag handle in sheet form.
  final bool showDragHandle;

  /// Replaces the default drag handle.
  final Widget? dragHandle;

  /// Height of the drag handle row. Must match the value passed to [heightOf].
  final double dragHandleHeight;

  /// Height of the title row in both forms.
  final double toolbarHeight;

  /// Background of the bar. Defaults to the theme's surface.
  final Color? backgroundColor;

  /// Border drawn around the bar. Defaults to a hairline bottom divider.
  final BoxBorder? border;

  /// Horizontal padding of the title row.
  final EdgeInsetsGeometry? padding;

  /// Text style of [title]. Defaults to the theme's `titleLarge`.
  final TextStyle? titleStyle;

  /// Whether the title is centered in page form.
  final bool centerTitle;

  /// Called by the default close and back buttons.
  /// Defaults to popping the enclosing route.
  final VoidCallback? onClose;

  /// Duration of the cross-fade between the two forms.
  final Duration transitionDuration;

  /// Creates a header that adapts to the sheet described by [metrics].
  const FullScreenBottomSheetBar({
    super.key,
    required this.metrics,
    this.title,
    this.sheetBar,
    this.pageBar,
    this.sheetLeading,
    this.sheetTrailing,
    this.pageLeading,
    this.pageActions,
    this.showDragHandle = true,
    this.dragHandle,
    this.dragHandleHeight = defaultDragHandleHeight,
    this.toolbarHeight = kToolbarHeight,
    this.backgroundColor,
    this.border,
    this.padding,
    this.titleStyle,
    this.centerTitle = false,
    this.onClose,
    this.transitionDuration = const Duration(milliseconds: 150),
  });

  /// Height this bar occupies for the given [metrics].
  ///
  /// Wire it to `FullScreenBottomSheet.headerExtent`, passing the same values used on
  /// the bar itself.
  static double heightOf(
    FullScreenBottomSheetMetrics metrics, {
    double toolbarHeight = kToolbarHeight,
    bool showDragHandle = true,
    double dragHandleHeight = defaultDragHandleHeight,
  }) {
    final double handle = (showDragHandle && !metrics.isFullScreen) ? dragHandleHeight : 0;
    return metrics.statusBarPadding + toolbarHeight + handle;
  }

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPage = metrics.isFullScreen;

    return Container(
      decoration: BoxDecoration(color: backgroundColor ?? theme.colorScheme.surface),
      // A foreground decoration paints the divider without consuming any of the
      // header's height, so the height stays exactly what `heightOf` reserved.
      foregroundDecoration: BoxDecoration(
        border: border ?? Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      padding: EdgeInsets.only(top: metrics.statusBarPadding),
      // The two forms differ in height, so during the cross-fade the outgoing
      // one is briefly laid out inside the incoming one's box. Each form is
      // given unbounded height and clipped, rather than overflowing its box.
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: transitionDuration,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
          ),
          child: isPage
              ? _Unbounded(key: const ValueKey('full_screen_bottom_sheet_bar.page'), child: _buildPage(context, theme))
              : _Unbounded(key: const ValueKey('full_screen_bottom_sheet_bar.sheet'), child: _buildSheet(context, theme)),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, ThemeData theme) {
    if (pageBar != null) return SizedBox(height: toolbarHeight, child: pageBar);

    final Widget titleWidget = DefaultTextStyle.merge(
      style: titleStyle ?? theme.textTheme.titleLarge,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      child: title ?? const SizedBox.shrink(),
    );

    return SizedBox(
      height: toolbarHeight,
      child: NavigationToolbar(
        centerMiddle: centerTitle,
        leading: pageLeading ?? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _close(context),
        ),
        middle: titleWidget,
        trailing: pageActions == null || pageActions!.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: pageActions!),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, ThemeData theme) {
    final Widget bar = sheetBar ?? Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        if (sheetLeading != null) ...[sheetLeading!, const SizedBox(width: 8)],

        Expanded(
          child: DefaultTextStyle.merge(
            style: titleStyle ?? theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            child: title ?? const SizedBox.shrink(),
          ),
        ),

        sheetTrailing ?? _CloseButton(onTap: () => _close(context)),
      ]),
    );

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (showDragHandle)
        SizedBox(
          height: dragHandleHeight,
          child: Center(child: dragHandle ?? _DragHandle(color: theme.colorScheme.outlineVariant)),
        ),
      SizedBox(height: toolbarHeight, child: bar),
    ]);
  }
}

/// Lays its child out at its natural height, top-aligned, regardless of the
/// incoming height constraint. The caller is expected to clip.
class _Unbounded extends StatelessWidget {
  final Widget child;
  const _Unbounded({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  final Color color;
  const _DragHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerHighest),
        child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
