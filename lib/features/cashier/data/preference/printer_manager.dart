import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/printer_device.dart';
import 'printer_prefs.dart';

enum PrinterConnState { disconnected, connecting, connected, error }

class PrinterManager extends ChangeNotifier {
  PrinterManager(this.prefs);

  final PrinterPrefs prefs;

  List<PrinterDevice> saved = [];
  String? defaultId;

  List<PrinterDevice> discoveredBt = [];
  List<PrinterDevice> discoveredUsb = [];

  bool scanningBt = false;
  bool scanningUsb = false;

  PrinterConnState connState = PrinterConnState.disconnected;
  String? connMessage;
  PrinterDevice? connectedPrinter;

  BluetoothConnection? _btConn;
  UsbPort? _usbPort;

  bool get isReady => connState == PrinterConnState.connected;

  // ===== INIT (load dari local storage) =====
  Future<void> init({bool autoConnect = true}) async {
    saved = await prefs.loadSaved();
    defaultId = await prefs.loadDefaultId();
    notifyListeners();

    if (autoConnect) {
      // jangan throw keras di init, biar app tetap masuk
      unawaited(connectDefault(silent: true));
    }
  }

  PrinterDevice? get defaultPrinter {
    if (defaultId == null) return null;
    return saved.where((p) => p.id == defaultId).cast<PrinterDevice?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );
  }


  Future<void> connectDefault({bool silent = false}) => _runLocked(() async {
    final p = defaultPrinter;
    if (p == null) {
      await _disconnectInternal();
      return;
    }
    await _connectInternal(p, silent: silent);
  });

  Future<void> connect(PrinterDevice p, {bool silent = false}) =>
    _runLocked(() => _connectInternal(p, silent: silent));

  Future<void> disconnect() => _runLocked(() => _disconnectInternal());

  // ===== BLUETOOTH =====
  Future<void> ensureConnected() async {
    if (isReady) return;
    final p = defaultPrinter;
    if (p == null) throw Exception('Default printer belum dipilih');
    await _connectInternal(p, silent: false); // ✅ internal, no lock
  }

  // ===== BLUETOOTH CONNECT =====
  Future<void> _connectBluetooth(PrinterDevice p) async {
    await ensureBluetoothOn();
    await ensureBtScanPermissions();

    final addr = p.address;
    if (addr == null || addr.isEmpty) {
      throw Exception('Bluetooth address kosong');
    }

    // Pastikan sudah bonded (paired) di OS
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    final isBonded = bonded.any((d) => d.address == addr);
    if (!isBonded) {
      throw Exception('Printer belum paired di sistem. Pair dulu lalu coba lagi.');
    }

    // Connect
    _btConn = await BluetoothConnection.toAddress(addr)
        .timeout(const Duration(seconds: 8));

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!(_btConn?.isConnected ?? false)) {
      throw Exception('Bluetooth gagal connect');
    }
  }

  // ===== USB CONNECT =====
  Future<void> _connectUsb(PrinterDevice p) async {
    final vid = p.vendorId;
    final pid = p.productId;
    if (vid == null || pid == null) throw Exception('USB vid/pid kosong');

    final devices = await UsbSerial.listDevices();
    final target = devices.firstWhere(
      (d) => d.vid == vid && d.pid == pid,
      orElse: () => throw Exception('USB device tidak ditemukan (cabut-pasang / scan ulang)'),
    );

    final port = await target.create();
    if (port == null) throw Exception('Gagal membuat USB port');

    final ok = await port.open();
    if (ok != true) throw Exception('Gagal membuka USB port (cek OTG/permission/daya printer)');

    try {
      await port.setDTR(true);
      await port.setRTS(true);
    } catch (_) {}

    // opsional: kalau memang printer kamu butuh baudrate tertentu
    try {
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
    } catch (_) {}

    _usbPort = port;
  }

  Future<void> write(Uint8List bytes) =>
    _runLocked(() async {
      await ensureConnected();

      final p = connectedPrinter;
      if (p == null) throw Exception('Printer belum connected');

      if (p.type == PrinterType.bluetooth) {
        final c = _btConn;
        if (c == null || !c.isConnected) throw Exception('Bluetooth terputus');
        c.output.add(bytes);
        await c.output.allSent.timeout(const Duration(seconds: 8));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } else {
        final port = _usbPort;
        if (port == null) throw Exception('USB port belum siap');
        await port.write(bytes);
      }
  });

    // ===== INTERNAL (NO LOCK) =====
  Future<void> _disconnectInternal() async {
    try {
      _btConn?.finish(); // ✅ penting untuk flutter_bluetooth_serial
    } catch (_) {}
    _btConn = null;

    try {
      await _usbPort?.close();
    } catch (_) {}
    _usbPort = null;

    connState = PrinterConnState.disconnected;
    connMessage = null;
    connectedPrinter = null;
    notifyListeners();
  }

  Future<void> _connectInternal(PrinterDevice p, {required bool silent}) async {
    // kalau sudah connect ke printer yang sama
    if (connectedPrinter?.id == p.id && isReady) return;

    connState = PrinterConnState.connecting;
    connMessage = 'Connecting...';
    notifyListeners();

    try {
      await _disconnectInternal(); // ✅ jangan panggil disconnect() di sini
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (p.type == PrinterType.bluetooth) {
        await _connectBluetooth(p);
      } else {
        await _connectUsb(p);
      }

      connState = PrinterConnState.connected;
      connMessage = 'Connected';
      connectedPrinter = p;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ PRINTER CONNECT ERROR: $e');
      connState = PrinterConnState.error;
      connMessage = e.toString();
      connectedPrinter = null;
      notifyListeners();

      if (!silent) rethrow;
    }
  }

  // ===== PRINT RAW =====


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

    // 1) cek dulu bonded list
    final bondedList = await FlutterBluetoothSerial.instance.getBondedDevices();
    final alreadyBonded = bondedList.any((d) => d.address == addr);

    if (!alreadyBonded) {
      // 2) kalau belum bonded, baru lakukan bond
      try {
        final ok = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(addr);
        if (ok != true) {
          throw Exception('Pairing gagal atau dibatalkan');
        }
      } catch (e) {
        // 3) fallback: kalau plugin lempar "device already bonded", anggap sukses
        final msg = e.toString().toLowerCase();
        if (!msg.contains('already bonded')) rethrow;
      }
    }

    // 4) apapun jalurnya, simpan & jadikan default bila perlu
    await _savePrinter(p);

    // optional: auto connect setelah disimpan
    await _connectInternal(p, silent: false);
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

    // auto connect begitu jadi default
    final p = defaultPrinter;
    if (p != null) {
      unawaited(connect(p, silent: true));
    }
  }

  Future<void> removeSaved(String id) async {
    saved = saved.where((x) => x.id != id).toList();
    await prefs.saveSaved(saved);

    if (defaultId == id) {
      defaultId = null;
      await prefs.saveDefaultId(null);
      await disconnect();
    }
    notifyListeners();
  }

  // ===== TEST PRINT (placeholder koneksi) =====
  Future<void> testPrint() async {
    final bytes = Uint8List.fromList('TEST\n\n\n'.codeUnits);
    await write(bytes);
  }


  Future<void> ensureBluetoothOn() async {
    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!isEnabled) {
      final ok = await FlutterBluetoothSerial.instance.requestEnable();
      if (ok != true) throw Exception('Bluetooth belum diaktifkan');
    }
  }

  Future<void> ensureBtScanPermissions() async {
    if (!Platform.isAndroid) return;

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted) throw Exception('Izin Bluetooth Scan ditolak');
    if (!connect.isGranted) throw Exception('Izin Bluetooth Connect ditolak');

    // device lama kadang butuh lokasi untuk scan
    await Permission.locationWhenInUse.request();
  }

  Future<List<BluetoothDevice>> getBondedBtDevices() {
    return FlutterBluetoothSerial.instance.getBondedDevices(); // :contentReference[oaicite:3]{index=3}
  }

  Future<void> unpairBluetoothAddress(String address) async {
    // API plugin: removeDeviceBondWithAddress :contentReference[oaicite:4]{index=4}
    final ok = await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(address);
    if (ok != true) throw Exception('Unpair gagal / dibatalkan');

    // bersihkan saved kalau ada yang match
    final id = 'bt:$address';
    await removeSaved(id);
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
      try { conn?.finish(); } catch (_) {}
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

  Future<void> _queue = Future.value();

  Future<T> _runLocked<T>(Future<T> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

}

