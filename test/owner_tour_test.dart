import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cavaa_cashier/features/owner/presentation/widgets/owner_tour.dart';

const _safe = EdgeInsets.only(top: 24, bottom: 24);
const _height = 760.0;

/// Rough geometry of the owner home screen at a given width.
List<(OwnerTourTarget, Rect)> _headerTargets(double w) => [
  (
    OwnerTourTarget(
      key: GlobalKey(),
      text: 'Profil & akunmu',
      shape: OwnerTourShape.circle,
      side: OwnerTourSide.above,
      align: OwnerTourAlign.start,
      padding: 4,
    ),
    const Rect.fromLTWH(32, 112, 54, 54),
  ),
  (
    OwnerTourTarget(
      key: GlobalKey(),
      text: 'Poin hadiahmu',
      shape: OwnerTourShape.pill,
      side: OwnerTourSide.right,
      padding: 4,
      gap: 16,
    ),
    const Rect.fromLTWH(32, 174, 170, 22),
  ),
  (
    OwnerTourTarget(
      key: GlobalKey(),
      text: 'Pilih toko yang sedang dikelola',
      align: OwnerTourAlign.start,
      anchor: 0.3,
    ),
    Rect.fromLTWH(32, 230, w - 64, 48),
  ),
];

List<(OwnerTourTarget, Rect)> _dockTargets(double w) {
  const top = _height - 24 - 10 - 64;
  final kasirW = (w - 32 - 11) - 8 - 54 * 3;
  var x = 16 + 7 + kasirW + 8;
  final items = <(OwnerTourTarget, Rect)>[
    (
      OwnerTourTarget(
        key: GlobalKey(),
        text: 'Buka mode kasir',
        shape: OwnerTourShape.pill,
        side: OwnerTourSide.above,
        align: OwnerTourAlign.start,
        anchor: 0.25,
        padding: 3,
      ),
      Rect.fromLTWH(23, top + 7, kasirW, 50),
    ),
  ];
  for (final text in [
    'Kembali ke menu utama',
    'Lihat laporan penjualan',
    'Pengaturan akun',
  ]) {
    items.add((
      OwnerTourTarget(
        key: GlobalKey(),
        text: text,
        shape: OwnerTourShape.circle,
        side: OwnerTourSide.above,
        align: OwnerTourAlign.end,
        padding: 0,
      ),
      Rect.fromLTWH(x, top + 8, 54, 48),
    ));
    x += 54;
  }
  return items;
}

void _expectClean(OwnerTourLayout layout, Size screen) {
  final bounds = Rect.fromLTRB(
    0,
    _safe.top,
    screen.width,
    screen.height - _safe.bottom,
  );
  for (var i = 0; i < layout.spots.length; i++) {
    final box = layout.spots[i].box;
    expect(
      bounds.contains(box.topLeft) && bounds.contains(box.bottomRight),
      isTrue,
      reason: 'box $i $box off screen',
    );
    for (var j = 0; j < layout.spots.length; j++) {
      final other = layout.spots[j];
      if (i != j) {
        expect(
          box.overlaps(other.box),
          isFalse,
          reason: 'box $i overlaps box $j',
        );
      }
      expect(
        box.overlaps(other.hole.outerRect),
        isFalse,
        reason: 'box $i covers highlight $j',
      );
    }
    // A pointer line must not run through someone else's box.
    for (final metric in layout.spots[i].line.computeMetrics()) {
      for (var d = 0.0; d < metric.length - 2; d += 2) {
        final p = metric.getTangentForOffset(d)!.position;
        for (var j = 0; j < layout.spots.length; j++) {
          if (j == i) continue;
          expect(
            layout.spots[j].box.deflate(1).contains(p),
            isFalse,
            reason: 'line $i crosses box $j',
          );
        }
      }
    }
  }
}

