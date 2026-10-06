/// Resolves server payment row id for sync push / proof upload.
int? resolveLastPaymentIdForPush({
  int? latestPaymentServerId,
  int? paymentId,
}) {
  if (latestPaymentServerId != null && latestPaymentServerId > 0) {
    return latestPaymentServerId;
  }
  if (paymentId != null && paymentId > 0) {
    return paymentId;
  }
  return null;
}

/// Payment method for sync push — CREATE open bill must send OPENBILL;
/// pay/catch-up must use the actual payment method, never OPENBILL.
String? paymentMethodForPush({
  required bool openbillFlag,
  required String effectiveIntent,
  required String? storedPaymentMethod,
  required double? paidAmountLocal,
}) {
  if (openbillFlag && effectiveIntent.toUpperCase() == 'CREATE') {
    return 'OPENBILL';
  }

  return checkoutPaymentMethodForPush(
    openbillFlag: openbillFlag,
    storedPaymentMethod: storedPaymentMethod,
    paidAmountLocal: paidAmountLocal,
  );
}

/// Pay/catch-up payment method resolution (excludes CREATE open bill).
String? checkoutPaymentMethodForPush({
  required bool openbillFlag,
  required String? storedPaymentMethod,
  required double? paidAmountLocal,
}) {
  final method = (storedPaymentMethod ?? '').trim();
  if (openbillFlag) {
    if (paidAmountLocal == null) {
      return null;
    }
    if (method.isNotEmpty && method.toUpperCase() != 'OPENBILL') {
      return method;
    }
    return null;
  }
  if (method.isEmpty) return 'CASH';
  return method;
}

/// Resolves payment row id for cashier proof upload.
int? resolvePaymentIdForProofUpload({
  int? appliedPaymentId,
  int? latestPaymentServerId,
  int? paymentId,
  int? fallbackFromOrderPayments,
}) {
  if (appliedPaymentId != null && appliedPaymentId > 0) {
    return appliedPaymentId;
  }

  final fromMirror = resolveLastPaymentIdForPush(
    latestPaymentServerId: latestPaymentServerId,
    paymentId: paymentId,
  );
  if (fromMirror != null && fromMirror > 0) {
    return fromMirror;
  }

  if (fallbackFromOrderPayments != null && fallbackFromOrderPayments > 0) {
    return fallbackFromOrderPayments;
  }

  return null;
}

/// Whether open bill pay push is missing a real payment method.
bool isOpenbillPayMissingPaymentMethod({
  required bool openbillFlag,
  required String effectiveIntent,
  required double? paidAmountLocal,
  required String? pushPaymentMethod,
}) {
  if (!openbillFlag || paidAmountLocal == null) return false;
  if (effectiveIntent.toUpperCase() == 'CREATE') return false;
  return pushPaymentMethod == null;
}
