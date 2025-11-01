import 'station.dart';

enum TrainStatus {
  onTime,
  delayed,
  early,
  cancelled,
  unknown,
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
    );
  }

  String get statusText {
    switch (status) {
      case TrainStatus.onTime:
        return 'À l\'heure';
      case TrainStatus.delayed:
        return 'En retard (+$delayMinutes min)';
      case TrainStatus.early:
        return 'En avance ($delayMinutes min)';
      case TrainStatus.cancelled:
        return 'Annulé';
      case TrainStatus.unknown:
        return 'Statut inconnu';
    }
  }

  /// Retourne l'heure de départ formatée
  String get departureTimeFormatted {
    final hour = departureTime.hour.toString().padLeft(2, '0');
    final minute = departureTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Retourne l'heure d'arrivée formatée si disponible
  String? get arrivalTimeFormatted {
    if (arrivalTime == null) return null;
    final hour = arrivalTime!.hour.toString().padLeft(2, '0');
    final minute = arrivalTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Vérifie si le train est en retard
  bool get isDelayed => status == TrainStatus.delayed;

  /// Vérifie si le trajet est direct (sans correspondances)
  bool get isDirect {
    // Chercher dans additionalInfo s'il y a une indication de correspondances
    final connectionInfo = additionalInfo.firstWhere(
      (info) => info.startsWith('Type:'),
      orElse: () => '',
    );

    // Si pas d'info, considérer comme direct par défaut
    if (connectionInfo.isEmpty) return true;

    // Si "Type: Direct" alors c'est direct, sinon c'est avec correspondances
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
}
