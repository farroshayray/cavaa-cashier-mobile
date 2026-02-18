enum PrinterType { bluetooth, usb }

class PrinterDevice {
  final String id;       // unique: bt:<mac> | usb:<vid>:<pid>:<name>
  final String name;
  final PrinterType type;

  // Bluetooth
  final String? address; // MAC

  // USB
  final int? vendorId;
  final int? productId;

  const PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.vendorId,
    this.productId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'address': address,
    'vendorId': vendorId,
    'productId': productId,
  };

  factory PrinterDevice.fromJson(Map<String, dynamic> j) => PrinterDevice(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    type: (j['type'] == 'usb') ? PrinterType.usb : PrinterType.bluetooth,
    address: j['address']?.toString(),
    vendorId: j['vendorId'] is int ? j['vendorId'] as int : int.tryParse('${j['vendorId']}'),
    productId: j['productId'] is int ? j['productId'] as int : int.tryParse('${j['productId']}'),
  );
}
