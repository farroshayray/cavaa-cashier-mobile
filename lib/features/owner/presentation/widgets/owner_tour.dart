import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _tourBrand = Color(0xFFAE1504);

enum OwnerTourShape { circle, pill, rect }

/// Where a target's callout box sits relative to the highlighted element.
enum OwnerTourSide { above, below, left, right }

/// For [OwnerTourSide.above]/[OwnerTourSide.below]: which end of the box the
/// pointer line meets, so neighbouring boxes can be laid out without their
/// lines crossing each other's boxes.
enum OwnerTourAlign { start, center, end }

enum OwnerTourResult { finished, later, skipped }

class OwnerTourTarget {
  const OwnerTourTarget({
    required this.key,
    required this.text,
    this.shape = OwnerTourShape.rect,
    this.side = OwnerTourSide.below,
    this.align = OwnerTourAlign.center,
    this.anchor = 0.5,
    this.padding = 6,
    this.gap = 26,
  });

  final GlobalKey key;
  final String text;
  final OwnerTourShape shape;
  final OwnerTourSide side;
  final OwnerTourAlign align;

  /// Where along the highlight's edge the line starts (0 = left/top,
  /// 1 = right/bottom).
  final double anchor;
  final double padding;

  /// Distance between the highlight and its callout box.
  final double gap;
}

class OwnerTourStep {
  const OwnerTourStep({
    required this.targets,
    this.primaryLabel = 'Selanjutnya',
    this.secondaryLabel,
    this.beforeShow,
  });

  final List<OwnerTourTarget> targets;
  final String primaryLabel;

  /// Shown instead of "Lewati" when set (e.g. "Nanti" on the last step).
  final String? secondaryLabel;

  /// Runs before the step is measured, e.g. to scroll a target into view.
  final Future<void> Function()? beforeShow;
}

