import 'station.dart';

/// Représente un arrêt dans un trajet
class JourneyStop {
  final Station station;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final DateTime? baseArrivalTime;
  final DateTime? baseDepartureTime;
  final bool isPassed;
  final bool isCurrent;
  final bool isUpcoming;

  const JourneyStop({
    required this.station,
    this.arrivalTime,
    this.departureTime,
    this.baseArrivalTime,
    this.baseDepartureTime,
    this.isPassed = false,
    this.isCurrent = false,
    this.isUpcoming = false,
  });

  JourneyStop copyWith({
    Station? station,
    DateTime? arrivalTime,
    DateTime? departureTime,
    DateTime? baseArrivalTime,
    DateTime? baseDepartureTime,
    bool? isPassed,
    bool? isCurrent,
    bool? isUpcoming,
  }) {
    return JourneyStop(
      station: station ?? this.station,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      baseArrivalTime: baseArrivalTime ?? this.baseArrivalTime,
      baseDepartureTime: baseDepartureTime ?? this.baseDepartureTime,
      isPassed: isPassed ?? this.isPassed,
      isCurrent: isCurrent ?? this.isCurrent,
      isUpcoming: isUpcoming ?? this.isUpcoming,
    );
  }
}

