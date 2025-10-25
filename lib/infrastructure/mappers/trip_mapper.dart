import '../../domain/models/trip.dart';
import '../../domain/models/station.dart';

/// Mapper pour convertir les trajets vers/depuis JSON
class TripMapper {
  /// Convertit un trajet vers JSON
  Map<String, dynamic> toJson(Trip trip) {
    return {
      'id': trip.id,
      'stationId': trip.station.id,
      'stationName': trip.station.name,
      'dayOfWeek': trip.dayOfWeek,
      'time': trip.time,
      'createdAt': trip.createdAt.toIso8601String(),
    };
  }

  /// Convertit JSON vers un trajet
  Trip fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      station: Station(
        id: json['stationId'] as String,
        name: json['stationName'] as String,
      ),
      dayOfWeek: json['dayOfWeek'] as String,
      time: json['time'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
