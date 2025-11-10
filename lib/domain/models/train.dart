import 'station.dart';

enum TrainStatus {
  onTime,
  delayed,
  early,
  cancelled,
  unknown,
}

enum TrainJourneyState {
  upcoming,
  inProgress,
  completed,
  cancelled,
}

class Train {
  final String id;
  final String direction;
  final DateTime departureTime;
  final DateTime? baseDepartureTime;
  final DateTime? arrivalTime;
  final DateTime? baseArrivalTime;
  final TrainStatus status;
  final int? delayMinutes;
  final List<String> additionalInfo;
  final Station station;
  final String? departurePlatform;
  final String? arrivalPlatform;
  final String? externalUrl;

  const Train({
    required this.id,
    required this.direction,
    required this.departureTime,
    this.baseDepartureTime,
    this.arrivalTime,
    this.baseArrivalTime,
    required this.status,
    this.delayMinutes,
    this.additionalInfo = const [],
    required this.station,
    this.departurePlatform,
    this.arrivalPlatform,
    this.externalUrl,
  });

  factory Train.fromTimes({
    required String id,
    required String direction,
    required DateTime departureTime,
    required DateTime baseDepartureTime,
    DateTime? arrivalTime,
    DateTime? baseArrivalTime,
    required Station station,
    List<String> additionalInfo = const [],
    String? departurePlatform,
    String? arrivalPlatform,
    String? externalUrl,
  }) {
    final difference = departureTime.difference(baseDepartureTime).inMinutes;

    TrainStatus status;
    int? delayMinutes;

    if (difference > 0) {
      status = TrainStatus.delayed;
      delayMinutes = difference;
    } else if (difference < 0) {
      status = TrainStatus.early;
      delayMinutes = difference.abs();
    } else {
      status = TrainStatus.onTime;
    }

    return Train(
      id: id,
      direction: direction,
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: baseArrivalTime,
      status: status,
      delayMinutes: delayMinutes,
      additionalInfo: additionalInfo,
      station: station,
      departurePlatform: departurePlatform,
      arrivalPlatform: arrivalPlatform,
      externalUrl: externalUrl,
    );
  }

  String get statusText {
    switch (status) {
      case TrainStatus.onTime:
        return 'À l\'heure';
      case TrainStatus.delayed:
        return delayMinutes != null
            ? 'En retard (+$delayMinutes min)'
            : 'En retard';
      case TrainStatus.early:
        return delayMinutes != null
            ? 'En avance ($delayMinutes min)'
            : 'En avance';
      case TrainStatus.cancelled:
        return 'Annulé';
      case TrainStatus.unknown:
        return 'Statut inconnu';
    }
  }

  String get departureTimeFormatted {
    final hour = departureTime.hour.toString().padLeft(2, '0');
    final minute = departureTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? get arrivalTimeFormatted {
    if (arrivalTime == null) return null;
    final hour = arrivalTime!.hour.toString().padLeft(2, '0');
    final minute = arrivalTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isDelayed => status == TrainStatus.delayed;

  bool get isDirect {
    final connectionInfo = additionalInfo.firstWhere(
      (info) => info.startsWith('Type:'),
      orElse: () => '',
    );

    if (connectionInfo.isEmpty) return true;

    return connectionInfo == 'Type: Direct';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Train && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Train(id: $id, direction: $direction, status: $status)';

  TrainJourneyState journeyState(DateTime now) {
    if (status == TrainStatus.cancelled) {
      return TrainJourneyState.cancelled;
    }
    if (departureTime.isAfter(now)) {
      return TrainJourneyState.upcoming;
    }
    if (arrivalTime != null && arrivalTime!.isBefore(now)) {
      return TrainJourneyState.completed;
    }
    return TrainJourneyState.inProgress;
  }
}
