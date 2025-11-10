import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/train.dart';
import 'package:train_qil/domain/models/trip.dart';
import 'package:train_qil/domain/services/trip_reminder_service.dart';
import 'package:train_qil/infrastructure/gateways/local_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/infrastructure/mappers/trip_mapper.dart';

@pragma('vm:entry-point')
void tripStatusCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName != TripReminderService.taskName) {
      return Future.value(false);
    }

    final data = inputData ?? const <String, dynamic>{};
    final tripId = data['tripId'] as String?;
    final apiKey = (data['apiKey'] as String?)?.trim() ?? '';
    final leadMinutes = data['leadTimeMinutes'] as int? ?? 30;
    final departureIso = data['departureDateTime'] as String?;
    final departureStationId = data['departureStationId'] as String?;
    final arrivalStationId = data['arrivalStationId'] as String?;

    if (tripId == null ||
        apiKey.isEmpty ||
        departureIso == null ||
        departureStationId == null ||
        arrivalStationId == null) {
      debugPrint('❌ Données insuffisantes pour exécuter la tâche $taskName');
      return Future.value(false);
    }

    final departureStationName = data['departureStationName'] as String? ?? '';
    final arrivalStationName = data['arrivalStationName'] as String? ?? '';
    final departureDate = DateTime.tryParse(departureIso);

    if (departureDate == null) {
      debugPrint('❌ Date de départ invalide: $departureIso');
      return Future.value(false);
    }

    final tripMapper = TripMapper();
    final localGateway = LocalStorageGateway(mapper: tripMapper);
    final trips = await localGateway.getAllTrips();

    Trip? storedTrip;
    for (final trip in trips) {
      if (trip.id == tripId) {
        storedTrip = trip;
        break;
      }
    }

    if (storedTrip == null) {
      debugPrint('ℹ️ Trajet $tripId introuvable, annulation de la tâche');
      await Workmanager()
          .cancelByUniqueName(TripReminderService.uniqueName(tripId));
      return Future.value(true);
    }

    if (!storedTrip.isActive || !storedTrip.notificationsEnabled) {
      debugPrint('ℹ️ Trajet $tripId non actif ou notifications désactivées');
      await Workmanager()
          .cancelByUniqueName(TripReminderService.uniqueName(tripId));
      return Future.value(true);
    }

    final departureStation = Station(
      id: storedTrip.departureStation.id,
      name: storedTrip.departureStation.name,
    );
    final arrivalStation = Station(
      id: storedTrip.arrivalStation.id,
      name: storedTrip.arrivalStation.name,
    );

    final client = http.Client();
    final mapper = SncfMapper();
    final gateway =
        SncfGateway(httpClient: client, apiKey: apiKey, mapper: mapper);

    Train? selectedTrain;
    try {
      final trains = await gateway.findJourneysWithDepartureTime(
        departureStation,
        arrivalStation,
        departureDate,
      );
      if (trains.isNotEmpty) {
        selectedTrain = _selectClosestTrain(trains, departureDate);
      }
    } on Object catch (error, stack) {
      debugPrint('❌ Erreur lors de la récupération du statut SNCF: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      client.close();
    }

    final notification = _buildNotificationPayload(
      storedTrip,
      selectedTrain,
      leadMinutes,
      departureStationName.isNotEmpty
          ? departureStationName
          : storedTrip.departureStation.name,
      arrivalStationName.isNotEmpty
          ? arrivalStationName
          : storedTrip.arrivalStation.name,
    );

    await _showNotification(notification.title, notification.body);

    await _scheduleNextRun(
      trip: storedTrip,
      apiKey: apiKey,
      leadMinutes: leadMinutes,
    );

    return Future.value(true);
  });
}

class _NotificationPayload {
  final String title;
  final String body;

  const _NotificationPayload(this.title, this.body);
}

_NotificationPayload _buildNotificationPayload(
  Trip trip,
  Train? train,
  int leadMinutes,
  String departureName,
  String arrivalName,
) {
  const baseTitle = 'Statut de votre trajet';

  if (train == null) {
    return _NotificationPayload(
      baseTitle,
      "Impossible de récupérer le statut pour $departureName → $arrivalName. Vérifiez l'application.",
    );
  }

  switch (train.status) {
    case TrainStatus.cancelled:
      return _NotificationPayload(
        '❌ Train annulé',
        'Le trajet $departureName → $arrivalName est annulé. Consultez les alternatives.',
      );
    case TrainStatus.delayed:
      final delay = train.delayMinutes ?? 0;
      return _NotificationPayload(
        '⏱️ Retard détecté',
        'Le train $departureName → $arrivalName partira avec ${delay.abs()} min de retard.',
      );
    case TrainStatus.early:
      final advance = train.delayMinutes ?? 0;
      return _NotificationPayload(
        '⚠️ Départ avancé',
        'Le train $departureName → $arrivalName partira ${advance.abs()} min plus tôt.',
      );
    case TrainStatus.onTime:
      final minutesText = leadMinutes > 0 ? 'dans $leadMinutes min' : 'bientôt';
      return _NotificationPayload(
        "✅ Train à l'heure",
        "Le train $departureName → $arrivalName est prévu à l'heure, départ $minutesText.",
      );
    case TrainStatus.unknown:
      return _NotificationPayload(
        baseTitle,
        "Le statut du train $departureName → $arrivalName reste inconnu. Vérifiez l'application.",
      );
  }
}

Train _selectClosestTrain(List<Train> trains, DateTime target) {
  return trains.reduce((current, next) {
    final currentDiff = (current.departureTime.difference(target)).abs();
    final nextDiff = (next.departureTime.difference(target)).abs();
    return currentDiff <= nextDiff ? current : next;
  });
}

Future<void> _showNotification(String title, String body) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  try {
    await plugin.initialize(initSettings);
  } on Exception catch (e) {
    debugPrint('ℹ️ Initialisation des notifications déjà effectuée: $e');
  }

  const androidDetails = AndroidNotificationDetails(
    'train_qil_channel',
    "Train'Qil Notifications",
    channelDescription: 'Notifications pour les trajets de train',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
  );
}

Future<void> _scheduleNextRun({
  required Trip trip,
  required String apiKey,
  required int leadMinutes,
}) async {
  if (apiKey.trim().isEmpty) {
    debugPrint(
        '⏭️ API manquante, annulation de la replanification pour ${trip.id}');
    await Workmanager()
        .cancelByUniqueName(TripReminderService.uniqueName(trip.id));
    return;
  }

  final now = DateTime.now();
  final nextDeparture = TripReminderService.computeNextDeparture(trip, now);
  if (nextDeparture == null) {
    await Workmanager()
        .cancelByUniqueName(TripReminderService.uniqueName(trip.id));
    return;
  }

  final leadDuration = Duration(minutes: max(0, leadMinutes));
  final triggerTime = nextDeparture.subtract(leadDuration);
  final delay = triggerTime.isBefore(now)
      ? const Duration(seconds: 10)
      : triggerTime.difference(now);

  await Workmanager().registerOneOffTask(
    TripReminderService.uniqueName(trip.id),
    TripReminderService.taskName,
    inputData: {
      'tripId': trip.id,
      'departureStationId': trip.departureStation.id,
      'departureStationName': trip.departureStation.name,
      'arrivalStationId': trip.arrivalStation.id,
      'arrivalStationName': trip.arrivalStation.name,
      'departureDateTime': nextDeparture.toIso8601String(),
      'leadTimeMinutes': leadMinutes,
      'apiKey': apiKey,
    },
    initialDelay: delay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.connected),
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 10),
  );
}
