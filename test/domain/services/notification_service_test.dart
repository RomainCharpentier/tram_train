import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/trip.dart';
import 'package:train_qil/domain/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel notificationsAndroidChannel =
      MethodChannel('dexterous.com/flutter/local_notifications_android');
  late List<MethodCall> notificationCalls;

  setUp(() {
    notificationCalls = [];

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (MethodCall call) async {
        notificationCalls.add(call);
        return true;
      },
    );
    messenger.setMockMethodCallHandler(
      notificationsAndroidChannel,
      (MethodCall call) async {
        notificationCalls.add(call);
        return true;
      },
    );

    PermissionHandlerPlatform.instance = _FakePermissionHandler();
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    messenger.setMockMethodCallHandler(notificationsAndroidChannel, null);
  });

  test('notifyDelay triggers local notification', () async {
    final service = NotificationService();
    final trip = _createTrip();

    await service.notifyDelay(trip, 5);

    expect(notificationCalls, isNotEmpty);
  });
}

Trip _createTrip() {
  return Trip(
    id: 'trip',
    departureStation: const Station(id: 'dep', name: 'Paris'),
    arrivalStation: const Station(id: 'arr', name: 'Lyon'),
    day: DayOfWeek.monday,
    time: const TimeOfDay(hour: 8, minute: 0),
    createdAt: DateTime.now(),
  );
}

class _FakePermissionHandler extends PermissionHandlerPlatform {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      PermissionStatus.granted;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    return {
      for (final permission in permissions) permission: PermissionStatus.granted
    };
  }
}
