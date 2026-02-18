import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/features/cashier/data/models/printer_device.dart';

class PrinterPrefs {
  static const _kSavedPrinters = 'saved_printers_v1';
  static const _kDefaultPrinterId = 'default_printer_id_v1';

  Future<List<PrinterDevice>> loadSaved() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kSavedPrinters);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<dynamic>();
      return list
          .whereType<Map>()
          .map((m) => PrinterDevice.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSaved(List<PrinterDevice> printers) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(printers.map((p) => p.toJson()).toList());
    await sp.setString(_kSavedPrinters, raw);
  }

  Future<String?> loadDefaultId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kDefaultPrinterId);
  }

  Future<void> saveDefaultId(String? id) async {
    final sp = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await sp.remove(_kDefaultPrinterId);
    } else {
      await sp.setString(_kDefaultPrinterId, id);
    }
  }
}
