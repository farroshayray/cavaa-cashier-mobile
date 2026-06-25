import 'package:flutter/material.dart';

import 'receipt_actions_bottom_sheet.dart';

class ReceiptActionIconButton extends StatelessWidget {
  const ReceiptActionIconButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onPrint,
    required this.onShare,
    this.compact = false,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 24.0;
    final spinnerSize = compact ? 18.0 : 20.0;

    return IconButton(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      constraints: compact
          ? const BoxConstraints(minWidth: 36, minHeight: 36)
          : null,
      onPressed: (isLoading || !enabled)
          ? null
          : () async {
              final action = await showReceiptActionsSheet(context);
              if (action == null) return;
              switch (action) {
                case ReceiptAction.print:
                  onPrint();
                case ReceiptAction.share:
                  onShare();
              }
            },
      icon: isLoading
          ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.receipt_long_outlined, size: iconSize),
      tooltip: 'Struk',
    );
  }
}
