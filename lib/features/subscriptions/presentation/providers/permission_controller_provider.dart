import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';

class PermissionController {
  PermissionController(this._ref);

  final Ref _ref;

  Future<bool> requestNotificationInContext() async {
    final ns = _ref.read(notificationServiceProvider);
    return ns.requestPermissionsIfNeeded(inContext: true);
  }

  Future<bool> areGranted() async {
    final ns = _ref.read(notificationServiceProvider);
    try {
      return (await ns.pendingRequests()).isNotEmpty;
    } catch (_) {
      return true;
    }
  }
}

final permissionControllerProvider = Provider<PermissionController>(
  PermissionController.new,
);
