import 'package:full_screen_bottom_sheet/full_screen_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildSheet({
  FullScreenBottomSheetWidgetBuilder? footerBuilder,
  double initialExtent = 0.9,
  ValueChanged<FullScreenBottomSheetMetrics>? onMetricsChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: FullScreenBottomSheet(
        initialExtent: initialExtent,
        onMetricsChanged: onMetricsChanged,
        footerBuilder: footerBuilder,
        headerBuilder: (context, metrics) => FullScreenBottomSheetBar(
          metrics: metrics,
          title: const Text('Title'),
        ),
        slivers: (context, scrollController) => [
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (context, index) => SizedBox(height: 60, child: Text('item $index')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders the header and content', (tester) async {
    await tester.pumpWidget(buildSheet());

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('item 0'), findsOneWidget);
  });

  testWidgets('shows a close button in sheet form and a back button when full screen', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSheet(initialExtent: 0.6));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.drag(find.text('item 0'), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('reports metrics as the sheet is dragged', (tester) async {
    final List<FullScreenBottomSheetMetrics> seen = <FullScreenBottomSheetMetrics>[];
    await tester.pumpWidget(buildSheet(initialExtent: 0.6, onMetricsChanged: seen.add));
    await tester.pumpAndSettle();

    await tester.drag(find.text('item 0'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(seen, isNotEmpty);
    expect(seen.last.extent, greaterThan(0.6));
  });

  testWidgets('pins a footer and reserves scroll space for it', (tester) async {
    await tester.pumpWidget(buildSheet(
      footerBuilder: (context, metrics) => const SizedBox(height: 80, child: Text('footer')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('footer'), findsOneWidget);

    // The reserved spacer keeps the footer from covering the last item.
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();

    final Rect lastItem = tester.getRect(find.text('item 39'));
    final Rect footer = tester.getRect(find.text('footer'));
    expect(lastItem.bottom, lessThanOrEqualTo(footer.top + 1));
  });

  testWidgets('exposes metrics to descendants through the scope', (tester) async {
    late ValueListenable<FullScreenBottomSheetMetrics> listenable;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FullScreenBottomSheet(
          headerBuilder: (context, metrics) => FullScreenBottomSheetBar(metrics: metrics, title: const Text('Title')),
          child: Builder(builder: (context) {
            listenable = FullScreenBottomSheetScope.of(context);
            return const SizedBox(height: 2000);
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(listenable.value.extent, closeTo(0.92, 0.0001));
  });
}
