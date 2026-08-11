import 'package:flutter/material.dart';
import 'package:full_screen_bottom_sheet/full_screen_bottom_sheet.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'full_screen_bottom_sheet',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('full_screen_bottom_sheet')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton(
              onPressed: () => _showListSheet(context),
              child: const Text('Sliver list, snapping'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showMetricsSheet(context),
              child: const Text('Single child, live metrics'),
            ),
          ],
        ),
      ),
    );
  }

  void _showListSheet(BuildContext context) {
    FullScreenBottomSheet.show(
      context,
      builder: (BuildContext context) => FullScreenBottomSheet(
        initialExtent: 0.6,
        minExtent: 0.4,
        snap: true,
        snapSizes: const <double>[0.6, 1.0],
        headerBuilder: (BuildContext context, FullScreenBottomSheetMetrics metrics) => FullScreenBottomSheetBar(
          metrics: metrics,
          title: const Text('Nearby restaurants'),
          pageActions: <Widget>[
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          ],
        ),
        footerBuilder: (BuildContext context, FullScreenBottomSheetMetrics metrics) => Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ),
        slivers: (BuildContext context, ScrollController scrollController) => <Widget>[
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (BuildContext context, int index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('Restaurant ${index + 1}'),
              subtitle: const Text('Open until 11:00 PM'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMetricsSheet(BuildContext context) {
    FullScreenBottomSheet.show(
      context,
      builder: (BuildContext context) => FullScreenBottomSheet(
        initialExtent: 0.5,
        minExtent: 0.3,
        headerBuilder: (BuildContext context, FullScreenBottomSheetMetrics metrics) => FullScreenBottomSheetBar(
          metrics: metrics,
          title: const Text('Live metrics'),
        ),
        child: const _MetricsReadout(),
      ),
    );
  }
}

class _MetricsReadout extends StatelessWidget {
  const _MetricsReadout();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FullScreenBottomSheetMetrics>(
      valueListenable: FullScreenBottomSheetScope.of(context),
      builder: (BuildContext context, FullScreenBottomSheetMetrics metrics, Widget? child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Drag the sheet — this follows every frame '
                  'without rebuilding the sheet itself.'),
              const SizedBox(height: 24),
              _Row('extent', metrics.extent.toStringAsFixed(3)),
              _Row('expansion', metrics.expansion.toStringAsFixed(3)),
              _Row('safeAreaProgress', metrics.safeAreaProgress.toStringAsFixed(3)),
              _Row('isFullScreen', '${metrics.isFullScreen}'),
              const SizedBox(height: 24),
              LinearProgressIndicator(value: metrics.expansion),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
