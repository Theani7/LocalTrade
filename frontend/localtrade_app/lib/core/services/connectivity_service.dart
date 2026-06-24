import 'package:flutter/foundation.dart';

enum ConnectionStatus { connected, connecting, reconnected }

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final ValueNotifier<ConnectionStatus> statusNotifier =
      ValueNotifier(ConnectionStatus.connected);

  bool _dismissScheduled = false;

  void onApiSuccess() {
    if (statusNotifier.value == ConnectionStatus.connecting) {
      statusNotifier.value = ConnectionStatus.reconnected;
      if (!_dismissScheduled) {
        _dismissScheduled = true;
        Future.delayed(const Duration(seconds: 1), () {
          _dismissScheduled = false;
          statusNotifier.value = ConnectionStatus.connected;
        });
      }
    } else if (statusNotifier.value != ConnectionStatus.reconnected) {
      statusNotifier.value = ConnectionStatus.connected;
    }
  }

  void onApiError() {
    if (statusNotifier.value != ConnectionStatus.connecting) {
      statusNotifier.value = ConnectionStatus.connecting;
    }
  }

  void dispose() {
    statusNotifier.dispose();
  }
}
