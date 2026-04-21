import 'package:flutter/foundation.dart';

class AppUpdateProvider extends ChangeNotifier {
  Map<String, dynamic>? _data;

  Map<String, dynamic>? get data => _data;
  bool get hasUpdate => _data?['update_available'] == true;

  void setUpdate(Map<String, dynamic>? data) {
    if (mapEquals(_data, data)) return;

    _data = data;
    notifyListeners();
  }

  void clear() => setUpdate(null);
}
