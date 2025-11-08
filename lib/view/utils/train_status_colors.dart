import 'package:flutter/material.dart';
import '../../domain/models/train.dart';
import '../../infrastructure/dependency_injection.dart';

class TrainStatusPresentation {
  const TrainStatusPresentation({
    required this.state,
    required this.primaryText,
    required this.primaryColor,
    required this.primaryIcon,
    this.scheduleText,
    this.scheduleColor,
    this.scheduleIcon,
    this.actualDeparture,
    this.scheduledDeparture,
    this.actualArrival,
    this.scheduledArrival,
  });

  final TrainJourneyState state;
  final String primaryText;
  final Color primaryColor;
  final IconData primaryIcon;
  final String? scheduleText;
  final Color? scheduleColor;
  final IconData? scheduleIcon;
  final String? actualDeparture;
  final String? scheduledDeparture;
  final String? actualArrival;
  final String? scheduledArrival;
  bool get hasDepartureDifference =>
      actualDeparture != null &&
      scheduledDeparture != null &&
      actualDeparture != scheduledDeparture;
  bool get hasArrivalDifference =>
      actualArrival != null && scheduledArrival != null && actualArrival != scheduledArrival;
}

/// Utilitaires pour les couleurs & textes d'affichage des statuts de trains.
class TrainStatusColors {
  // Couleurs d'état du trajet
  static const Color inProgressColor = Color(0xFF3B82F6);
  static const Color upcomingColor = Colors.black;
  static const Color completedColor = Colors.grey;
  static const Color cancelledColor = Colors.red;

  // Couleurs liées à la ponctualité
  static const Color onTimeColor = Colors.black;
  static const Color delayedColor = Colors.orange;
  static const Color earlyColor = Colors.green;
  static const Color unknownColor = Colors.grey;

  static TrainStatusPresentation buildPresentation(Train train) {
    final state = getJourneyState(train);
    final primaryColor = _journeyStateColor(state);
    final primaryIcon = _journeyStateIcon(state);
    final primaryText = _journeyStateText(train, state);

    final scheduleText = _scheduleText(train, state);
    final scheduleColor = scheduleText != null ? getPunctualityColor(train.status) : null;
    final scheduleIcon = scheduleText != null ? getPunctualityIcon(train.status) : null;
    final scheduledDepartureTime = _scheduledDeparture(train);
    final scheduledArrivalTime = _scheduledArrival(train);
    final actualDepartureTime = _actualTimeFromSchedule(
        train.departureTime, scheduledDepartureTime, train.delayMinutes,
        isDelayed: train.status == TrainStatus.delayed);
    final actualArrivalTime = _actualTimeFromSchedule(
        train.arrivalTime, scheduledArrivalTime, train.delayMinutes,
        isDelayed: train.status == TrainStatus.delayed);

    final actualDeparture = _formatTime(actualDepartureTime);
    final scheduledDeparture = _formatTime(scheduledDepartureTime);
    final actualArrival = _formatTime(actualArrivalTime);
    final scheduledArrival = _formatTime(scheduledArrivalTime);
    return TrainStatusPresentation(
      state: state,
      primaryText: primaryText,
      primaryColor: primaryColor,
      primaryIcon: primaryIcon,
      scheduleText: scheduleText,
      scheduleColor: scheduleColor,
      scheduleIcon: scheduleIcon,
      actualDeparture: actualDeparture,
      scheduledDeparture: scheduledDeparture,
      actualArrival: actualArrival,
      scheduledArrival: scheduledArrival,
    );
  }

  static TrainJourneyState getJourneyState(Train train) {
    return train.journeyState(_now());
  }

  static DateTime? getScheduledDepartureTime(Train train) => _scheduledDeparture(train);

  static DateTime? getScheduledArrivalTime(Train train) => _scheduledArrival(train);

  static Color getJourneyStateColor(Train train) => _journeyStateColor(getJourneyState(train));

  static IconData getJourneyStateIcon(Train train) => _journeyStateIcon(getJourneyState(train));

  static String getJourneyPrimaryText(Train train) =>
      _journeyStateText(train, getJourneyState(train));

  static String? getScheduleText(Train train) => _scheduleText(train, getJourneyState(train));

  static Color? getScheduleColor(Train train) {
    final scheduleText = getScheduleText(train);
    if (scheduleText == null) return null;
    return getPunctualityColor(train.status);
  }

  static IconData? getScheduleIcon(Train train) {
    final scheduleText = getScheduleText(train);
    if (scheduleText == null) return null;
    return getPunctualityIcon(train.status);
  }

  static bool isTrainInProgress(Train train) =>
      getJourneyState(train) == TrainJourneyState.inProgress;

