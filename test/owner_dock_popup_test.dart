import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cavaa_cashier/features/owner/presentation/widgets/dock_route_observer.dart';

/// Mirrors the owner shell: a floating dock over a nested section navigator.
class _Shell extends StatefulWidget {
  const _Shell({required this.page});

  final Widget page;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  var sheetOpen = false;
  var popupOpen = false;
  var dockTaps = 0;
  late final observer = DockRouteObserver((sheet, popup) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          sheetOpen = sheet;
          popupOpen = popup;
        });
      }
    });
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: sheetOpen
          ? null
          : DockVisibility(
              hidden: popupOpen,
              child: GestureDetector(
                onTap: () => dockTaps++,
                child: Container(
                  key: const Key('dock'),
                  height: 74,
                  color: Colors.red,
                ),
              ),
            ),
      body: Navigator(
        observers: [observer],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => widget.page),
      ),
    );
  }
}

void main() {
  const screen = Size(360, 760);

  Future<void> pumpShell(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: _Shell(page: page)));
  }

  bool dockHidden(WidgetTester tester) => tester
      .widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byKey(const Key('dock')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      )
      .ignoring;

  testWidgets('dropdown menu hides the dock and stays clear of it', (
    tester,
  ) async {
    final items = [for (var i = 0; i < 30; i++) 'Bahan $i'];
    await pumpShell(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: DropdownButtonFormField<String>(
            items: [
              for (final it in items)
                DropdownMenuItem(value: it, child: Text(it)),
            ],
            onChanged: (_) {},
            hint: const Text('Pilih bahan'),
          ),
        ),
      ),
    );
    final bodyBefore = tester.getSize(find.byType(Navigator).last);
    expect(dockHidden(tester), isFalse);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(dockHidden(tester), isTrue);
    // The dock keeps its layout space, so the page behind doesn't move.
    expect(tester.getSize(find.byType(Navigator).last), bodyBefore);
    expect(tester.getSize(find.byKey(const Key('dock'))).height, 74);

    // Every menu item that is on screen sits above the bottom margin the
    // menu reserves, and the dock is out of the way (slid off + invisible).
    final dockRect = tester.getRect(find.byKey(const Key('dock')));
    expect(dockRect.top, greaterThanOrEqualTo(screen.height - 1));
    var checked = 0;
    for (final it in items) {
      if (find.text(it).evaluate().isEmpty) continue;
      final r = tester.getRect(find.text(it).last);
      if (r.top >= screen.height) continue;
      expect(r.bottom, lessThanOrEqualTo(screen.height));
      checked++;
    }
    expect(checked, greaterThan(5));

    await tester.tap(find.text('Bahan 2').last);
    await tester.pumpAndSettle();
    expect(dockHidden(tester), isFalse);
    final dockAfter = tester.getRect(find.byKey(const Key('dock')));
    expect(dockAfter.bottom, screen.height);
  });

  testWidgets('popup menu hides the dock too', (tester) async {
    await pumpShell(
      tester,
      Scaffold(
        body: Center(
          child: PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'a', child: Text('Ubah')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(dockHidden(tester), isTrue);
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    expect(dockHidden(tester), isFalse);
  });

  testWidgets('bottom sheet still removes the dock', (tester) async {
    await pumpShell(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 200),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock')), findsNothing);
    Navigator.of(tester.element(find.text('buka'))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock')), findsOneWidget);
    expect(dockHidden(tester), isFalse);
  });
}
