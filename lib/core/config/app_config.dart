class AppConfig {
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Multipart payment-order (bukti bayar) butuh waktu upload + proses server.
  static const Duration paymentMultipartTimeout = Duration(seconds: 90);

  /// Fetch print detail setelah pembayaran — sedikit lebih longgar dari API biasa.
  static const Duration printDetailTimeout = Duration(seconds: 30);
}
