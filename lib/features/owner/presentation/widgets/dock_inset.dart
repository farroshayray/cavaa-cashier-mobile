import 'dart:math' as math;

import 'package:flutter/widgets.dart';

extension DockInsetPadding on EdgeInsets {
  /// Adds the bottom inset from [MediaQuery] so the end of a scroll view
  /// clears whatever overlays the bottom of the screen: the owner's floating
  /// dock, or the system navigation bar elsewhere.
  EdgeInsets withBottomInset(BuildContext context) =>
      copyWith(bottom: bottom + MediaQuery.paddingOf(context).bottom);
}

/// Publishes how far the owner's floating dock overlaps the pages below it.
///
/// Measured here, above the pages' own Scaffolds, because a Scaffold strips
/// the bottom padding from the MediaQuery it gives its floating action
/// button.
class DockOverlapScope extends StatelessWidget {
  const DockOverlapScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final overlap = math.max(
      0.0,
      MediaQuery.paddingOf(context).bottom -
          MediaQuery.viewPaddingOf(context).bottom,
    );
    return _DockOverlap(overlap: overlap, child: child);
  }
}

class _DockOverlap extends InheritedWidget {
  const _DockOverlap({required this.overlap, required super.child});

  final double overlap;

  @override
  bool updateShouldNotify(_DockOverlap oldWidget) =>
      oldWidget.overlap != overlap;
}

/// Lifts a FloatingActionButton above the owner's floating dock. Scaffold
/// places FABs using only the system view padding, so the dock's overlap has
/// to be applied by hand. Outside the owner shell this adds nothing.
class DockAwareFab extends StatelessWidget {
  const DockAwareFab({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final overlap =
        context.dependOnInheritedWidgetOfExactType<_DockOverlap>()?.overlap ??
        0;
    return Padding(
      padding: EdgeInsets.only(bottom: overlap),
      child: child,
    );
  }
}
