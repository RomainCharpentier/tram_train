import '../../domain/models/train.dart';
import '../../domain/models/station.dart';

/// Mapper pour convertir les données SNCF vers les modèles du domain
class SncfMapper {
  /// Parse le format datetime SNCF (YYYYMMDDTHHMMSS) en DateTime local
  DateTime _parseSncfDateTime(String value) {
    // Exemple: 20250101T081000
    final y = int.parse(value.substring(0, 4));
    final m = int.parse(value.substring(4, 6));
    final d = int.parse(value.substring(6, 8));
    final h = int.parse(value.substring(9, 11));
    final min = int.parse(value.substring(11, 13));
    final s = int.parse(value.substring(13, 15));
    return DateTime(y, m, d, h, min, s);
  }

  /// Convertit les départs SNCF vers des trains
  List<Train> mapDeparturesToTrains(Map<String, dynamic> response, Station station) {
    final departures = (response['departures'] as List<dynamic>?)
            ?.map((departure) => _mapDepartureToTrain(departure, station))
            .toList() ??
        [];

    return departures;
  }

  /// Convertit un départ SNCF vers un train
  Train _mapDepartureToTrain(Map<String, dynamic> departure, Station station) {
    final stopDateTime = departure['stop_date_time'] as Map<String, dynamic>;
    final displayInfo = departure['display_informations'] as Map<String, dynamic>;

    final departureTime = _parseSncfDateTime(stopDateTime['departure_date_time'] as String);
    final baseDepartureTime =
        _parseSncfDateTime(stopDateTime['base_departure_date_time'] as String);

    // Générer un ID unique basé sur les données disponibles
    final links = departure['links'] as List<dynamic>? ?? [];
    final vehicleJourneyLink = links.firstWhere(
      (link) => link['type'] == 'vehicle_journey',
      orElse: () => {'id': 'unknown'},
    );
    final id = vehicleJourneyLink['id'] as String? ?? 'unknown';

    return Train.fromTimes(
      id: id,
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      station: station,
      additionalInfo: [
        'Ligne: ${displayInfo['label'] ?? ''}',
        'Mode: ${displayInfo['physical_mode'] ?? ''}',
        'Réseau: ${displayInfo['network'] ?? ''}',
      ],
    );
  }

  /// Convertit les lieux SNCF vers des gares
  List<Station> mapPlacesToStations(Map<String, dynamic> response) {
    final places =
        (response['places'] as List<dynamic>?)?.map((place) => mapPlaceToStation(place)).toList() ??
            [];

    return places;
  }

  /// Convertit un lieu SNCF vers une gare
  Station mapPlaceToStation(Map<String, dynamic> place) {
    final fullId = place['id'] as String? ?? '';
    final sncfId = fullId.replaceFirst('stop_area:', '');

    return Station(
      id: sncfId,
      name: place['name'] as String? ?? '',
      description: place['label'] as String? ?? '',
    );
  }

  /// Convertit les horaires de route vers des trains
  List<Train> mapRouteSchedulesToTrains(Map<String, dynamic> response, Station station) {
    final routeSchedules = (response['route_schedules'] as List<dynamic>?)?.expand((routeSchedule) {
          final displayInfo = routeSchedule['display_informations'] as Map<String, dynamic>;
          final table = routeSchedule['table'] as Map<String, dynamic>;
          final rows = table['rows'] as List<dynamic>? ?? [];

          return rows.map((row) => _mapRouteScheduleRowToTrain(row, displayInfo, station));
        }).toList() ??
        [];

    return routeSchedules;
  }

