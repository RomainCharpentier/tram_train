import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workmanager/workmanager.dart';

import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/trip.dart';
import 'package:train_qil/domain/services/clock_service.dart';
import 'package:train_qil/domain/services/trip_reminder_service.dart';
import 'package:train_qil/domain/services/trip_service.dart';
import 'package:train_qil/env_config.dart';

void main() {
  late FakeScheduler fakeScheduler;
  late MockClockService clock;
  late _TestTripService tripService;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    EnvConfig.apiKey = 'test-key';

    fakeScheduler = FakeScheduler();
    clock = MockClockService(DateTime(2025, 1, 6, 7, 0)); // Lundi 07:00
    tripService = _TestTripService();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    EnvConfig.apiKey = null;
  });

  TripReminderService _buildService() {
    return TripReminderService(
      tripService: tripService,
      clockService: clock,
      scheduler: fakeScheduler,
    );
  }

  test('scheduleTrip planifie une tâche pour un trajet actif', () async {
    final trip = _createTrip();
    final service = _buildService();

    await service.scheduleTrip(trip);

    expect(fakeScheduler.registeredTasks, hasLength(1));
    final task = fakeScheduler.registeredTasks.single;
    expect(task.uniqueName, TripReminderService.uniqueName(trip.id));
    expect(task.taskName, TripReminderService.taskName);
    expect(task.initialDelay, const Duration(minutes: 30));
    expect(task.existingWorkPolicy, ExistingWorkPolicy.replace);
    expect(task.inputData?['tripId'], trip.id);
    expect(
      task.inputData?['departureDateTime'],
      DateTime(2025, 1, 6, 8, 0).toIso8601String(),
    );
  });

  test('scheduleTrip annule la tâche quand les notifications sont désactivées',
      () async {
    final trip = _createTrip(id: 'disabled', notificationsEnabled: false);
    final service = _buildService();

    await service.scheduleTrip(trip);

    expect(fakeScheduler.registeredTasks, isEmpty);
    expect(
      fakeScheduler.cancelledIds,
      contains(TripReminderService.uniqueName(trip.id)),
    );
  });

  test('refreshSchedules planifie seulement les trajets actifs', () async {
    final active = _createTrip(id: 'active');
    final inactive = _createTrip(id: 'inactive', isActive: false);
    final muted = _createTrip(id: 'muted', notificationsEnabled: false);
    tripService.trips = [active, inactive, muted];

    final service = _buildService();
    await service.refreshSchedules();

    expect(
      fakeScheduler.registeredTasks.map((task) => task.uniqueName).toList(),
      contains(TripReminderService.uniqueName(active.id)),
    );
    expect(
      fakeScheduler.cancelledIds,
      containsAll(<String>[
        TripReminderService.uniqueName(inactive.id),
        TripReminderService.uniqueName(muted.id),
      ]),
    );
  });

  test('computeNextDeparture décale à la semaine suivante si nécessaire', () {
    final now = DateTime(2025, 1, 6, 10, 0); // Lundi 10h
    final trip = _createTrip(hour: 8, minute: 0);

    final next = TripReminderService.computeNextDeparture(trip, now);

    expect(next, DateTime(2025, 1, 13, 8, 0));
  });
}

Trip _createTrip({
  String id = 'trip-1',
  DayOfWeek day = DayOfWeek.monday,
  int hour = 8,
  int minute = 0,
  bool isActive = true,
  bool notificationsEnabled = true,
}) {
  return Trip(
    id: id,
    departureStation: const Station(id: 'dep', name: 'Paris'),
    arrivalStation: const Station(id: 'arr', name: 'Lyon'),
    day: day,
    time: TimeOfDay(hour: hour, minute: minute),
    isActive: isActive,
    notificationsEnabled: notificationsEnabled,
    createdAt: DateTime(2025, 1, 1),
  );
}

class _TestTripService extends TripService {
  _TestTripService() : super(_DummyTripStorage());

  List<Trip> trips = const [];

  @override
  Future<List<Trip>> getAllTrips() async => trips;
}

class _DummyTripStorage implements TripStorage {
  @override
  Future<void> clearAllTrips() async {}

  @override
  Future<void> deleteTrip(String tripId) async {}

  @override
  Future<List<Trip>> getAllTrips() async => [];

  @override
  Future<void> saveTrip(Trip trip) async {}
}

class FakeScheduler implements BackgroundTaskScheduler {
  final List<_RegisteredTask> registeredTasks = [];
  final List<String> cancelledIds = [];

  @override
  Future<void> registerOneOffTask({
    required String uniqueName,
    required String taskName,
    required Duration initialDelay,
    ExistingWorkPolicy? existingWorkPolicy,
    Constraints? constraints,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    Map<String, dynamic>? inputData,
  }) async {
    registeredTasks.add(
      _RegisteredTask(
        uniqueName: uniqueName,
        taskName: taskName,
        inputData: inputData,
        initialDelay: initialDelay,
        existingWorkPolicy: existingWorkPolicy,
        constraints: constraints,
        backoffPolicy: backoffPolicy,
        backoffPolicyDelay: backoffPolicyDelay,
      ),
    );
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    cancelledIds.add(uniqueName);
  }
}

class _RegisteredTask {
  final String uniqueName;
  final String taskName;
  final Map<String, dynamic>? inputData;
  final Duration? initialDelay;
  final ExistingWorkPolicy? existingWorkPolicy;
  final Constraints? constraints;
  final BackoffPolicy? backoffPolicy;
  final Duration? backoffPolicyDelay;

  _RegisteredTask({
    required this.uniqueName,
    required this.taskName,
    required this.inputData,
    required this.initialDelay,
    required this.existingWorkPolicy,
    required this.constraints,
    required this.backoffPolicy,
    required this.backoffPolicyDelay,
  });
}
