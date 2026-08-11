import 'package:full_screen_bottom_sheet/full_screen_bottom_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

FullScreenBottomSheetMetrics metricsAt(double extent, {double topInset = 40, double height = 800}) {
  return FullScreenBottomSheetMetrics(
    extent: extent,
    minExtent: 0.5,
    maxExtent: 1.0,
    topInset: topInset,
    screenSize: Size(400, height),
  );
}

void main() {
  group('FullScreenBottomSheetMetrics', () {
    test('reports the sheet top offset from the extent', () {
      expect(metricsAt(0.5).topOffset, 400);
      expect(metricsAt(1.0).topOffset, 0);
    });

    test('is not full screen while the sheet sits below the safe area', () {
      // topOffset 400 > topInset 40.
      expect(metricsAt(0.5).isFullScreen, isFalse);
      expect(metricsAt(0.5).statusBarPadding, 0);
    });

    test('becomes full screen as soon as the top edge reaches the safe area', () {
      // topOffset == topInset == 40.
      expect(metricsAt(0.95).isFullScreen, isTrue);
      expect(metricsAt(0.95).statusBarPadding, 0);
    });

    test('grows status bar padding as the sheet covers the inset', () {
      expect(metricsAt(1.0).statusBarPadding, 40);
      expect(metricsAt(1.0).safeAreaProgress, 1);
    });

    test('never pads beyond the device inset', () {
      expect(metricsAt(1.0, topInset: 40).statusBarPadding, lessThanOrEqualTo(40));
    });

    test('treats a device without a top inset as full screen only at the top', () {
      expect(metricsAt(0.5, topInset: 0).isFullScreen, isFalse);
      expect(metricsAt(1.0, topInset: 0).isFullScreen, isTrue);
      expect(metricsAt(1.0, topInset: 0).safeAreaProgress, 1);
    });

    test('expansion maps the extent onto the draggable range', () {
      expect(metricsAt(0.5).expansion, 0);
      expect(metricsAt(0.75).expansion, closeTo(0.5, 0.0001));
      expect(metricsAt(1.0).expansion, 1);
    });

    test('compares by value so identical metrics do not notify', () {
      expect(metricsAt(0.75), equals(metricsAt(0.75)));
      expect(metricsAt(0.75).hashCode, equals(metricsAt(0.75).hashCode));
      expect(metricsAt(0.75), isNot(equals(metricsAt(0.76))));
    });
  });

  group('FullScreenBottomSheetBar.heightOf', () {
    test('reserves the drag handle only while in sheet form', () {
      final FullScreenBottomSheetMetrics sheet = metricsAt(0.5);
      final FullScreenBottomSheetMetrics page = metricsAt(1.0);

      expect(FullScreenBottomSheetBar.heightOf(sheet), 56 + FullScreenBottomSheetBar.defaultDragHandleHeight);
      expect(FullScreenBottomSheetBar.heightOf(page), 40 + 56);
    });

    test('honours a custom toolbar height', () {
      expect(FullScreenBottomSheetBar.heightOf(metricsAt(0.5), toolbarHeight: 64, showDragHandle: false), 64);
    });
  });
}
