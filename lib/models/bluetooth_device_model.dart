import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final String id;
  final String name;
  final int rssi;

  BluetoothDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
  });

  // Usine pour créer une instance à partir d’un ScanResult
  factory BluetoothDeviceModel.fromScanResult(ScanResult result) {
    final device = result.device;
    return BluetoothDeviceModel(
      id: device.id.id,
      name: device.name.isNotEmpty ? device.name : 'Appareil inconnu',
      rssi: result.rssi,
    );
  }
}