  static Color getPunctualityColor(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return onTimeColor;
      case TrainStatus.delayed:
        return delayedColor;
      case TrainStatus.early:
        return earlyColor;
      case TrainStatus.cancelled:
        return cancelledColor;
      case TrainStatus.unknown:
        return unknownColor;
    }
  }

  static IconData getPunctualityIcon(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return Icons.check_circle;
      case TrainStatus.delayed:
        return Icons.schedule;
      case TrainStatus.early:
        return Icons.trending_up;
      case TrainStatus.cancelled:
        return Icons.cancel;
      case TrainStatus.unknown:
        return Icons.help_outline;
    }
  }

  static DateTime _now() {
    try {
      return DependencyInjection.instance.clockService.now();
    } catch (_) {
      const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
      return useMockData ? DateTime(2025, 1, 6, 7, 0) : DateTime.now();
    }
  }

  static Color _journeyStateColor(TrainJourneyState state) {
    switch (state) {
      case TrainJourneyState.upcoming:
        return upcomingColor;
      case TrainJourneyState.inProgress:
        return inProgressColor;
      case TrainJourneyState.completed:
        return completedColor;
      case TrainJourneyState.cancelled:
        return cancelledColor;
    }
  }

  static IconData _journeyStateIcon(TrainJourneyState state) {
    switch (state) {
      case TrainJourneyState.upcoming:
        return Icons.schedule;
      case TrainJourneyState.inProgress:
        return Icons.train;
      case TrainJourneyState.completed:
        return Icons.flag;
      case TrainJourneyState.cancelled:
        return Icons.cancel;
    }
  }

  static String? _formatTime(DateTime? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _journeyStateText(Train train, TrainJourneyState state) {
    final scheduledDeparture = _scheduledDeparture(train);
    final actualDeparture = _actualTimeFromSchedule(
      train.departureTime,
      scheduledDeparture,
      train.delayMinutes,
      isDelayed: train.status == TrainStatus.delayed,
    );
    final scheduledArrival = _scheduledArrival(train);
    final actualArrival = _actualTimeFromSchedule(
      train.arrivalTime,
      scheduledArrival,
      train.delayMinutes,
      isDelayed: train.status == TrainStatus.delayed,
    );

    switch (state) {
      case TrainJourneyState.upcoming:
        final actualText = _formatTime(actualDeparture);
        final scheduledText = _formatTime(scheduledDeparture);
        final platformSuffix =
            (train.departurePlatform != null && train.departurePlatform!.isNotEmpty)
                ? ' • Voie ${train.departurePlatform}'
                : '';
        if (actualText != null && scheduledText != null && actualText != scheduledText) {
          return 'Prochain départ $actualText (prévu $scheduledText)$platformSuffix';
        }
        if (actualText != null) return 'Prochain départ $actualText$platformSuffix';
        return 'Prochain départ$platformSuffix';
      case TrainJourneyState.inProgress:
        final actualArrivalText = _formatTime(actualArrival);
        final scheduledArrivalText = _formatTime(scheduledArrival);
        final arrivalPlatformSuffix =
            (train.arrivalPlatform != null && train.arrivalPlatform!.isNotEmpty)
                ? ' • Voie ${train.arrivalPlatform}'
                : '';
        if (actualArrivalText != null &&
            scheduledArrivalText != null &&
            actualArrivalText != scheduledArrivalText) {
          return 'Trajet en cours • arrivée estimée $actualArrivalText (prévu $scheduledArrivalText)$arrivalPlatformSuffix';
        }
        if (actualArrivalText != null) {
          return 'Trajet en cours • arrivée estimée $actualArrivalText$arrivalPlatformSuffix';
        }
        return 'Trajet en cours';
      case TrainJourneyState.completed:
        final actualArrivalTextCompleted = _formatTime(actualArrival);
        final scheduledArrivalTextCompleted = _formatTime(scheduledArrival);
        if (actualArrivalTextCompleted != null &&
            scheduledArrivalTextCompleted != null &&
            actualArrivalTextCompleted != scheduledArrivalTextCompleted) {
          return 'Trajet terminé à $actualArrivalTextCompleted (prévu $scheduledArrivalTextCompleted)';
        }
        if (actualArrivalTextCompleted != null) {
          return 'Trajet terminé à $actualArrivalTextCompleted';
        }
        return 'Trajet terminé';
      case TrainJourneyState.cancelled:
        return 'Trajet annulé';
    }
  }

  static String? _scheduleText(Train train, TrainJourneyState state) {
    if (train.status == TrainStatus.unknown) {
      return null;
    }
    if (state == TrainJourneyState.cancelled || state == TrainJourneyState.completed) {
      return null;
    }
    return train.statusText;
  }

  static DateTime? _scheduledDeparture(Train train) {
    if (train.baseDepartureTime != null) return train.baseDepartureTime;
    if (train.delayMinutes != null) {
      final minutes = train.delayMinutes!;
      if (train.status == TrainStatus.delayed) {
        return train.departureTime.subtract(Duration(minutes: minutes));
      } else if (train.status == TrainStatus.early) {
        return train.departureTime.add(Duration(minutes: minutes));
      }
    }
    return train.departureTime;
  }

  static DateTime? _scheduledArrival(Train train) {
    if (train.baseArrivalTime != null) return train.baseArrivalTime;
    if (train.delayMinutes != null && train.arrivalTime != null) {
      final minutes = train.delayMinutes!;
      if (train.status == TrainStatus.delayed) {
        return train.arrivalTime!.subtract(Duration(minutes: minutes));
      } else if (train.status == TrainStatus.early) {
        return train.arrivalTime!.add(Duration(minutes: minutes));
      }
    }
    return train.arrivalTime;
  }

  static DateTime? _actualTimeFromSchedule(
    DateTime? actual,
    DateTime? scheduled,
    int? delayMinutes, {
    required bool isDelayed,
  }) {
    if (actual != null &&
        scheduled != null &&
        actual != scheduled &&
        _formatTime(actual) != _formatTime(scheduled)) {
      return actual;
    }
    if (scheduled == null) return actual;
    if (delayMinutes == null) return actual;
    final minutes = delayMinutes;
    if (isDelayed) {
      return scheduled.add(Duration(minutes: minutes));
    }
    if (actual != null && actual.isBefore(scheduled)) {
      return scheduled.subtract(Duration(minutes: minutes));
    }
    return actual;
  }
}