/// Shows a spotlight tour over the whole screen. Each step highlights one or
/// more widgets (by [GlobalKey]) and points a line from each to a short
/// caption. Steps whose targets aren't on screen are skipped.
Future<OwnerTourResult> showOwnerTour(
  BuildContext context,
  List<OwnerTourStep> steps,
) async {
  final result = await Navigator.of(context, rootNavigator: true)
      .push<OwnerTourResult>(
        PageRouteBuilder<OwnerTourResult>(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, _, _) => _OwnerTour(steps: steps),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
  // Back button closes the tour like "Lewati".
  return result ?? OwnerTourResult.skipped;
}

/// One measured target, ready to paint.
class OwnerTourSpot {
  const OwnerTourSpot({
    required this.hole,
    required this.box,
    required this.line,
    required this.text,
  });

  final RRect hole;
  final Rect box;
  final Path line;
  final String text;
}

/// Lays out holes, callout boxes and pointer lines for one step. Kept free of
/// widgets so it can be unit tested.
@visibleForTesting
class OwnerTourLayout {
  OwnerTourLayout._(this.spots, this.controlsRect);

  final List<OwnerTourSpot> spots;
  final Rect controlsRect;

  List<RRect> get holes => [for (final s in spots) s.hole];
  List<Rect> get boxes => [for (final s in spots) s.box];

  static const boxMaxWidth = 180.0;
  static const boxPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 8);
  static const textStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: Color(0xFF111827),
  );
  static const controlsHeight = 56.0;
  static const margin = 16.0;

  static OwnerTourLayout compute({
    required List<(OwnerTourTarget, Rect)> targets,
    required Size screen,
    required EdgeInsets safe,
    required TextScaler textScaler,
    TextStyle? style,
  }) {
    final bounds = Rect.fromLTRB(
      margin,
      safe.top + 8,
      screen.width - margin,
      screen.height - safe.bottom - 8,
    );
    final holes = [for (final (t, r) in targets) _holeFor(t, r)];
    final spots = <OwnerTourSpot>[];
    final placed = <Rect>[];

    for (var i = 0; i < targets.length; i++) {
      final target = targets[i].$1;
      final hole = holes[i];
      var side = target.side;
      var maxWidth = boxMaxWidth;
      if (side == OwnerTourSide.right || side == OwnerTourSide.left) {
        final room = side == OwnerTourSide.right
            ? bounds.right - (hole.right + target.gap)
            : (hole.left - target.gap) - bounds.left;
        if (room < 76) {
          side = OwnerTourSide.below;
        } else {
          maxWidth = math.min(maxWidth, room);
        }
      }
      // The point on the highlight's edge where the line starts.
      final Offset start;
      switch (side) {
        case OwnerTourSide.above:
        case OwnerTourSide.below:
          final x = hole.left + hole.width * target.anchor;
          start = Offset(
            x,
            side == OwnerTourSide.above ? hole.top : hole.bottom,
          );
        case OwnerTourSide.left:
        case OwnerTourSide.right:
          final y = hole.top + hole.height * target.anchor;
          start = Offset(
            side == OwnerTourSide.right ? hole.right : hole.left,
            y,
          );
      }

      // A box that grows to the right of its line must stop before the next
      // target's line on the same side, or that line would run through it.
      if ((side == OwnerTourSide.above || side == OwnerTourSide.below) &&
          target.align == OwnerTourAlign.start) {
        var nextLine = double.infinity;
        for (var j = 0; j < targets.length; j++) {
          if (j == i || targets[j].$1.side != side) continue;
          final x = holes[j].left + holes[j].width * targets[j].$1.anchor;
          if (x > start.dx) nextLine = math.min(nextLine, x);
        }
        final room = nextLine - 10 - math.max(bounds.left, start.dx - 14);
        if (room >= 90) maxWidth = math.min(maxWidth, room);
      }
      final size = _measure(
        target.text,
        maxWidth,
        textScaler,
        style ?? textStyle,
      );

      final obstacles = [
        ...placed,
        for (final h in holes) h.outerRect.inflate(4),
        // Earlier pointer lines, so this box doesn't sit on top of them.
        for (final s in spots) s.line.getBounds().inflate(3),
      ];
      final initial = _clamp(
        _initialBox(side, target, start, size, hole),
        bounds,
      );
      // Nudge away from boxes and highlights already on screen: above/below
      // boxes move further out; side boxes take whichever way is shorter.
      final Rect box;
      switch (side) {
        case OwnerTourSide.above:
          box = _resolve(initial, -1, obstacles, bounds) ?? initial;
        case OwnerTourSide.below:
          box = _resolve(initial, 1, obstacles, bounds) ?? initial;
        case OwnerTourSide.left:
        case OwnerTourSide.right:
          final up = _resolve(initial, -1, obstacles, bounds);
          final down = _resolve(initial, 1, obstacles, bounds);
          if (up == null || down == null) {
            box = up ?? down ?? initial;
          } else {
            box = (up.top - initial.top).abs() <= (down.top - initial.top).abs()
                ? up
                : down;
          }
      }
      placed.add(box);

      spots.add(
        OwnerTourSpot(
          hole: hole,
          box: box,
          line: _linePath(side, start, box),
          text: target.text,
        ),
      );
    }

    // Controls go top or bottom, whichever covers less of the tour.
    final top = Rect.fromLTWH(
      margin,
      safe.top + 10,
      screen.width - margin * 2,
      controlsHeight,
    );
    final bottom = Rect.fromLTWH(
      margin,
      screen.height - safe.bottom - 10 - controlsHeight,
      screen.width - margin * 2,
      controlsHeight,
    );
    double cover(Rect c) {
      var area = 0.0;
      for (final s in spots) {
        for (final r in [s.hole.outerRect, s.box]) {
          final hit = c.intersect(r.inflate(8));
          if (hit.width > 0 && hit.height > 0) area += hit.width * hit.height;
        }
      }
      return area;
    }

    return OwnerTourLayout._(spots, cover(bottom) <= cover(top) ? bottom : top);
  }

  /// Moves [box] vertically in direction [dy] (-1 up, 1 down) until it clears
  /// every obstacle. Returns null if it runs out of screen first.
  static Rect? _resolve(
    Rect box,
    double dy,
    List<Rect> obstacles,
    Rect bounds,
  ) {
    for (var n = 0; n < 24; n++) {
      final hit = obstacles.where((r) => r.overlaps(box.inflate(4)));
      if (hit.isEmpty) return box;
      final r = hit.first;
      final shift = dy < 0 ? box.bottom - r.top + 8 : r.bottom - box.top + 8;
      box = box.shift(Offset(0, dy * shift));
      if (box.top < bounds.top || box.bottom > bounds.bottom) return null;
    }
    return null;
  }

  /// The exact style captions are drawn with: the theme's body text (which
  /// brings its own letter spacing) plus [textStyle]. Measuring with anything
  /// else makes the box too narrow and the last line gets cut off.
  static TextStyle resolveStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.merge(textStyle) ?? textStyle;

  static RRect _holeFor(OwnerTourTarget t, Rect r) {
    switch (t.shape) {
      case OwnerTourShape.circle:
        final d = math.max(r.width, r.height) + t.padding * 2;
        return RRect.fromRectAndRadius(
          Rect.fromCenter(center: r.center, width: d, height: d),
          Radius.circular(d / 2),
        );
      case OwnerTourShape.pill:
        final rect = r.inflate(t.padding);
        return RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
      case OwnerTourShape.rect:
        return RRect.fromRectAndRadius(
          r.inflate(t.padding),
          const Radius.circular(16),
        );
    }
  }

  static Size _measure(
    String text,
    double maxWidth,
    TextScaler scaler,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(maxWidth: maxWidth - boxPadding.horizontal);
    final size = Size(
      painter.width.ceilToDouble() + boxPadding.horizontal + 2,
      painter.height.ceilToDouble() + boxPadding.vertical,
    );
    painter.dispose();
    return size;
  }

  static Rect _initialBox(
    OwnerTourSide side,
    OwnerTourTarget t,
    Offset start,
    Size size,
    RRect hole,
  ) {
    switch (side) {
      case OwnerTourSide.above:
      case OwnerTourSide.below:
        final left = switch (t.align) {
          OwnerTourAlign.start => start.dx - 14,
          OwnerTourAlign.center => start.dx - size.width / 2,
          OwnerTourAlign.end => start.dx - size.width + 14,
        };
        final top = side == OwnerTourSide.above
            ? hole.top - t.gap - size.height
            : hole.bottom + t.gap;
        return Offset(left, top) & size;
      case OwnerTourSide.right:
        return Offset(hole.right + t.gap, start.dy - size.height / 2) & size;
      case OwnerTourSide.left:
        return Offset(
              hole.left - t.gap - size.width,
              start.dy - size.height / 2,
            ) &
            size;
    }
  }

  static Rect _clamp(Rect box, Rect bounds) {
    final dx = box.left < bounds.left
        ? bounds.left - box.left
        : box.right > bounds.right
        ? bounds.right - box.right
        : 0.0;
    final dy = box.top < bounds.top
        ? bounds.top - box.top
        : box.bottom > bounds.bottom
        ? bounds.bottom - box.bottom
        : 0.0;
    return box.shift(Offset(dx, dy));
  }

  static Path _linePath(OwnerTourSide side, Offset start, Rect box) {
    final Offset end;
    final Offset control;
    switch (side) {
      case OwnerTourSide.above:
      case OwnerTourSide.below:
        end = Offset(
          start.dx.clamp(box.left + 10, box.right - 10),
          side == OwnerTourSide.above ? box.bottom : box.top,
        );
        control = Offset(start.dx, (start.dy + end.dy) / 2);
      case OwnerTourSide.left:
      case OwnerTourSide.right:
        end = Offset(
          side == OwnerTourSide.right ? box.left : box.right,
          start.dy.clamp(box.top + 8, box.bottom - 8),
        );
        control = Offset((start.dx + end.dx) / 2, start.dy);
    }
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }
}

