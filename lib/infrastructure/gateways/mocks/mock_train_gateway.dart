import '../../../domain/models/train.dart';
import '../../../domain/models/station.dart';
import '../../../domain/services/train_service.dart';
import '../../dependency_injection.dart';
import 'data/mock_data.dart';

class MockTrainGateway implements TrainGateway {
  List<Train>? _mockTrains;
  DateTime? _lastNow;

  MockTrainGateway();

  List<Train> get _trains {
    final now = _getNow();
    if (_mockTrains == null || _lastNow != now) {
      _mockTrains = MockData.getMockTrains(now);
      _lastNow = now;
    }
    return _mockTrains!;
  }

  DateTime _getNow() {
    // Toujours utiliser DependencyInjection.instance.clockService pour garantir la bonne date
    return DependencyInjection.instance.clockService.now();
  }

  void resetCache() {
    _mockTrains = null;
    _lastNow = null;
  }

  @override
  Future<List<Train>> getDepartures(Station station) async {
    return _trains.where((train) => train.station.id == station.id).toList();
  }

  @override
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime) async {
    return _trains.where((train) {
      if (train.station.id != station.id) return false;
      // Retourner les trains dans les 2 heures autour de l'heure demandée
      final timeDiff = (train.departureTime.difference(dateTime).inMinutes).abs();
      return timeDiff <= 120;
    }).toList();
  }

  // Méthodes supplémentaires pour compatibilité avec SncfGateway
  Future<List<Train>> findJourneysBetween(Station fromStation, Station toStation) async {
    // Cas spéciaux pour tester l'état vide (aucun train trouvé)
    // Lyon → Marseille : état vide
    if (_matchesStationName(fromStation, 'Lyon Part-Dieu') &&
        _matchesStationName(toStation, 'Marseille St-Charles')) {
      return [];
    }
    // Paris → Bordeaux : état vide (trajet inactif mais pour tester l'état vide)
    if (_isParisStation(fromStation) && _matchesStationName(toStation, 'Bordeaux St-Jean')) {
      return [];
    }

    final matchingTrains = _trains.where((train) {
      // Le train doit partir de la station de départ
      // Vérifier si c'est une station parisienne (toutes les gares parisiennes sont acceptées)
      final fromMatches = _stationMatches(train.station, fromStation) ||
          (_isParisStation(train.station) && _isParisStation(fromStation));

      if (!fromMatches) return false;

      // La direction doit contenir la destination (vérifier par nom, avec tolérance)
      final toNameLower = toStation.name.toLowerCase();
      final directionLower = train.direction.toLowerCase();

      // Vérifier correspondance exacte ou partielle
      return directionLower.contains(toNameLower) ||
          _matchesStationName(toStation, 'Lille') && directionLower.contains('lille') ||
          _matchesStationName(toStation, 'Lyon') && directionLower.contains('lyon') ||
          _matchesStationName(toStation, 'Marseille') && directionLower.contains('marseille');
    }).toList();

    return matchingTrains;
  }

  /// Vérifie si une station est parisienne (pour tolérer toutes les gares parisiennes)
  bool _isParisStation(Station station) {
    final nameLower = station.name.toLowerCase();
    return nameLower.contains('paris') ||
        nameLower.contains('nord') ||
        nameLower.contains('lyon') && station.name.contains('Gare de Lyon');
  }

  /// Vérifie si deux stations correspondent (par ID ou par nom)
  bool _stationMatches(Station station, Station other) {
    return station.id == other.id || station.name == other.name;
  }

  /// Vérifie si une station correspond à un nom (par ID ou par nom)
  bool _matchesStationName(Station station, String name) {
    return station.name == name || station.name.toLowerCase() == name.toLowerCase();
  }

  Future<List<Train>> findJourneysWithDepartureTime(
    Station fromStation,
    Station toStation,
    DateTime departureTime,
  ) async {
    // Utiliser la même logique que findJourneysBetween mais filtrer aussi par heure
    final baseTrains = await findJourneysBetween(fromStation, toStation);

    if (baseTrains.isEmpty) return [];

    final now = _getNow();
    final trains = <Train>[];

    // Vérifier si on a un train en cours dans les mocks qui correspond
    final allMockTrains = MockData.getMockTrains(now);
    final inProgressTrain = allMockTrains.firstWhere(
      (t) =>
          t.id == 'mock_train_in_progress' &&
          _stationMatches(t.station, fromStation) &&
          t.direction.contains(toStation.name),
      orElse: () => Train(
        id: '',
        direction: '',
        departureTime: now,
        status: TrainStatus.unknown,
        station: fromStation,
      ),
    );

    // Si le train en cours correspond, toujours l'inclure (peu importe l'heure)
    // car il représente un train actuellement en cours de trajet
    if (inProgressTrain.id == 'mock_train_in_progress') {
      // Vérifier que le train est toujours en cours (départ passé, arrivée future)
      if (inProgressTrain.departureTime.isBefore(now) &&
          inProgressTrain.arrivalTime != null &&
          inProgressTrain.arrivalTime!.isAfter(now)) {
        trains.add(inProgressTrain);
      }
    }

    // Générer des trains à des heures fixes autour de l'heure demandée
    // pour le jour demandé, plutôt que d'utiliser les heures relatives à "maintenant"
    final targetDate = DateTime(
      departureTime.year,
      departureTime.month,
      departureTime.day,
    );

    // Créer des trains à des heures fixes autour de l'heure demandée
    // Exemple : si recherche à 8h, créer des trains à 7h30, 8h, 8h30, 9h
    final baseHour = departureTime.hour;
    final baseMinute = departureTime.minute;

    // Train à l'heure demandée
    trains.add(_createTrainFromTemplate(
      baseTrains.first,
      targetDate.add(Duration(hours: baseHour, minutes: baseMinute)),
    ));

    // Train 30 minutes avant (si pas trop tôt)
    if (baseHour > 0 || baseMinute >= 30) {
      final beforeTime = baseMinute >= 30
          ? targetDate.add(Duration(hours: baseHour, minutes: baseMinute - 30))
          : targetDate.add(Duration(hours: baseHour - 1, minutes: baseMinute + 30));
      trains.add(_createTrainFromTemplate(baseTrains.first, beforeTime));
    }

    // Train 30 minutes après
    trains.add(_createTrainFromTemplate(
      baseTrains.first,
      targetDate.add(Duration(hours: baseHour, minutes: baseMinute + 30)),
    ));

    // Train 1h après
    trains.add(_createTrainFromTemplate(
      baseTrains.first,
      targetDate.add(Duration(hours: baseHour + 1, minutes: baseMinute)),
    ));

    // Trier par heure de départ
    trains.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    return trains;
  }

  /// Crée un train à partir d'un template avec une nouvelle heure de départ
  Train _createTrainFromTemplate(Train template, DateTime newDepartureTime) {
    // Calculer la durée du trajet (par défaut 1h)
    Duration duration;
    if (template.baseArrivalTime != null && template.baseDepartureTime != null) {
      duration = template.baseArrivalTime!.difference(template.baseDepartureTime!);
    } else {
      duration = const Duration(hours: 1);
    }

    final newArrivalTime = newDepartureTime.add(duration);

    return Train(
      id: '${template.id}_${newDepartureTime.millisecondsSinceEpoch}',
      direction: template.direction,
      departureTime: newDepartureTime,
      baseDepartureTime: newDepartureTime,
      arrivalTime: newArrivalTime,
      baseArrivalTime: newArrivalTime,
      status: template.status,
      delayMinutes: template.delayMinutes,
      station: template.station,
      additionalInfo: template.additionalInfo,
      departurePlatform: template.departurePlatform,
      arrivalPlatform: template.arrivalPlatform,
      intermediateStops: template.intermediateStops,
    );
  }

  Future<List<Train>> findJourneysWithArrivalTime(
    Station fromStation,
    Station toStation,
    DateTime arrivalTime,
  ) async {
    return findJourneysBetween(fromStation, toStation);
  }

  Future<Map<String, dynamic>> getJourneysRaw(
    Station fromStation,
    Station toStation,
    DateTime time, {
    required String represents,
  }) async {
    // Retourner une structure mock simple
    return {
      'journeys': [],
      'links': [],
    };
  }

  Future<List<Train>> getJourneysByHref(
    String href,
    Station fromStation,
    Station toStation,
  ) async {
    return findJourneysBetween(fromStation, toStation);
  }

  // Méthodes supplémentaires de SncfGateway (non dans l'interface TrainGateway)

  /// Recherche de gares par nom (mock)
  Future<List<Station>> searchStations(String query) async {
    // Utiliser les stations des trajets mock
    final allStations = <Station>[];
    final trips = MockData.getMockTrips();

    for (final trip in trips) {
      if (!allStations.any((s) => s.id == trip.departureStation.id)) {
        allStations.add(trip.departureStation);
      }
      if (!allStations.any((s) => s.id == trip.arrivalStation.id)) {
        allStations.add(trip.arrivalStation);
      }
    }

    if (query.trim().isEmpty) return allStations;

    final queryLower = query.toLowerCase();
    return allStations.where((station) => station.name.toLowerCase().contains(queryLower)).toList();
  }

  Future<List<Train>> getTrainsPassingThrough(Station station) async {
    return _trains.where((train) => train.station.id == station.id).toList();
  }

  /// Récupère les informations d'une gare (mock)
  Future<Map<String, dynamic>> getStationInfo(Station station) async {
    return {
      'station_id': station.id,
      'name': station.name,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'departures_count': _trains.where((t) => t.station.id == station.id).length,
      'is_active': true,
    };
  }

  /// Récupère les perturbations (mock)
  Future<List<Map<String, dynamic>>> getDisruptions() async {
    // Retourner quelques perturbations mock pour tester
    return [
      {
        'id': 'mock_disruption_1',
        'severity': 'delay',
        'message': 'Retards sur certaines lignes',
        'affected_lines': ['TGV', 'TER'],
        'start_time': _getNow().toIso8601String(),
        'end_time': _getNow().add(const Duration(hours: 2)).toIso8601String(),
      },
    ];
  }

  /// Récupère les perturbations pour une ligne (mock)
  Future<List<Map<String, dynamic>>> getDisruptionsForLine(String lineId) async {
    return getDisruptions();
  }

  /// Récupère les perturbations pour une gare (mock)
  Future<List<Map<String, dynamic>>> getDisruptionsForStation(String stationId) async {
    return getDisruptions();
  }

  /// Récupère les informations d'une ligne (mock)
  Future<Map<String, dynamic>> getLineInfo(String lineId) async {
    return {
      'line_id': lineId,
      'name': 'Ligne mock $lineId',
      'color': '#FF0000',
      'text_color': '#FFFFFF',
      'transport_mode': 'train',
      'commercial_mode': 'TGV',
    };
  }

  /// Récupère les gares d'une ligne (mock)
  Future<List<Station>> getLineStations(String lineId) async {
    // Retourner toutes les stations mock
    final allStations = <Station>[];
    final trips = MockData.getMockTrips();

    for (final trip in trips) {
      if (!allStations.any((s) => s.id == trip.departureStation.id)) {
        allStations.add(trip.departureStation);
      }
      if (!allStations.any((s) => s.id == trip.arrivalStation.id)) {
        allStations.add(trip.arrivalStation);
      }
    }

    return allStations;
  }

  /// Récupère les horaires d'une ligne (mock)
  Future<List<Map<String, dynamic>>> getLineSchedules(String lineId, DateTime dateTime) async {
    final now = _getNow();
    return [
      {
        'line_id': lineId,
        'datetime': now.add(const Duration(hours: 1)).toIso8601String(),
        'departure_time': now.add(const Duration(hours: 1)).toIso8601String(),
        'arrival_time': now.add(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'line_id': lineId,
        'datetime': now.add(const Duration(hours: 3)).toIso8601String(),
        'departure_time': now.add(const Duration(hours: 3)).toIso8601String(),
        'arrival_time': now.add(const Duration(hours: 4)).toIso8601String(),
      },
    ];
  }

  Future<List<Train>> getNextArrivalsForLine(Station station, String lineId) async {
    return _trains.where((train) => train.station.id == station.id).toList();
  }

  /// Récupère les rapports de trafic (mock)
  Future<List<Map<String, dynamic>>> getTrafficReports() async {
    return [
      {
        'id': 'mock_traffic_1',
        'severity': 'normal',
        'message': 'Trafic normal',
        'timestamp': _getNow().toIso8601String(),
      },
    ];
  }

  /// Récupère les rapports de trafic pour une ligne (mock)
  Future<List<Map<String, dynamic>>> getTrafficReportsForLine(String lineId) async {
    return getTrafficReports();
  }

  /// Récupère les rapports de trafic pour une gare (mock)
  Future<List<Map<String, dynamic>>> getTrafficReportsForStation(String stationId) async {
    return getTrafficReports();
  }
}
