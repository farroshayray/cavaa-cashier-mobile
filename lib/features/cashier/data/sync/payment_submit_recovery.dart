import 'dart:async';

import 'package:dio/dio.dart';

import '/features/cashier/presentation/utils/order_edit_utils.dart';

/// Outcome of checking server state after a payment submit timeout/error.
class PaymentRecoveryResult {
  const PaymentRecoveryResult({
    required this.succeeded,
    this.ambiguous = false,
    this.orderDetail,
    this.message,
  });

  final bool succeeded;
  final bool ambiguous;
  final Map<String, dynamic>? orderDetail;
  final String? message;
}

/// True when the client gave up waiting but the server may still have applied pay.
bool isPaymentSubmitTimeout(Object error) {
  if (error is TimeoutException) return true;
  if (error is DioException) {
    return error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }
  return false;
}

/// Whether server order detail reflects a completed payment.
bool isPaymentCompletedOnServer(Map<String, dynamic> detail) {
  final status = (detail['order_status'] ?? '').toString().toUpperCase();
  const postPayStatuses = {'PAID', 'SERVED', 'PROCESSED'};
  if (!postPayStatuses.contains(status)) return false;

  if (_isTruthy(detail['payment_flag'])) return true;

  final latest = detail['latest_payment'];
  if (latest is Map) {
    final payStatus =
        (latest['payment_status'] ?? '').toString().toUpperCase();
    if (payStatus == 'PAID') return true;
  }

  if (status == 'PAID') return true;
  if (status == 'SERVED' && isOpenBillOrder(detail)) return true;
  if (status == 'PROCESSED' && _isTruthy(detail['payment_flag'])) return true;

  return false;
}

bool _isTruthy(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == '1' || v == 'true';
  }
  return false;
}

/// After payment-order timeout, read server detail — do not resubmit payment.
Future<PaymentRecoveryResult> recoverPaymentAfterSubmitFailure({
  required Future<Map<String, dynamic>> Function(int serverId) fetchOrderDetail,
  required int serverId,
}) async {
  try {
    final detail = await fetchOrderDetail(serverId);
    if (isPaymentCompletedOnServer(detail)) {
      return PaymentRecoveryResult(
        succeeded: true,
        orderDetail: detail,
      );
    }
    return const PaymentRecoveryResult(
      succeeded: false,
      ambiguous: false,
      message:
          'Koneksi lambat — cek tab order sebelum mencoba bayar lagi.',
    );
  } catch (_) {
    return const PaymentRecoveryResult(
      succeeded: false,
      ambiguous: true,
      message:
          'Tidak dapat memverifikasi status pembayaran. Cek tab order sebelum mencoba lagi.',
    );
  }
}
