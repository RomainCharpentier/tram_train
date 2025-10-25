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

  /// Convertit les lieux SNCF vers des gares
  List<Station> mapPlacesToStations(Map<String, dynamic> response) {
    final places = (response['places'] as List<dynamic>?)
        ?.map((place) => mapPlaceToStation(place))
        .toList() ?? [];
    
    return places;
  }

  /// Convertit un lieu SNCF vers une gare
  Station mapPlaceToStation(Map<String, dynamic> place) {
    return Station(
      id: place['id'] as String? ?? '',
      name: place['name'] as String? ?? '',
      description: place['label'] as String? ?? '',
    );
  }

  /// Convertit les horaires de route vers des trains
  List<Train> mapRouteSchedulesToTrains(Map<String, dynamic> response, Station station) {
    final routeSchedules = (response['route_schedules'] as List<dynamic>?)
        ?.expand((routeSchedule) {
          final displayInfo = routeSchedule['display_informations'] as Map<String, dynamic>;
          final table = routeSchedule['table'] as Map<String, dynamic>;
          final rows = table['rows'] as List<dynamic>? ?? [];
          
          return rows.map((row) => _mapRouteScheduleRowToTrain(row, displayInfo, station));
        })
        .toList() ?? [];
    
    return routeSchedules;
  }

  /// Convertit une ligne d'horaire de route vers un train
  Train _mapRouteScheduleRowToTrain(Map<String, dynamic> row, Map<String, dynamic> displayInfo, Station station) {
    final stopTimes = row['stop_times'] as List<dynamic>? ?? [];
    final firstStopTime = stopTimes.isNotEmpty ? stopTimes.first as Map<String, dynamic> : {};
    
    final departureTime = firstStopTime['departure_date_time'] != null
        ? DateTime.parse(firstStopTime['departure_date_time'] as String)
        : DateTime.now();
    
    return Train.fromTimes(
      id: '${station.id}_${row['pattern']['id']}',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: departureTime,
      station: station,
      additionalInfo: [],
    );
  }

  /// Convertit les trajets SNCF vers des trains
  List<Train> mapJourneysToTrains(Map<String, dynamic> response, Station fromStation, Station toStation) {
    final journeys = (response['journeys'] as List<dynamic>?)
        ?.map((journey) => _mapJourneyToTrain(journey, fromStation, toStation))
        .toList() ?? [];
    
    return journeys;
  }

  /// Convertit un trajet SNCF vers un train
  Train _mapJourneyToTrain(Map<String, dynamic> journey, Station fromStation, Station toStation) {
    final sections = journey['sections'] as List<dynamic>? ?? [];
    final firstSection = sections.isNotEmpty ? sections.first as Map<String, dynamic> : {};
    final from = firstSection['from'] as Map<String, dynamic>? ?? {};
    final to = firstSection['to'] as Map<String, dynamic>? ?? {};
    
    final departureTime = from['departure_date_time'] != null
        ? DateTime.parse(from['departure_date_time'] as String)
        : DateTime.now();
    
    final arrivalTime = to['arrival_date_time'] != null
        ? DateTime.parse(to['arrival_date_time'] as String)
        : DateTime.now();
    
    return Train.fromTimes(
      id: journey['id'] as String? ?? '',
      direction: to['name'] as String? ?? toStation.name,
      departureTime: departureTime,
      baseDepartureTime: departureTime,
      station: fromStation,
      additionalInfo: [
        'Arrivée: ${arrivalTime.toString()}',
        'Durée: ${_calculateDuration(departureTime, arrivalTime)}',
      ],
    );
  }

  /// Calcule la durée d'un trajet
  String _calculateDuration(DateTime departure, DateTime arrival) {
    final duration = arrival.difference(departure);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  /// Convertit les informations de gare
  Map<String, dynamic> mapStationInfo(Map<String, dynamic> response) {
    final stopSchedules = response['stop_schedules'] as List<dynamic>? ?? [];
    final firstSchedule = stopSchedules.isNotEmpty ? stopSchedules.first as Map<String, dynamic> : {};
    final displayInfo = firstSchedule['display_informations'] as Map<String, dynamic>? ?? {};
    
    return {
      'name': displayInfo['name'] ?? '',
      'direction': displayInfo['direction'] ?? '',
      'network': displayInfo['network'] ?? '',
      'commercial_mode': displayInfo['commercial_mode'] ?? '',
      'physical_mode': displayInfo['physical_mode'] ?? '',
    };
  }

  /// Convertit les perturbations
  List<Map<String, dynamic>> mapDisruptions(Map<String, dynamic> response) {
    final disruptions = (response['disruptions'] as List<dynamic>?)
        ?.map((disruption) => _mapDisruption(disruption))
        .toList() ?? [];
    
    return disruptions;
  }

  /// Convertit une perturbation
  Map<String, dynamic> _mapDisruption(Map<String, dynamic> disruption) {
    return {
      'id': disruption['id'] ?? '',
      'severity': disruption['severity'] ?? '',
      'impact_level': disruption['impact_level'] ?? '',
      'messages': (disruption['messages'] as List<dynamic>?)
          ?.map((message) => message['text'] as String? ?? '')
          .toList() ?? [],
      'application_periods': disruption['application_periods'] ?? [],
    };
  }

  /// Convertit les informations de ligne
  Map<String, dynamic> mapLineInfo(Map<String, dynamic> response) {
    final line = response['lines'] as List<dynamic>? ?? [];
    final firstLine = line.isNotEmpty ? line.first as Map<String, dynamic> : {};
    
    return {
      'id': firstLine['id'] ?? '',
      'name': firstLine['name'] ?? '',
      'code': firstLine['code'] ?? '',
      'color': firstLine['color'] ?? '',
      'text_color': firstLine['text_color'] ?? '',
      'commercial_mode': firstLine['commercial_mode'] ?? '',
      'physical_mode': firstLine['physical_mode'] ?? '',
      'network': firstLine['network'] ?? '',
      'opening_time': firstLine['opening_time'] ?? '',
      'closing_time': firstLine['closing_time'] ?? '',
    };
  }

  /// Convertit les gares d'une ligne
  List<Station> mapLineStations(Map<String, dynamic> response) {
    final stopAreas = (response['stop_areas'] as List<dynamic>?)
        ?.map((stopArea) => mapStopAreaToStation(stopArea))
        .toList() ?? [];

    return stopAreas;
  }

  /// Convertit une zone d'arrêt vers une gare
  Station mapStopAreaToStation(Map<String, dynamic> stopArea) {
    return Station(
      id: stopArea['id'] as String? ?? '',
      name: stopArea['name'] as String? ?? '',
      description: stopArea['label'] as String? ?? '',
    );
  }

  /// Convertit les horaires de ligne
  List<Map<String, dynamic>> mapLineSchedules(Map<String, dynamic> response) {
    final schedules = (response['schedules'] as List<dynamic>?)
        ?.map((schedule) => _mapLineSchedule(schedule))
        .toList() ?? [];

    return schedules;
  }

  /// Convertit un horaire de ligne
  Map<String, dynamic> _mapLineSchedule(Map<String, dynamic> schedule) {
    return {
      'id': schedule['id'] ?? '',
      'name': schedule['name'] ?? '',
      'direction': schedule['direction'] ?? '',
      'departure_time': schedule['departure_time'] ?? '',
      'arrival_time': schedule['arrival_time'] ?? '',
      'duration': schedule['duration'] ?? 0,
      'frequency': schedule['frequency'] ?? '',
      'validity_pattern': schedule['validity_pattern'] ?? {},
    };
  }

  /// Convertit les arrivées vers des trains
  List<Train> mapArrivalsToTrains(Map<String, dynamic> response, Station station) {
    final arrivals = (response['arrivals'] as List<dynamic>?)
        ?.map((arrival) => _mapArrivalToTrain(arrival, station))
        .toList() ?? [];

    return arrivals;
  }

  /// Convertit une arrivée vers un train
  Train _mapArrivalToTrain(Map<String, dynamic> arrival, Station station) {
    final stopDateTime = arrival['stop_date_time'] as Map<String, dynamic>? ?? {};
    final displayInfo = arrival['display_informations'] as Map<String, dynamic>? ?? {};

    final arrivalTime = stopDateTime['arrival_date_time'] != null
        ? DateTime.parse(stopDateTime['arrival_date_time'] as String)
        : DateTime.now();

    return Train.fromTimes(
      id: arrival['id'] as String? ?? '',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: arrivalTime,
      baseDepartureTime: arrivalTime,
      station: station,
      additionalInfo: [
        'Ligne: ${displayInfo['label'] ?? ''}',
        'Mode: ${displayInfo['physical_mode'] ?? ''}',
      ],
    );
  }

  /// Convertit les rapports de trafic
  List<Map<String, dynamic>> mapTrafficReports(Map<String, dynamic> response) {
    final reports = (response['traffic_reports'] as List<dynamic>?)
        ?.map((report) => _mapTrafficReport(report))
        .toList() ?? [];

    return reports;
  }

  /// Convertit un rapport de trafic
  Map<String, dynamic> _mapTrafficReport(Map<String, dynamic> report) {
    return {
      'id': report['id'] ?? '',
      'title': report['title'] ?? '',
      'message': report['message'] ?? '',
      'severity': report['severity'] ?? '',
      'impact_level': report['impact_level'] ?? '',
      'application_periods': report['application_periods'] ?? [],
      'lines': (report['lines'] as List<dynamic>?)
          ?.map((line) => line['id'] as String? ?? '')
          .toList() ?? [],
      'stop_areas': (report['stop_areas'] as List<dynamic>?)
          ?.map((area) => area['id'] as String? ?? '')
          .toList() ?? [],
      'updated_at': report['updated_at'] ?? '',
    };
  }
}
