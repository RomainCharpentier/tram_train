import '../../domain/models/train.dart';
import '../../domain/models/station.dart';

class SncfMapper {
  DateTime _parseSncfDateTime(String value) {
    final y = int.parse(value.substring(0, 4));
    final m = int.parse(value.substring(4, 6));
    final d = int.parse(value.substring(6, 8));
    final h = int.parse(value.substring(9, 11));
    final min = int.parse(value.substring(11, 13));
    final s = int.parse(value.substring(13, 15));
    return DateTime(y, m, d, h, min, s);
  }

  DateTime? _tryParseSncfDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return _parseSncfDateTime(value);
  }

  TrainStatus? _mapSncfStatus(String? status) {
    if (status == null) return null;
    switch (status.toLowerCase()) {
      case 'on_time':
      case 'theoretical':
      case 'scheduled':
      case 'planned':
      case 'departed':
      case 'arrival':
        return TrainStatus.onTime;
      case 'delayed':
      case 'late':
      case 'retarded':
        return TrainStatus.delayed;
      case 'early':
      case 'ahead':
        return TrainStatus.early;
      case 'cancelled':
      case 'canceled':
      case 'suppressed':
      case 'deleted':
        return TrainStatus.cancelled;
      default:
        return null;
    }
  }

  int? _parseDelayMinutes(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return (value / 60).round();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return (parsed / 60).round();
      }
    }
    return null;
  }

  List<Train> mapDeparturesToTrains(Map<String, dynamic> response, Station station) {
    final departures = (response['departures'] as List<dynamic>?)
            ?.map((departure) => _mapDepartureToTrain(departure, station))
            .toList() ??
        [];

    return departures;
  }

  Train _mapDepartureToTrain(Map<String, dynamic> departure, Station station) {
    final stopDateTime = departure['stop_date_time'] as Map<String, dynamic>;
    final displayInfo = departure['display_informations'] as Map<String, dynamic>;
    final departurePlatform = stopDateTime['departure_platform'] as String?;
    final arrivalPlatform = stopDateTime['arrival_platform'] as String?;

    final departureTime = _parseSncfDateTime(stopDateTime['departure_date_time'] as String);
    final baseDepartureTime =
        _tryParseSncfDateTime(stopDateTime['base_departure_date_time'] as String?) ??
            departureTime;
    final arrivalTime = _tryParseSncfDateTime(stopDateTime['arrival_date_time'] as String?);
    final baseArrivalTime =
        _tryParseSncfDateTime(stopDateTime['base_arrival_date_time'] as String?) ?? arrivalTime;

    final departureStatusRaw = stopDateTime['departure_status'] as String?;
    final arrivalStatusRaw = stopDateTime['arrival_status'] as String?;
    var statusHint = _mapSncfStatus(departureStatusRaw) ?? _mapSncfStatus(arrivalStatusRaw);

    final delayMinutesSigned = _parseDelayMinutes(stopDateTime['departure_delay']) ??
        _parseDelayMinutes(stopDateTime['arrival_delay']);
    int? delayMinutes = delayMinutesSigned != null ? delayMinutesSigned.abs() : null;

    var computedStatus = statusHint ?? TrainStatus.unknown;
    if (computedStatus != TrainStatus.cancelled) {
      int? signedDelay = delayMinutesSigned;
      if (signedDelay == null) {
        final diff = departureTime.difference(baseDepartureTime).inMinutes;
        if (diff != 0) {
          signedDelay = diff;
          delayMinutes = diff.abs();
        }
      }
      if (signedDelay != null && signedDelay != 0) {
        computedStatus = signedDelay > 0 ? TrainStatus.delayed : TrainStatus.early;
      } else if (computedStatus == TrainStatus.unknown) {
        computedStatus = TrainStatus.onTime;
      }
    }

    final links = departure['links'] as List<dynamic>? ?? [];
    final vehicleJourneyLink = links.firstWhere(
      (link) => link['type'] == 'vehicle_journey',
      orElse: () => {'id': 'unknown'},
    );
    final id = vehicleJourneyLink['id'] as String? ?? 'unknown';

    final additionalInfo = <String>[
      'Ligne: ${displayInfo['label'] ?? ''}',
      'Mode: ${displayInfo['physical_mode'] ?? ''}',
      'Réseau: ${displayInfo['network'] ?? ''}',
    ];

    final extraInfos = stopDateTime['additional_informations'];
    if (extraInfos is List) {
      final texts = extraInfos.map((e) => e?.toString()).whereType<String>();
      additionalInfo.addAll(texts);
    }

    return Train(
      id: id,
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: baseArrivalTime,
      status: computedStatus,
      delayMinutes: computedStatus == TrainStatus.cancelled ? null : delayMinutes,
      additionalInfo: additionalInfo,
      station: station,
      departurePlatform: departurePlatform,
      arrivalPlatform: arrivalPlatform,
    );
  }

  List<Station> mapPlacesToStations(Map<String, dynamic> response) {
    final places =
        (response['places'] as List<dynamic>?)?.map((place) => mapPlaceToStation(place)).toList() ??
            [];

    return places;
  }

  Station mapPlaceToStation(Map<String, dynamic> place) {
    final fullId = place['id'] as String? ?? '';
    final sncfId = fullId.replaceFirst('stop_area:', '');

    return Station(
      id: sncfId,
      name: place['name'] as String? ?? '',
      description: place['label'] as String? ?? '',
    );
  }

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

  Train _mapRouteScheduleRowToTrain(
      Map<String, dynamic> row, Map<String, dynamic> displayInfo, Station station) {
    final stopTimes = row['stop_times'] as List<dynamic>? ?? [];
    final firstStopTime = stopTimes.isNotEmpty ? stopTimes.first as Map<String, dynamic> : {};

    final departureTime = firstStopTime['departure_date_time'] != null
        ? _parseSncfDateTime(firstStopTime['departure_date_time'] as String)
        : DateTime.now();

    return Train(
      id: '${station.id}_${row['pattern']['id']}',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: departureTime,
      status: TrainStatus.unknown,
      additionalInfo: [],
      station: station,
    );
  }

  List<Train> mapJourneysToTrains(
      Map<String, dynamic> response, Station fromStation, Station toStation) {
    final journeys = (response['journeys'] as List<dynamic>?)
            ?.map((journey) => _mapJourneyToTrain(journey, fromStation, toStation))
            .toList() ??
        [];

    return journeys;
  }

  Train _mapJourneyToTrain(Map<String, dynamic> journey, Station fromStation, Station toStation) {
    final sections = journey['sections'] as List<dynamic>? ?? [];
    final firstSection = sections.isNotEmpty ? sections.first as Map<String, dynamic> : {};
    final lastSection = sections.isNotEmpty ? sections.last as Map<String, dynamic> : {};

    final from = firstSection['from'] as Map<String, dynamic>? ?? {};
    final to = lastSection['to'] as Map<String, dynamic>? ?? {};

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

    DateTime baseDepartureTime = departureTime;
    DateTime? baseArrivalTime = arrivalTime;

    final firstStopTimes = firstSection['stop_date_times'] as List<dynamic>? ?? [];
    final firstStop = firstStopTimes.isNotEmpty ? firstStopTimes.first as Map<String, dynamic> : {};
    final lastStopTimes = lastSection['stop_date_times'] as List<dynamic>? ?? [];
    final lastStop = lastStopTimes.isNotEmpty ? lastStopTimes.last as Map<String, dynamic> : {};

    baseDepartureTime =
        _tryParseSncfDateTime(firstSection['base_departure_date_time'] as String?) ??
            _tryParseSncfDateTime(firstStop['base_departure_date_time'] as String?) ??
            departureTime;
    baseArrivalTime =
        _tryParseSncfDateTime(lastSection['base_arrival_date_time'] as String?) ??
            _tryParseSncfDateTime(lastStop['base_arrival_date_time'] as String?) ??
            arrivalTime;

    final departureStatusRaw =
        firstSection['departure_status'] as String? ?? firstStop['departure_status'] as String?;
    final arrivalStatusRaw =
        lastSection['arrival_status'] as String? ?? lastStop['arrival_status'] as String?;

    var statusHint = _mapSncfStatus(departureStatusRaw) ?? _mapSncfStatus(arrivalStatusRaw);

    int? delayMinutesSigned =
        _parseDelayMinutes(firstStop['departure_delay']) ?? _parseDelayMinutes(lastStop['arrival_delay']);
    int? delayMinutes = delayMinutesSigned != null ? delayMinutesSigned.abs() : null;

    var computedStatus = statusHint ?? TrainStatus.unknown;
    if (computedStatus != TrainStatus.cancelled) {
      int? signedDelay = delayMinutesSigned;
      if (signedDelay == null) {
        final diff = departureTime.difference(baseDepartureTime).inMinutes;
        if (diff != 0) {
          signedDelay = diff;
          delayMinutes = diff.abs();
        }
      }
      if (signedDelay != null && signedDelay != 0) {
        computedStatus = signedDelay > 0 ? TrainStatus.delayed : TrainStatus.early;
      } else if (computedStatus == TrainStatus.unknown) {
        computedStatus = TrainStatus.onTime;
      }
    }

    final hasConnections = _hasRealConnections(sections);
    final connectionCount = _countRealConnections(sections);

    final departurePlatform =
        firstStop['departure_platform'] as String? ?? firstSection['departure_platform'] as String?;
    final arrivalPlatform =
        lastStop['arrival_platform'] as String? ?? lastSection['arrival_platform'] as String?;

    return Train(
      id: journey['id'] as String? ?? '',
      direction: to['name'] as String? ?? toStation.name,
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: baseArrivalTime,
      status: computedStatus,
      delayMinutes: computedStatus == TrainStatus.cancelled ? null : delayMinutes,
      station: fromStation,
      additionalInfo: [
        'Durée: ${_calculateDuration(departureTime, arrivalTime)}',
        if (hasConnections) 'Correspondances: $connectionCount',
        if (hasConnections) 'Type: Avec correspondances' else 'Type: Direct',
      ],
      departurePlatform: departurePlatform,
      arrivalPlatform: arrivalPlatform,
    );
  }

  String _calculateDuration(DateTime departure, DateTime arrival) {
    final duration = arrival.difference(departure);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  bool _hasRealConnections(List<dynamic> sections) {
    if (sections.length <= 1) return false;

    final transportSections = <Map<String, dynamic>>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sectionData = section as Map<String, dynamic>;
      final displayInfo = sectionData['display_informations'] as Map<String, dynamic>? ?? {};

      final currentMode = displayInfo['physical_mode'] as String?;
      final currentLine = displayInfo['commercial_mode'] as String?;

      if (currentMode != null && currentMode.isNotEmpty) {
        transportSections.add({
          'mode': currentMode,
          'line': currentLine,
          'index': i,
        });
      }
    }

    if (transportSections.length < 2) {
      return false;
    }

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

  int _countRealConnections(List<dynamic> sections) {
    if (sections.length <= 1) return 0;

    final transportSections = <Map<String, dynamic>>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sectionData = section as Map<String, dynamic>;
      final displayInfo = sectionData['display_informations'] as Map<String, dynamic>? ?? {};

      final currentMode = displayInfo['physical_mode'] as String?;
      final currentLine = displayInfo['commercial_mode'] as String?;

      if (currentMode != null && currentMode.isNotEmpty) {
        transportSections.add({
          'mode': currentMode,
          'line': currentLine,
        });
      }
    }

    if (transportSections.length < 2) return 0;

    int connectionCount = 0;

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

  List<Map<String, dynamic>> mapDisruptions(Map<String, dynamic> response) {
    final disruptions = (response['disruptions'] as List<dynamic>?)
            ?.map((disruption) => _mapDisruption(disruption))
            .toList() ??
        [];

    return disruptions;
  }

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

  List<Station> mapLineStations(Map<String, dynamic> response) {
    final stopAreas = (response['stop_areas'] as List<dynamic>?)
            ?.map((stopArea) => mapStopAreaToStation(stopArea))
            .toList() ??
        [];

    return stopAreas;
  }

  Station mapStopAreaToStation(Map<String, dynamic> stopArea) {
    return Station(
      id: stopArea['id'] as String? ?? '',
      name: stopArea['name'] as String? ?? '',
      description: stopArea['label'] as String? ?? '',
    );
  }

  List<Map<String, dynamic>> mapLineSchedules(Map<String, dynamic> response) {
    final schedules = (response['schedules'] as List<dynamic>?)
            ?.map((schedule) => _mapLineSchedule(schedule))
            .toList() ??
        [];

    return schedules;
  }

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

  List<Train> mapArrivalsToTrains(Map<String, dynamic> response, Station station) {
    final arrivals = (response['arrivals'] as List<dynamic>?)
            ?.map((arrival) => _mapArrivalToTrain(arrival, station))
            .toList() ??
        [];

    return arrivals;
  }

  Train _mapArrivalToTrain(Map<String, dynamic> arrival, Station station) {
    final stopDateTime = arrival['stop_date_time'] as Map<String, dynamic>? ?? {};
    final displayInfo = arrival['display_informations'] as Map<String, dynamic>? ?? {};
    final departurePlatform = stopDateTime['departure_platform'] as String?;
    final arrivalPlatform = stopDateTime['arrival_platform'] as String?;

    final arrivalTime = _tryParseSncfDateTime(stopDateTime['arrival_date_time'] as String?) ??
        DateTime.now();
    final baseArrivalTime =
        _tryParseSncfDateTime(stopDateTime['base_arrival_date_time'] as String?) ?? arrivalTime;
    final departureTime =
        _tryParseSncfDateTime(stopDateTime['departure_date_time'] as String?) ?? arrivalTime;
    final baseDepartureTime =
        _tryParseSncfDateTime(stopDateTime['base_departure_date_time'] as String?) ??
            departureTime;

    final arrivalStatusRaw = stopDateTime['arrival_status'] as String?;
    final departureStatusRaw = stopDateTime['departure_status'] as String?;

    var statusHint = _mapSncfStatus(arrivalStatusRaw) ?? _mapSncfStatus(departureStatusRaw);

    int? delayMinutesSigned = _parseDelayMinutes(stopDateTime['arrival_delay']) ??
        _parseDelayMinutes(stopDateTime['departure_delay']);
    int? delayMinutes = delayMinutesSigned != null ? delayMinutesSigned.abs() : null;

    var computedStatus = statusHint ?? TrainStatus.unknown;
    if (computedStatus != TrainStatus.cancelled) {
      int? signedDelay = delayMinutesSigned;
      if (signedDelay == null) {
        final diff = arrivalTime.difference(baseArrivalTime).inMinutes;
        if (diff != 0) {
          signedDelay = diff;
          delayMinutes = diff.abs();
        }
      }
      if (signedDelay != null && signedDelay != 0) {
        computedStatus = signedDelay > 0 ? TrainStatus.delayed : TrainStatus.early;
      } else if (computedStatus == TrainStatus.unknown) {
        computedStatus = TrainStatus.onTime;
      }
    }

    final additionalInfo = <String>[
      'Ligne: ${displayInfo['label'] ?? ''}',
      'Mode: ${displayInfo['physical_mode'] ?? ''}',
    ];

    final extraInfos = stopDateTime['additional_informations'];
    if (extraInfos is List) {
      additionalInfo.addAll(
        extraInfos.map((e) => e?.toString()).whereType<String>(),
      );
    }

    return Train(
      id: arrival['id'] as String? ?? '',
      direction: displayInfo['direction'] as String? ?? '',
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      arrivalTime: arrivalTime,
      baseArrivalTime: baseArrivalTime,
      status: computedStatus,
      delayMinutes: computedStatus == TrainStatus.cancelled ? null : delayMinutes,
      station: station,
      additionalInfo: additionalInfo,
      departurePlatform: departurePlatform,
      arrivalPlatform: arrivalPlatform,
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
