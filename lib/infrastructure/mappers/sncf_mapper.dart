import '../../domain/models/train.dart';
import '../../domain/models/station.dart';

/// Mapper pour convertir les données SNCF vers les modèles du domain
class SncfMapper {
  /// Convertit les départs SNCF vers des trains
  List<Train> mapDeparturesToTrains(Map<String, dynamic> response, Station station) {
    final departures = (response['departures'] as List<dynamic>?)
        ?.map((departure) => _mapDepartureToTrain(departure, station))
        .toList() ?? [];
    
    return departures;
  }

  /// Convertit un départ SNCF vers un train
  Train _mapDepartureToTrain(Map<String, dynamic> departure, Station station) {
    final stopDateTime = departure['stop_date_time'] as Map<String, dynamic>;
    final displayInfo = departure['display_informations'] as Map<String, dynamic>;
    
    final departureTime = DateTime.parse(stopDateTime['departure_date_time'] as String);
    final baseDepartureTime = DateTime.parse(stopDateTime['base_departure_date_time'] as String);
    
    return Train.fromTimes(
      id: departure['id'] as String? ?? '',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      station: station,
      additionalInfo: (stopDateTime['additional_informations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}