void main() {
  for (final w in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3]) {
      test('tour layout fits at ${w}dp, text x$scale', () {
        final screen = Size(w, _height);
        for (final targets in [_headerTargets(w), _dockTargets(w)]) {
          final layout = OwnerTourLayout.compute(
            targets: targets,
            screen: screen,
            safe: _safe,
            textScaler: TextScaler.linear(scale),
          );
          expect(layout.spots, hasLength(targets.length));
          _expectClean(layout, screen);
        }
      });
    }
  }

  testWidgets('captions render fully inside their measured boxes', (
    tester,
  ) async {
    const texts = [
      'Panel menu: semua pengelolaan toko ada di sini',
      'Pilih toko yang sedang dikelola',
      'Lengkapi produk, pembayaran, meja & pegawai',
      'Kembali ke menu utama',
      'Lihat laporan penjualan',
      'Profil & akunmu',
    ];
    for (final scale in [1.0, 1.3]) {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final style = OwnerTourLayout.resolveStyle(ctx);
      for (final text in texts) {
        final layout = OwnerTourLayout.compute(
          targets: [
            (
              OwnerTourTarget(key: GlobalKey(), text: text),
              const Rect.fromLTWH(40, 200, 200, 40),
            ),
          ],
          screen: const Size(360, 760),
          safe: _safe,
          textScaler: TextScaler.linear(scale),
          style: style,
        );
        final box = layout.boxes.single;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: box.width - OwnerTourLayout.boxPadding.horizontal,
                  child: DefaultTextStyle(
                    style: style,
                    child: Text(
                      text,
                      key: const Key('t'),
                      textWidthBasis: TextWidthBasis.longestLine,
                      textScaler: TextScaler.linear(scale),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final rendered = tester.getSize(find.byKey(const Key('t')));
        expect(
          rendered.height,
          lessThanOrEqualTo(
            box.height - OwnerTourLayout.boxPadding.vertical + 0.5,
          ),
          reason: '"$text" at x$scale needs more lines than measured',
        );
      }
    }
  });

  testWidgets('scrollTargetIntoView builds and reveals a far-off lazy item', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final target = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(
                  key: i == 35 ? target : null,
                  height: 120,
                  child: Text('item $i'),
                ),
            ],
          ),
        ),
      ),
    );

    // Far below the first screen: not built yet.
    expect(target.currentContext, isNull);

    final done = scrollTargetIntoView(controller, target);
    await tester.pumpAndSettle();
    await done;

    expect(target.currentContext, isNotNull);
    final rect = tester.getRect(find.byKey(target));
    final screen = tester.getRect(find.byType(ListView));
    expect(rect.top, greaterThanOrEqualTo(screen.top));
    expect(rect.bottom, lessThanOrEqualTo(screen.bottom));
  });

  testWidgets('a step behind beforeShow counts as upcoming', (tester) async {
    final a = GlobalKey();
    final lazy = GlobalKey();
    var showLazy = false;
    OwnerTourResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 120),
                Container(key: a, width: 80, height: 40, color: Colors.red),
                const SizedBox(height: 120),
                if (showLazy)
                  Container(key: lazy, width: 80, height: 40, color: Colors.blue),
                TextButton(
                  onPressed: () async {
                    result = await showOwnerTour(context, [
                      OwnerTourStep(
                        targets: [OwnerTourTarget(key: a, text: 'Satu')],
                      ),
                      OwnerTourStep(
                        // Like scrolling a lazy list: the target only
                        // exists once this has run.
                        beforeShow: () async => setState(() => showLazy = true),
                        primaryLabel: 'Selesai',
                        targets: [OwnerTourTarget(key: lazy, text: 'Dua')],
                      ),
                    ]);
                  },
                  child: const Text('mulai'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Satu'), findsOneWidget);

    // Not the last step even though "Dua" isn't built yet.
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Dua'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(result, OwnerTourResult.finished);
  });

  testWidgets('steps advance, missing targets are skipped', (tester) async {
    final a = GlobalKey();
    final b = GlobalKey();
    final missing = GlobalKey();
    OwnerTourResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const SizedBox(height: 120),
                Container(key: a, width: 80, height: 40, color: Colors.red),
                const SizedBox(height: 200),
                Container(key: b, width: 80, height: 40, color: Colors.blue),
                TextButton(
                  onPressed: () async {
                    result = await showOwnerTour(context, [
                      OwnerTourStep(
                        targets: [
                          OwnerTourTarget(key: a, text: 'Satu'),
                          OwnerTourTarget(key: missing, text: 'Hilang'),
                        ],
                      ),
                      OwnerTourStep(
                        targets: [OwnerTourTarget(key: missing, text: 'X')],
                      ),
                      OwnerTourStep(
                        primaryLabel: 'Selesai',
                        secondaryLabel: 'Nanti',
                        targets: [OwnerTourTarget(key: b, text: 'Dua')],
                      ),
                    ]);
                  },
                  child: const Text('mulai'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Satu'), findsOneWidget);
    expect(find.text('Hilang'), findsNothing);

    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();
    // Step 2 has nothing on screen, so it jumps straight to step 3.
    expect(find.text('Dua'), findsOneWidget);
    expect(find.text('Nanti'), findsOneWidget);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(result, OwnerTourResult.finished);
    expect(find.text('Dua'), findsNothing);
  });
}
