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