  /// Convertit une ligne d'horaire de route vers un train
  Train _mapRouteScheduleRowToTrain(
      Map<String, dynamic> row, Map<String, dynamic> displayInfo, Station station) {
    final stopTimes = row['stop_times'] as List<dynamic>? ?? [];
    final firstStopTime = stopTimes.isNotEmpty ? stopTimes.first as Map<String, dynamic> : {};

    final departureTime = firstStopTime['departure_date_time'] != null
        ? _parseSncfDateTime(firstStopTime['departure_date_time'] as String)
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
  List<Train> mapJourneysToTrains(
      Map<String, dynamic> response, Station fromStation, Station toStation) {
    final journeys = (response['journeys'] as List<dynamic>?)
            ?.map((journey) => _mapJourneyToTrain(journey, fromStation, toStation))
            .toList() ??
        [];

    return journeys;
  }

  /// Convertit un trajet SNCF vers un train
  Train _mapJourneyToTrain(Map<String, dynamic> journey, Station fromStation, Station toStation) {
    final sections = journey['sections'] as List<dynamic>? ?? [];
    final firstSection = sections.isNotEmpty ? sections.first as Map<String, dynamic> : {};
    final lastSection = sections.isNotEmpty ? sections.last as Map<String, dynamic> : {};

    final from = firstSection['from'] as Map<String, dynamic>? ?? {};
    final to = lastSection['to'] as Map<String, dynamic>? ?? {};

    // Essayer plusieurs emplacements possibles pour les horodatages
    String? depRaw = firstSection['departure_date_time'] as String?;
    depRaw ??= from['departure_date_time'] as String?;
    if (depRaw == null) {
      final stopDateTimes = firstSection['stop_date_times'] as List<dynamic>?;
      if (stopDateTimes != null && stopDateTimes.isNotEmpty) {
        final firstStop = stopDateTimes.first as Map<String, dynamic>;
        depRaw = firstStop['departure_date_time'] as String?;
      }
    }

    String? arrRaw = lastSection['arrival_date_time'] as String?;
    arrRaw ??= to['arrival_date_time'] as String?;
    if (arrRaw == null) {
      final stopDateTimes = lastSection['stop_date_times'] as List<dynamic>?;
      if (stopDateTimes != null && stopDateTimes.isNotEmpty) {
        final lastStop = stopDateTimes.last as Map<String, dynamic>;
        arrRaw = lastStop['arrival_date_time'] as String?;
      }
    }

    final departureTime = depRaw != null ? _parseSncfDateTime(depRaw) : DateTime.now();
    final arrivalTime = arrRaw != null ? _parseSncfDateTime(arrRaw) : DateTime.now();

    // Détecter les vraies correspondances (changement de véhicule/mode)
    final hasConnections = _hasRealConnections(sections);
    final connectionCount = _countRealConnections(sections);

    return Train.fromTimes(
      id: journey['id'] as String? ?? '',
      direction: to['name'] as String? ?? toStation.name,
      departureTime: departureTime,
      baseDepartureTime: departureTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: arrivalTime,
      station: fromStation,
      additionalInfo: [
        'Durée: ${_calculateDuration(departureTime, arrivalTime)}',
        if (hasConnections) 'Correspondances: $connectionCount',
        if (hasConnections) 'Type: Avec correspondances' else 'Type: Direct',
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

  /// Vérifie s'il y a de vraies correspondances (changement de véhicule/mode)
  bool _hasRealConnections(List<dynamic> sections) {
    if (sections.length <= 1) return false;

    // Filtrer les sections qui ont un mode de transport réel
    final transportSections = <Map<String, dynamic>>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sectionData = section as Map<String, dynamic>;
      final displayInfo = sectionData['display_informations'] as Map<String, dynamic>? ?? {};

      final currentMode = displayInfo['physical_mode'] as String?;
      final currentLine = displayInfo['commercial_mode'] as String?;

      // Ne garder que les sections avec un mode de transport réel
      if (currentMode != null && currentMode.isNotEmpty) {
        transportSections.add({
          'mode': currentMode,
          'line': currentLine,
          'index': i,
        });
      }
    }

    // Si moins de 2 sections de transport, pas de correspondance
    if (transportSections.length < 2) {
      return false;
    }

    // Vérifier les changements entre sections de transport
    for (int i = 1; i < transportSections.length; i++) {
      final prev = transportSections[i - 1];
      final curr = transportSections[i];

      final prevMode = prev['mode'] as String;
      final currMode = curr['mode'] as String;
      final prevLine = prev['line'] as String?;
      final currLine = curr['line'] as String?;

      if (prevMode != currMode) {
        return true;
      }

      if (prevLine != null && currLine != null && prevLine != currLine) {
        return true;
      }
    }

    return false;
  }

  /// Compte le nombre de vraies correspondances
  int _countRealConnections(List<dynamic> sections) {
    if (sections.length <= 1) return 0;

    // Filtrer les sections qui ont un mode de transport réel
    final transportSections = <Map<String, dynamic>>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sectionData = section as Map<String, dynamic>;
      final displayInfo = sectionData['display_informations'] as Map<String, dynamic>? ?? {};

      final currentMode = displayInfo['physical_mode'] as String?;
      final currentLine = displayInfo['commercial_mode'] as String?;

      // Ne garder que les sections avec un mode de transport réel
      if (currentMode != null && currentMode.isNotEmpty) {
        transportSections.add({
          'mode': currentMode,
          'line': currentLine,
        });
      }
    }

    // Si moins de 2 sections de transport, pas de correspondance
    if (transportSections.length < 2) return 0;

    int connectionCount = 0;

    // Compter les changements entre sections de transport
    for (int i = 1; i < transportSections.length; i++) {
      final prev = transportSections[i - 1];
      final curr = transportSections[i];

      final prevMode = prev['mode'] as String;
      final currMode = curr['mode'] as String;
      final prevLine = prev['line'] as String?;
      final currLine = curr['line'] as String?;

      if (prevMode != currMode) {
        connectionCount++;
      } else if (prevLine != null && currLine != null && prevLine != currLine) {
        connectionCount++;
      }
    }

    return connectionCount;
  }

  /// Convertit les informations de gare
  Map<String, dynamic> mapStationInfo(Map<String, dynamic> response) {
    final stopSchedules = response['stop_schedules'] as List<dynamic>? ?? [];
    final firstSchedule =
        stopSchedules.isNotEmpty ? stopSchedules.first as Map<String, dynamic> : {};
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
            .toList() ??
        [];

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
              .toList() ??
          [],
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
            .toList() ??
        [];

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
            .toList() ??
        [];

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
            .toList() ??
        [];

    return arrivals;
  }

  /// Convertit une arrivée vers un train
  Train _mapArrivalToTrain(Map<String, dynamic> arrival, Station station) {
    final stopDateTime = arrival['stop_date_time'] as Map<String, dynamic>? ?? {};
    final displayInfo = arrival['display_informations'] as Map<String, dynamic>? ?? {};

    final arrivalTime = stopDateTime['arrival_date_time'] != null
        ? _parseSncfDateTime(stopDateTime['arrival_date_time'] as String)
        : DateTime.now();

    return Train.fromTimes(
      id: arrival['id'] as String? ?? '',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: arrivalTime,
      baseDepartureTime: arrivalTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: arrivalTime,
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
            .toList() ??
        [];

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
              .toList() ??
          [],
      'stop_areas': (report['stop_areas'] as List<dynamic>?)
              ?.map((area) => area['id'] as String? ?? '')
              .toList() ??
          [],
      'updated_at': report['updated_at'] ?? '',
    };
  }
}
