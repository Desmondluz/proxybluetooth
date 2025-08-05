import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceTile extends StatelessWidget {
  final ScanResult result;

  const BluetoothDeviceTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final device = result.device;
    return ListTile(
      leading: Icon(Icons.bluetooth),
      title: Text(device.name.isNotEmpty ? device.name : 'Appareil sans nom'),
      subtitle: Text(device.id.id),
      trailing: Text(result.rssi.toString()),
    );
  }
}
