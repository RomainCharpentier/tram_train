import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'clock_service.dart';
import 'trip_service.dart';
import '../models/trip.dart';
import '../../env_config.dart';

class TripReminderService {
  static const String taskName = 'trip_status_check';
  static const String _taskPrefix = 'trip_status_';
  static const Duration defaultLeadTime = Duration(minutes: 30);

  final TripService _tripService;
  final ClockService _clockService;
  final Workmanager _workmanager;

  TripReminderService({
    required TripService tripService,
    required ClockService clockService,
    Workmanager? workmanager,
  })  : _tripService = tripService,
        _clockService = clockService,
        _workmanager = workmanager ?? Workmanager();

  static String uniqueName(String tripId) => '$_taskPrefix$tripId';

  bool get _isWorkmanagerAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasValidApiKey => (EnvConfig.apiKey?.trim().isNotEmpty ?? false);

  Future<void> refreshSchedules({Duration leadTime = defaultLeadTime}) async {
    if (!_isWorkmanagerAvailable) {
      debugPrint('⏭️ Workmanager indisponible sur cette plateforme');
      return;
    }
    if (!_hasValidApiKey) {
      debugPrint('⏭️ API SNCF manquante, annulation de la planification');
      return;
    }
    final trips = await _tripService.getAllTrips();
    for (final trip in trips) {
      if (trip.isActive && trip.notificationsEnabled) {
        await scheduleTrip(trip, leadTime: leadTime);
      } else {
        await cancelTrip(trip.id);
      }
    }
  }

  Future<void> scheduleTrip(
    Trip trip, {
    Duration leadTime = defaultLeadTime,
  }) async {
    if (!_isWorkmanagerAvailable) {
      debugPrint('⏭️ Ignoré: Workmanager indisponible sur cette plateforme');
      return;
    }
    if (!_hasValidApiKey) {
      debugPrint(
          '⏭️ Ignoré: API SNCF absente, impossible de planifier ${trip.id}');
      await cancelTrip(trip.id);
      return;
    }
    if (!trip.isActive || !trip.notificationsEnabled) {
      await cancelTrip(trip.id);
      return;
    }

    final now = _clockService.now();
    final nextDeparture = computeNextDeparture(trip, now);
    if (nextDeparture == null) {
      debugPrint(
          '⚠️ Impossible de calculer la prochaine occurrence pour ${trip.id}');
      await cancelTrip(trip.id);
      return;
    }

    final candidateTrigger = nextDeparture.subtract(leadTime);
    final triggerTime = candidateTrigger.isBefore(now)
        ? now.add(const Duration(seconds: 10))
        : candidateTrigger;

    final delay = triggerTime.difference(now);

    await _workmanager.registerOneOffTask(
      uniqueName(trip.id),
      taskName,
      inputData: {
        'tripId': trip.id,
        'departureStationId': trip.departureStation.id,
        'departureStationName': trip.departureStation.name,
        'arrivalStationId': trip.arrivalStation.id,
        'arrivalStationName': trip.arrivalStation.name,
        'departureDateTime': nextDeparture.toIso8601String(),
        'leadTimeMinutes': leadTime.inMinutes,
        'apiKey': EnvConfig.apiKey,
      },
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
    debugPrint(
      '⏰ Tâche planifiée pour ${trip.description} dans ${delay.inMinutes} min (lead ${leadTime.inMinutes} min)',
    );
  }

  Future<void> cancelTrip(String tripId) async {
    if (!_isWorkmanagerAvailable) {
      return;
    }
    await _workmanager.cancelByUniqueName(uniqueName(tripId));
  }

  static DateTime? computeNextDeparture(Trip trip, DateTime now) {
    final tripWeekday = trip.day.index + 1; // Monday = 1
    final currentWeekday = now.weekday;

    final daysAhead = (tripWeekday - currentWeekday) % 7;
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      trip.time.hour,
      trip.time.minute,
    ).add(Duration(days: daysAhead));

    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }
}
