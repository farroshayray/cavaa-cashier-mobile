import 'package:flutter/widgets.dart';

extension DockInsetPadding on EdgeInsets {
  /// Adds the bottom inset from [MediaQuery] so the end of a scroll view
  /// clears whatever overlays the bottom of the screen: the owner's floating
  /// dock, or the system navigation bar elsewhere.
  EdgeInsets withBottomInset(BuildContext context) =>
      copyWith(bottom: bottom + MediaQuery.paddingOf(context).bottom);
}
