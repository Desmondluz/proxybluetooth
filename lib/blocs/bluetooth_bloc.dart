import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// --- EVENTS ---

abstract class BluetoothEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartScan extends BluetoothEvent {}

class StopScan extends BluetoothEvent {}

class RequestBluetoothPermissions extends BluetoothEvent {}

/// --- STATES ---

abstract class BluetoothState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothPermissionDenied extends BluetoothState {}

class BluetoothPermissionGranted extends BluetoothState {}

class BluetoothScanning extends BluetoothState {}

class BluetoothScanSuccess extends BluetoothState {
  final List<ScanResult> devices;

  BluetoothScanSuccess(this.devices);

  @override
  List<Object?> get props => [devices];
}

class BluetoothScanError extends BluetoothState {
  final String message;

  BluetoothScanError(this.message);

  @override
  List<Object?> get props => [message];
}

/// --- BLOC ---

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final List<ScanResult> _devices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BluetoothBloc() : super(BluetoothInitial()) {
    on<RequestBluetoothPermissions>(_onRequestBluetoothPermissions);
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
  }

  /// --- Demande de permissions ---
  Future<void> _onRequestBluetoothPermissions(
      RequestBluetoothPermissions event, Emitter<BluetoothState> emit) async {
    try {
      if (!Platform.isAndroid) {
        emit(BluetoothPermissionGranted());
        return;
      }

      // Vérifie et demande toutes les permissions nécessaires
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted &&
          statuses[Permission.locationWhenInUse]!.isGranted) {
        emit(BluetoothPermissionGranted());
        add(StartScan()); // Lancer le scan si tout est ok
      } else {
        emit(BluetoothPermissionDenied());
      }
    } catch (e) {
      emit(BluetoothScanError("Erreur lors de la demande de permissions : $e"));
    }
  }

  /// --- Démarrage du scan ---
  Future<void> _onStartScan(
      StartScan event, Emitter<BluetoothState> emit) async {
    try {
      _devices.clear();
      emit(BluetoothScanning());

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _devices
          ..clear()
          ..addAll(results);
        emit(BluetoothScanSuccess(List<ScanResult>.from(_devices)));
      });

      FlutterBluePlus.isScanning
          .where((isScanning) => !isScanning)
          .first
          .then((_) {
        add(StopScan());
      });
    } catch (e) {
      emit(BluetoothScanError('Erreur lors du scan : $e'));
    }
  }

  /// --- Arrêt du scan ---
  Future<void> _onStopScan(StopScan event, Emitter<BluetoothState> emit) async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      emit(BluetoothScanSuccess(List<ScanResult>.from(_devices)));
    } catch (e) {
      emit(BluetoothScanError('Erreur lors de l’arrêt du scan : $e'));
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}
