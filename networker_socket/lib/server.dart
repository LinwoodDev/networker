import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:networker/networker.dart';

class SocketServer extends NetworkingServer {
  final int port;
  HttpServer? _server;

  @override
  String get identifier => port.toString();

  final List<SocketServerConnection> _clients = [];

  SocketServer(this.port);

  @override
  FutureOr<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server?.listen((request) {
      final identifier = request.session.id;
      WebSocketTransformer.upgrade(request).then((ws) {
        _clients.add(SocketServerConnection(this, ws, identifier));
        ws.listen((data) {
          final message = json.decode(data);
          if (message is! Map) {
            ws.close(WebSocketStatus.protocolError);
            return;
          }
          handleData(identifier, message);
        });
      });
    });
  }

  @override
  void stop() {
    _server?.close();
    _server = null;
  }

  @override
  bool isConnected() {
    return _server != null;
  }

  @override
  List<NetworkingServerConnection> get clients => List.unmodifiable(_clients);
}

class SocketServerConnection extends NetworkingServerConnection {
  final WebSocket _socket;
  @override
  final String identifier;

  SocketServerConnection(super.server, this._socket, this.identifier);

  @override
  bool isConnected() => _socket.readyState == WebSocket.open;

  @override
  FutureOr<void> start() {}

  @override
  FutureOr<void> stop() => _socket.close();

  @override
  FutureOr<void> send(
      {required String service,
      required String event,
      required String data}) async {
    _socket
        .add(json.encode({'service': service, 'data': data, 'event': event}));
    await _socket.done;
  }
}
