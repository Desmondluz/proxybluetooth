import 'dart:async'; // Pour gérer les StreamSubscription et futures
import 'package:flutter_bloc/flutter_bloc.dart'; // Pour le pattern BLoC
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Pour le Bluetooth
import 'package:equatable/equatable.dart'; // Pour simplifier la comparaison des objets

/// --- EVENTS ---
// Événements déclenchés pour contrôler le BLoC Bluetooth

// Classe abstraite de base pour tous les événements Bluetooth
abstract class BluetoothEvent extends Equatable {
  @override
  List<Object?> get props => []; // Pas de propriété dans la base
}

// Événement pour démarrer le scan Bluetooth
class StartScan extends BluetoothEvent {}

// Événement pour arrêter le scan Bluetooth
class StopScan extends BluetoothEvent {}

/// --- STATES ---
// États possibles du BLoC Bluetooth

// Classe abstraite de base pour tous les états Bluetooth
abstract class BluetoothState extends Equatable {
  @override
  List<Object?> get props => []; // Pas de propriété dans la base
}

// État initial (avant le démarrage du scan)
class BluetoothInitial extends BluetoothState {}

// État indiquant que le scan Bluetooth est en cours
class BluetoothScanning extends BluetoothState {}

// État indiquant que le scan a réussi avec la liste des appareils détectés
class BluetoothScanSuccess extends BluetoothState {
  final List<ScanResult> devices; // Liste des appareils détectés

  BluetoothScanSuccess(this.devices);

  @override
  List<Object?> get props => [devices]; // Comparaison sur la liste des appareils
}

// État indiquant qu'une erreur est survenue durant le scan
class BluetoothScanError extends BluetoothState {
  final String message; // Message d'erreur

  BluetoothScanError(this.message);

  @override
  List<Object?> get props => [message]; // Comparaison sur le message d'erreur
}

/// --- BLOC ---
// Logique métier du Bluetooth sous forme de BLoC

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final List<ScanResult> _devices = []; // Stockage interne des appareils détectés
  StreamSubscription<List<ScanResult>>? _scanSubscription; // Abonnement au flux de résultats

  BluetoothBloc() : super(BluetoothInitial()) {
    // Association des événements avec leurs handlers
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
  }

  // Gestion du démarrage du scan
  Future<void> _onStartScan(StartScan event, Emitter<BluetoothState> emit) async {
    try {
      _devices.clear(); // Réinitialisation de la liste des appareils
      emit(BluetoothScanning()); // Émettre l'état scanning

      // Démarrer le scan Bluetooth avec un timeout de 10 secondes
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // S'abonner au flux des résultats du scan
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _devices
          ..clear() // On vide la liste
          ..addAll(results); // On ajoute les nouveaux résultats
        emit(BluetoothScanSuccess(List<ScanResult>.from(_devices))); // Émettre la liste actualisée
      });

      // Dès que le scan s'arrête (isScanning devient false), on déclenche l'arrêt du scan
      FlutterBluePlus.isScanning.where((isScanning) => !isScanning).first.then((_) {
        add(StopScan());
      });
    } catch (e) {
      // En cas d'erreur, on émet un état d'erreur avec message
      emit(BluetoothScanError('Erreur lors du scan : $e'));
    }
  }

  // Gestion de l'arrêt du scan
  Future<void> _onStopScan(StopScan event, Emitter<BluetoothState> emit) async {
    try {
      await FlutterBluePlus.stopScan(); // Arrêter le scan
      await _scanSubscription?.cancel(); // Annuler l'abonnement au flux
      _scanSubscription = null; // Nettoyer la référence
      emit(BluetoothScanSuccess(List<ScanResult>.from(_devices))); // Émettre la liste finale
    } catch (e) {
      // En cas d'erreur, émettre l'état d'erreur
      emit(BluetoothScanError('Erreur lors de l’arrêt du scan : $e'));
    }
  }

  // Nettoyage à la fermeture du BLoC
  @override
  Future<void> close() {
    _scanSubscription?.cancel(); // Annuler l'abonnement si actif
    return super.close();
  }
}
