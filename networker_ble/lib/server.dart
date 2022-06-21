import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:networker/networker.dart';
import 'package:quick_blue/quick_blue.dart';

class BleServer extends NetworkingServer {
  final String appService, characteristic;

  @override
  final List<NetworkingServerConnection> clients = [];

  BleServer(this.appService, this.characteristic);

  @override
  String get identifier => '';

  @override
  FutureOr<bool> isConnected() {
    return QuickBlue.isBluetoothAvailable();
  }

  @override
  FutureOr<void> start() {
    QuickBlue.setConnectionHandler(_handleConnection);
  }

  @override
  FutureOr<void> stop() {
    QuickBlue.setConnectionHandler(null);
  }

  void _handleConnection(String deviceId, BlueConnectionState state) {
    if (state == BlueConnectionState.connected) {
      final connection = BleServerConnection(this, appService, characteristic, deviceId);
      clients.add(connection);
      
    } else {
      clients.removeWhere((c) => c.identifier == deviceId);
    }
  }
}

class BleServerConnection extends NetworkingServerConnection {
  final String appService, characteristic;
  BleServerConnection(super.server, this.appService, this.characteristic, this.identifier);

  @override
  Future<bool> isConnected() => QuickBlue.isBluetoothAvailable();

  @override
  FutureOr<void> send(
      {required String service, required String event, required String data}) {
        QuickBlue.writeValue(identifier, appService, characteristic, Uint8List.fromList(utf8.encode(data)), BleOutputProperty.withoutResponse)
  }

  @override
  FutureOr<void> start() {
    QuickBlue.setValueHandler((deviceId, characteristicId, value) {
      if (identifier == deviceId) {
        handle(utf8.decode(value));
      }
    });
  }

  @override
  FutureOr<void> stop() {
    QuickBlue.setValueHandler(null);
  }

  @override
  final String identifier;
}
