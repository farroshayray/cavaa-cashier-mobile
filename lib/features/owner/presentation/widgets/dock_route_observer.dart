import 'package:flutter/material.dart';

/// Watches the owner's section navigator for routes that the floating dock
/// would cover, so the dock can step aside:
///
/// * bottom sheets ([ModalBottomSheetRoute]);
/// * other popups — dropdown menus and popup menus. A dropdown menu sizes
///   itself to the navigator's full height and ignores MediaQuery padding,
///   so with the dock overlaying the body its last items end up under it.
class DockRouteObserver extends NavigatorObserver {
  DockRouteObserver(this.onChanged);

  /// Called with whether any sheet / any other popup is currently open.
  final void Function(bool sheetOpen, bool popupOpen) onChanged;

  var _sheets = 0;
  var _popups = 0;

  void _update(Route<dynamic> route, int delta) {
    if (route is ModalBottomSheetRoute) {
      _sheets = (_sheets + delta).clamp(0, 1 << 20);
    } else if (route is PopupRoute) {
      _popups = (_popups + delta).clamp(0, 1 << 20);
    } else {
      return;
    }
    onChanged(_sheets > 0, _popups > 0);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, -1);
}

/// Slides the dock out of sight without giving up its layout space, so the
/// page behind (and a dropdown anchored to it) doesn't move.
class DockVisibility extends StatelessWidget {
  const DockVisibility({super.key, required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedSlide(
        offset: hidden ? const Offset(0, 1.3) : Offset.zero,
        duration: _duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: _duration,
          child: child,
        ),
      ),
    );
  }
}
