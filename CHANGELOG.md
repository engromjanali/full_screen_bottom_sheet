## 1.1.0

- The sheet now flattens its top corners as it slides through the top safe area,
  so a full-screen sheet reads as a page instead of a sheet with rounded corners
  against the screen edge. Set `fullScreenBorderRadius` to the same value as
  `borderRadius` to keep the previous behaviour.

## 1.0.0

- Initial release.
- `FullScreenBottomSheet`: draggable bottom sheet backed by a single scroll view, so
  dragging anywhere resizes it and dragging past the minimum extent dismisses it.
- `FullScreenBottomSheetBar`: header that switches between sheet and app-bar
  presentation as the sheet crosses the top safe area.
- `FullScreenBottomSheetMetrics` and `FullScreenBottomSheetScope` for reacting to the sheet's
  extent, either per meaningful change or continuously.
