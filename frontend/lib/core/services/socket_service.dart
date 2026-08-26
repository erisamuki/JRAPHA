import 'package:socket_io_client/socket_io_client.dart' as io_client;

/// Thin wrapper around the Socket.IO client. Rather than patching
/// individual pieces of dashboard state per event (visit_created,
/// billing_created, low_stock_alert, etc.), this simply notifies a
/// callback on ANY relevant event so the admin dashboard can just
/// refetch its aggregate snapshot - simpler and less error-prone
/// than manual client-side state merging.
class SocketService {
  io_client.Socket? _socket;

  // Same base as ApiClient, minus the /api suffix (Socket.IO connects
  // to the server root, not a REST path).
  static const String _socketUrl = 'http://localhost:5000';

  void connect({required void Function() onRelevantEvent}) {
    _socket = io_client.io(
      _socketUrl,
      io_client.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket!.connect();

    const relevantEvents = [
      'visit_created',
      'visit_status_changed',
      'user_status_changed',
      'billing_created',
      'payment_recorded',
      'low_stock_alert',
      'lab_order_created',
      'lab_result_ready',
      'prescription_created',
      'prescription_dispensed',
    ];

    for (final event in relevantEvents) {
      _socket!.on(event, (_) => onRelevantEvent());
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