class _OwnerTour extends StatefulWidget {
  const _OwnerTour({required this.steps});

  final List<OwnerTourStep> steps;

  @override
  State<_OwnerTour> createState() => _OwnerTourState();
}

class _OwnerTourState extends State<_OwnerTour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _holeT = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0, 0.5, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _lineT = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
  );
  late final Animation<double> _boxT = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  int _index = -1;
  bool _busy = true;
  OwnerTourLayout? _layout;
  List<RRect> _fromHoles = const [];
  Size? _lastScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context);
    if (_lastScreen != null && _lastScreen != screen && !_busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _index < 0) return;
        final layout = _measure(widget.steps[_index]);
        if (layout != null) setState(() => _layout = layout);
      });
    }
    _lastScreen = screen;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  OwnerTourLayout? _measure(OwnerTourStep step) {
    final targets = <(OwnerTourTarget, Rect)>[];
    for (final t in step.targets) {
      final box = t.key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      targets.add((t, box.localToGlobal(Offset.zero) & box.size));
    }
    if (targets.isEmpty) return null;
    final mq = MediaQuery.of(context);
    return OwnerTourLayout.compute(
      style: OwnerTourLayout.resolveStyle(context),
      targets: targets,
      screen: mq.size,
      safe: mq.padding,
      textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
    );
  }

  Future<void> _goTo(int from) async {
    setState(() => _busy = true);
    for (var i = from; i < widget.steps.length; i++) {
      final step = widget.steps[i];
      await step.beforeShow?.call();
      if (!mounted) return;
      // Let scrolling settle and the targets repaint in place.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final layout = _measure(step);
      if (layout == null) continue;
      setState(() {
        _fromHoles = _currentHoles();
        _layout = layout;
        _index = i;
        _busy = false;
      });
      _anim.forward(from: 0);
      return;
    }
    // Nothing left to show.
    _close(OwnerTourResult.finished);
  }

  List<RRect> _currentHoles() {
    final layout = _layout;
    if (layout == null) return const [];
    return _lerpHoles(_fromHoles, layout.holes, _holeT.value);
  }

  static List<RRect> _lerpHoles(List<RRect> from, List<RRect> to, double t) {
    return [
      for (var i = 0; i < to.length; i++)
        RRect.lerp(
          i < from.length
              ? from[i]
              : RRect.fromRectAndRadius(
                  Rect.fromCenter(center: to[i].center, width: 0, height: 0),
                  Radius.zero,
                ),
          to[i],
          t,
        )!,
    ];
  }

  /// Indexes of steps with at least one target on screen.
  List<int> get _available => [
    for (var i = 0; i < widget.steps.length; i++)
      if (widget.steps[i].targets.any((t) => t.key.currentContext != null)) i,
  ];

  bool get _isLast => !_available.any((i) => i > _index);

  void _close(OwnerTourResult result) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        // Swallow taps so nothing under the tour gets pressed by accident.
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final holes = layout == null
                ? const <RRect>[]
                : _lerpHoles(_fromHoles, layout.holes, _holeT.value);
            return Stack(
              children: [
                Positioned.fill(
                  child: ClipPath(
                    clipper: _DimClipper(holes),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                      child: const ColoredBox(color: Color(0x9E000000)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TourPainter(
                        holes: holes,
                        lines: [
                          if (layout != null)
                            for (final s in layout.spots) s.line,
                        ],
                        lineProgress: _lineT.value,
                      ),
                    ),
                  ),
                ),
                if (layout != null)
                  for (final s in layout.spots)
                    // Height is left free so a caption can never be clipped.
                    Positioned(
                      left: s.box.left,
                      top: s.box.top,
                      width: s.box.width,
                      child: Opacity(
                        opacity: _boxT.value,
                        child: Transform.scale(
                          scale: 0.9 + 0.1 * _boxT.value,
                          child: _Callout(text: s.text),
                        ),
                      ),
                    ),
                if (layout != null)
                  Positioned.fromRect(
                    rect: layout.controlsRect,
                    child: _Controls(
                      count: _available.length,
                      current: _available.indexOf(_index),
                      primaryLabel: widget.steps[_index].primaryLabel,
                      secondaryLabel:
                          widget.steps[_index].secondaryLabel ?? 'Lewati',
                      busy: _busy,
                      onPrimary: () => _isLast
                          ? _close(OwnerTourResult.finished)
                          : _goTo(_index + 1),
                      onSecondary: () => _close(
                        widget.steps[_index].secondaryLabel != null
                            ? OwnerTourResult.later
                            : OwnerTourResult.skipped,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DimClipper extends CustomClipper<Path> {
  const _DimClipper(this.holes);

  final List<RRect> holes;

  @override
  Path getClip(Size size) {
    var path = Path()..addRect(Offset.zero & size);
    for (final h in holes) {
      path = Path.combine(PathOperation.difference, path, Path()..addRRect(h));
    }
    return path;
  }

  @override
  bool shouldReclip(_DimClipper oldClipper) => oldClipper.holes != holes;
}

class _TourPainter extends CustomPainter {
  const _TourPainter({
    required this.holes,
    required this.lines,
    required this.lineProgress,
  });

  final List<RRect> holes;
  final List<Path> lines;
  final double lineProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = _tourBrand.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    for (final h in holes) {
      if (h.width < 1) continue;
      canvas.drawRRect(h.inflate(2), glow);
      canvas.drawRRect(h.inflate(1), ring);
    }

    if (lineProgress <= 0) return;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final dot = Paint()..color = Colors.white;
    for (final line in lines) {
      for (final metric in line.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * lineProgress),
          stroke,
        );
        final start = metric.getTangentForOffset(0)?.position;
        if (start != null) canvas.drawCircle(start, 3.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_TourPainter old) =>
      old.holes != holes ||
      old.lines != lines ||
      old.lineProgress != lineProgress;
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: OwnerTourLayout.boxPadding,
          // Same style and scale the layout measured with.
          child: DefaultTextStyle(
            style: OwnerTourLayout.resolveStyle(context),
            child: Text(
              text,
              textWidthBasis: TextWidthBasis.longestLine,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.count,
    required this.current,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.busy,
    required this.onPrimary,
    required this.onSecondary,
  });

  final int count;
  final int current;
  final String primaryLabel;
  final String secondaryLabel;
  final bool busy;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            TextButton(
              onPressed: busy ? null : onSecondary,
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: Text(secondaryLabel),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == current ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= current
                            ? _tourBrand
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: busy ? null : onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: _tourBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
