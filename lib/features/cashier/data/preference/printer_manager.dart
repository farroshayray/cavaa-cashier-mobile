import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../models/printer_device.dart';
import 'printer_prefs.dart';
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrinterManager extends ChangeNotifier {
  PrinterManager(this.prefs);

  final PrinterPrefs prefs;

  List<PrinterDevice> saved = [];
  String? defaultId;

  List<PrinterDevice> discoveredBt = [];
  List<PrinterDevice> discoveredUsb = [];

  bool scanningBt = false;
  bool scanningUsb = false;

  // ===== INIT (load dari local storage) =====
  Future<void> init() async {
    saved = await prefs.loadSaved();
    defaultId = await prefs.loadDefaultId();
    notifyListeners();
  }

  // ===== BLUETOOTH =====

  /// Scan device bluetooth (bonded + discovery)
  Future<void> scanBluetooth() async {
    await ensureBluetoothOn();
    await ensureBtScanPermissions();
    scanningBt = true;
    notifyListeners();

    try {
      final List<PrinterDevice> results = [];

      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (final d in bonded) {
        final addr = d.address;
        results.add(PrinterDevice(
          id: 'bt:$addr',
          name: d.name ?? 'Bluetooth Device',
          type: PrinterType.bluetooth,
          address: addr,
        ));
      }

      await FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        final d = r.device;
        final addr = d.address;
        final exists = results.any((x) => x.id == 'bt:$addr');
        if (!exists) {
          results.add(PrinterDevice(
            id: 'bt:$addr',
            name: d.name ?? 'Bluetooth Device',
            type: PrinterType.bluetooth,
            address: addr,
          ));
          discoveredBt = List.of(results);
          notifyListeners();
        }
      }).asFuture();

      discoveredBt = results;
    } finally {
      scanningBt = false;
      notifyListeners();
    }
  }


  /// Pair (bond) bluetooth device jika belum bonded, lalu simpan ke saved
  Future<void> pairAndSaveBluetooth(PrinterDevice p) async {
    if (p.address == null) throw Exception('Bluetooth address kosong');

    final addr = p.address!;

    // Bond / Pair ke device (akan munculkan dialog pairing OS)
    final bonded = await FlutterBluetoothSerial.instance
        .bondDeviceAtAddress(addr);

    if (bonded != true) {
      throw Exception('Pairing gagal atau dibatalkan');
    }

    await _savePrinter(p);
  }

  // ===== USB =====
  Future<void> scanUsb() async {
    scanningUsb = true;
    notifyListeners();

    final devices = await UsbSerial.listDevices();
    discoveredUsb = devices.map((d) {
      final vid = d.vid;
      final pid = d.pid;
      final name = d.productName ?? d.manufacturerName ?? 'USB Device';
      return PrinterDevice(
        id: 'usb:$vid:$pid',
        name: name,
        type: PrinterType.usb,
        vendorId: vid,
        productId: pid,
      );
    }).toList();

    scanningUsb = false;
    notifyListeners();
  }

  /// Untuk USB tidak ada "pairing" seperti BT. Yang dilakukan: minta permission + pastikan device bisa dibuka.
  Future<void> pairAndSaveUsb(PrinterDevice p) async {
    final vid = p.vendorId;
    final pid = p.productId;
    if (vid == null || pid == null) throw Exception('USB vid/pid kosong');

    final devices = await UsbSerial.listDevices();
    final target = devices.firstWhere(
      (d) => d.vid == vid && d.pid == pid,
      orElse: () => throw Exception('USB device tidak ditemukan (coba scan ulang)'),
    );

    final port = await target.create();
    if (port == null) throw Exception('Gagal membuat USB port');

    final openOk = await port.open();
    if (openOk != true) {
      // biasanya ini terjadi kalau permission belum ada / device tidak support
      throw Exception('Gagal membuka USB port (cek permission / OTG / daya printer)');
    }

    // optional: set parameter port (sebagian printer butuh ini)
    try {
      // kalau method ini tidak ada di versi kamu, hapus saja blok try ini
      await port.setDTR(true);
      await port.setRTS(true);
    } catch (_) {}

    await port.close();

    await _savePrinter(p);
  }



  // ===== SAVE / DEFAULT / REMOVE =====
  Future<void> _savePrinter(PrinterDevice p) async {
    final exists = saved.any((x) => x.id == p.id);
    if (!exists) {
      saved = [p, ...saved];
      await prefs.saveSaved(saved);
    }

    defaultId ??= p.id;
    await prefs.saveDefaultId(defaultId);

    notifyListeners();
  }

  Future<void> setDefault(String id) async {
    defaultId = id;
    await prefs.saveDefaultId(defaultId);
    notifyListeners();
  }

  Future<void> removeSaved(String id) async {
    saved = saved.where((x) => x.id != id).toList();
    await prefs.saveSaved(saved);

    if (defaultId == id) {
      defaultId = null;
      await prefs.saveDefaultId(null);
    }

    notifyListeners();
  }

  PrinterDevice? get defaultPrinter {
    if (defaultId == null) return null;
    for (final p in saved) {
      if (p.id == defaultId) return p;
    }
    return null;
  }


  // ===== TEST PRINT (placeholder koneksi) =====
  Future<void> testPrint() async {
    final p = defaultPrinter;
    if (p == null) throw Exception('Default printer belum dipilih');

    debugPrint('DEFAULT PRINTER => type=${p.type} id=${p.id} name=${p.name} address=${p.address} vid=${p.vendorId} pid=${p.productId}');

    final bytes = await _buildTestTicket();

    if (p.type == PrinterType.bluetooth) {
      await _printBluetooth(p, bytes);
    } else {
      await _printUsb(p, bytes);
    }
  }


  Future<void> ensureBluetoothOn() async {
  final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!isEnabled) {
      final ok = await FlutterBluetoothSerial.instance.requestEnable();
      if (ok != true) {
        throw Exception('Bluetooth belum diaktifkan');
      }
    }
  }

  Future<void> ensureBtScanPermissions() async {
    // Android 12+ = BLUETOOTH_SCAN & CONNECT
    // Android 11- = Location untuk scan
    if (!Platform.isAndroid) return;

    // Android 12+:
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    if (!scan.isGranted) {
      throw Exception('Izin Bluetooth Scan ditolak');
    }
    if (!connect.isGranted) {
      throw Exception('Izin Bluetooth Connect ditolak');
    }

    // Untuk device Android lama, kadang tetap butuh lokasi:
    final loc = await Permission.locationWhenInUse.request();
    // Jangan hard fail kalau loc ditolak di Android 12+ (karena sudah tidak wajib),
    // tapi untuk Android lama bisa penting.
  }

  Future<List<int>> _buildTestTicket() async {
    // RAW paling sederhana (ASCII) untuk memastikan koneksi + write OK
    final s = 'TEST PRINT\nRPP02N\nOK\n\n\n';
    return Uint8List.fromList(s.codeUnits);
  }


  Future<void> _printBluetooth(PrinterDevice p, List<int> bytes) async {
    await ensureBluetoothOn();
    await ensureBtScanPermissions();

    final addr = p.address;
    if (addr == null || addr.isEmpty) {
      throw Exception('Bluetooth address kosong');
    }

    BluetoothConnection? conn;
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      final isBonded = bonded.any((d) => d.address == addr);
      if (!isBonded) {
        throw Exception('Printer belum paired di sistem. Pair dulu lalu coba lagi.');
      }
      conn = await BluetoothConnection.toAddress(addr);

      conn.output.add(Uint8List.fromList(bytes));
      await conn.output.allSent;

      // beberapa printer butuh delay sedikit sebelum close
      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
      try {
        await conn?.close();
      } catch (_) {}
    }
  }

  Future<void> _printUsb(PrinterDevice p, List<int> bytes) async {
    final vid = p.vendorId;
    final pid = p.productId;
    if (vid == null || pid == null) throw Exception('USB vid/pid kosong');

    final devices = await UsbSerial.listDevices();
    final target = devices.firstWhere(
      (d) => d.vid == vid && d.pid == pid,
      orElse: () => throw Exception('USB device tidak ditemukan (coba scan ulang)'),
    );

    final port = await target.create();
    if (port == null) throw Exception('Gagal membuat USB port');

    final openOk = await port.open();
    if (openOk != true) throw Exception('Gagal membuka USB port');

    // banyak printer butuh setting ini
    try {
      await port.setDTR(true);
      await port.setRTS(true);
    } catch (_) {}

    // set port parameters (opsional, tapi sering membantu)
    try {
      await port.setPortParameters(9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
    } catch (_) {}

    await port.write(Uint8List.fromList(bytes));

    await Future.delayed(const Duration(milliseconds: 200));
    await port.close();
  }


}

