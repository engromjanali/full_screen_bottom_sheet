## 1.0.0

- Initial release.
- `FullScreenBottomSheet`: draggable bottom sheet backed by a single scroll view, so
  dragging anywhere resizes it and dragging past the minimum extent dismisses it.
- `FullScreenBottomSheetBar`: header that switches between sheet and app-bar
  presentation as the sheet crosses the top safe area.
- `FullScreenBottomSheetMetrics` and `FullScreenBottomSheetScope` for reacting to the sheet's
  extent, either per meaningful change or continuously.
