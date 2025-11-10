import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/models/notification_pause.dart';
import 'package:train_qil/domain/services/notification_pause_service.dart';

void main() {
  late InMemoryNotificationPauseStorage storage;
  late NotificationPauseService service;

  setUp(() {
    storage = InMemoryNotificationPauseStorage();
    service = NotificationPauseService(storage: storage);
  });

  test('createNotificationPause persists a new active pause', () async {
    final now = DateTime.now();
    final pause = await service.createNotificationPause(
      name: 'Test',
      startDate: now,
      endDate: now.add(const Duration(hours: 2)),
    );

    expect(pause.name, 'Test');
    expect(await storage.getAllNotificationPauses(), contains(pause));
  });

  test('getActiveNotificationPauses filters by current time', () async {
    final now = DateTime.now();
    final active = NotificationPause(
      id: 'active',
      name: 'Active',
      startDate: now.subtract(const Duration(hours: 1)),
      endDate: now.add(const Duration(hours: 1)),
      isActive: true,
      createdAt: now,
    );
    final past = active.copyWith(
      id: 'past',
      startDate: now.subtract(const Duration(hours: 3)),
      endDate: now.subtract(const Duration(hours: 2)),
    );

    await storage.saveNotificationPause(active);
    await storage.saveNotificationPause(past);

    final activePauses = await service.getActiveNotificationPauses();

    expect(activePauses, [active]);
    expect(await service.areNotificationsPaused(), isTrue);
  });

  test('getUpcomingNotificationPauses returns pauses in the future', () async {
    final now = DateTime.now();
    final upcoming = NotificationPause(
      id: 'future',
      name: 'Future',
      startDate: now.add(const Duration(hours: 2)),
      endDate: now.add(const Duration(hours: 3)),
      isActive: true,
      createdAt: now,
    );
    await storage.saveNotificationPause(upcoming);

    final upcomingPauses = await service.getUpcomingNotificationPauses();
    expect(upcomingPauses, [upcoming]);
  });

  test('getPastNotificationPauses returns pauses in the past', () async {
    final now = DateTime.now();
    final past = NotificationPause(
      id: 'past',
      name: 'Past',
      startDate: now.subtract(const Duration(hours: 3)),
      endDate: now.subtract(const Duration(hours: 2)),
      isActive: true,
      createdAt: now,
    );
    await storage.saveNotificationPause(past);

    final pastPauses = await service.getPastNotificationPauses();
    expect(pastPauses, [past]);
  });
}

class InMemoryNotificationPauseStorage implements NotificationPauseStorage {
  final List<NotificationPause> _pauses = [];

  @override
  Future<void> deleteNotificationPause(String pauseId) async {
    _pauses.removeWhere((pause) => pause.id == pauseId);
  }

  @override
  Future<List<NotificationPause>> getAllNotificationPauses() async =>
      List.unmodifiable(_pauses);

  @override
  Future<void> saveNotificationPause(NotificationPause pause) async {
    _pauses.removeWhere((existing) => existing.id == pause.id);
    _pauses.add(pause);
  }
}
