import 'dart:async';
import '../data/services/connectivity_service.dart';

class MockConnectivityService implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  MockConnectivityService() {
    _controller.add(true);
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async => true;

  void setConnected(bool connected) {
    _controller.add(connected);
  }

  void dispose() {
    _controller.close();
  }
}
