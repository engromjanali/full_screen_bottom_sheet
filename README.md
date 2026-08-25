# full_screen_bottom_sheet

A draggable bottom sheet that becomes a full-screen page, with a header that
adapts between sheet and app-bar presentation.

Dragging anywhere in the sheet — header included — resizes it, and dragging
past its minimum extent dismisses it, because the whole sheet is one scroll
view driven by the drag controller. As the sheet slides under the status bar
its header pads itself past the notch and swaps its close button for a back
button, so an expanded sheet reads as a screen rather than a sheet.

The package depends only on Flutter, so it carries no opinion about state
management or navigation.

![A bottom sheet dragged up until it becomes a full-screen page, its header turning into an app bar](https://raw.githubusercontent.com/engromjanali/full_screen_bottom_sheet/main/screenshots/full-screen-transition.gif)

## Usage

```dart
FullScreenBottomSheet.show(
  context,
  builder: (context) => FullScreenBottomSheet(
    headerBuilder: (context, metrics) => FullScreenBottomSheetBar(
      metrics: metrics,
      title: const Text('Happy Hour'),
    ),
    slivers: (context, scrollController) => [
      SliverList.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) => RestaurantCard(restaurants[index]),
      ),
    ],
  ),
);
```

For a single box-model child, pass `child:` instead of `slivers:`.

## Sizing

| Parameter | Meaning |
| --- | --- |
| `initialExtent` | Fraction of the screen occupied when first shown. |
| `minExtent` | Fraction below which dragging dismisses the sheet. |
| `maxExtent` | Largest fraction; `1.0` is full screen. |
| `snap` / `snapSizes` | Snap to fixed extents on release. |

## Reacting to the drag

`FullScreenBottomSheetMetrics` describes how far the sheet is opened:

- `isFullScreen` — the sheet's top has reached the top safe area.
- `statusBarPadding` — how much of the status bar the sheet covers; use it as
  top padding so content clears the notch exactly when it needs to.
- `expansion` — progress between `minExtent` and `maxExtent`.
- `safeAreaProgress` — progress moving into the safe area, for cross-fades.

![The sheet's metrics updating on every frame of a drag](https://raw.githubusercontent.com/engromjanali/full_screen_bottom_sheet/main/screenshots/live-metrics.gif)

`headerBuilder` and `footerBuilder` rebuild only when the header's appearance
actually changes, so dragging never rebuilds the sheet's content. Override
`rebuildWhen` to widen or narrow that. To follow the extent continuously
without rebuilding anything else, listen to the scope:

```dart
ValueListenableBuilder<FullScreenBottomSheetMetrics>(
  valueListenable: FullScreenBottomSheetScope.of(context),
  builder: (context, metrics, _) => Opacity(opacity: metrics.expansion, child: child),
);
```

## Customising the header

`FullScreenBottomSheetBar` fills in sensible defaults but every part is replaceable —
`sheetLeading`, `sheetTrailing`, `pageLeading`, `pageActions`, `dragHandle`,
and `title`. To reuse an existing app bar for the expanded state, pass it as
`pageBar`; to fully control the collapsed state, pass `sheetBar`.

When changing `toolbarHeight`, `showDragHandle` or `dragHandleHeight`, pass the
same values to `FullScreenBottomSheetBar.heightOf` through `headerExtent` so the pinned
header reserves the matching height:

```dart
FullScreenBottomSheet(
  headerBuilder: (context, metrics) => FullScreenBottomSheetBar(metrics: metrics, toolbarHeight: 64),
  headerExtent: (metrics) => FullScreenBottomSheetBar.heightOf(metrics, toolbarHeight: 64),
);
```

A completely custom header works too — return any widget from `headerBuilder`
and give `headerExtent` its height.

## Pinned footer

`footerBuilder` pins a bar to the bottom of the sheet. Its height is measured
after layout and reserved at the end of the scroll view, so the footer never
covers the last item.
