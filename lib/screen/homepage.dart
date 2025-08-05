//Ici je présente la page d'accueil de l'application

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/bluetooth_bloc.dart';
import '../widgets/bluetooth_device_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = BlocProvider.of<BluetoothBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Bluetooth'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text("Démarrer"),
                onPressed: () {
                  bluetoothBloc.add(StartScan());
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text("Arrêter"),
                onPressed: () {
                  bluetoothBloc.add(StopScan());
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<BluetoothBloc, BluetoothState>(
              builder: (context, state) {
                if (state is BluetoothScanning) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BluetoothScanSuccess) {
                  if (state.devices.isEmpty) {
                    return const Center(child: Text('Aucun appareil trouvé.'));
                  }
                  return ListView.builder(
                    itemCount: state.devices.length,
                    itemBuilder: (context, index) {
                      return BluetoothDeviceTile(result: state.devices[index]);
                    },
                  );
                } else if (state is BluetoothScanError) {
                  return Center(child: Text('Erreur : ${state.message}'));
                }
                return const Center(child: Text('Appuyez sur "Démarrer" pour scanner.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
