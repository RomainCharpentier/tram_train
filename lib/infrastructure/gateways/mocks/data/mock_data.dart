import '../../../../domain/models/trip.dart' as domain;
import '../../../../domain/models/train.dart';
import '../../../../domain/models/station.dart';
import '../mock_favorite_station_storage.dart';

/// Données mock pour tester l'application
///
/// Cas de test couverts :
/// - Trajets avec trains trouvés : Paris → Lille, Paris → Lyon, Lille → Paris
/// - Trajets sans trains trouvés (état vide) : Lyon → Marseille, Paris → Bordeaux
/// - Trajets actifs/inactifs
/// - Trajets avec notifications activées/désactivées
/// - Trains à l'heure, en retard, annulés
/// - Trains avec différents statuts et heures de départ
class MockData {
  static List<domain.Trip> getMockTrips() {
    const parisNord = Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    );

    const lilleEurope = Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    );

    const lyonPartDieu = Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Lyon Part-Dieu',
      latitude: 45.7606,
      longitude: 4.8604,
    );

    const marseilleStCharles = Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Marseille St-Charles',
      latitude: 43.3032,
      longitude: 5.3842,
    );

    const bordeauxStJean = Station(
      id: 'stop_point:SNCF:87581009',
      name: 'Bordeaux St-Jean',
      latitude: 44.8258,
      longitude: -0.5563,
    );

    const rennes = Station(
      id: 'stop_point:SNCF:87471003',
      name: 'Rennes',
      latitude: 48.1033,
      longitude: -1.6720,
    );

    const nantes = Station(
      id: 'stop_point:SNCF:87481002',
      name: 'Nantes',
      latitude: 47.2173,
      longitude: -1.5534,
    );

    MockFavoriteStationStorage.seedFavorites([
      parisNord,
      lyonPartDieu,
      rennes,
      nantes,
    ]);

    return [
      domain.Trip(
        id: 'mock_trip_1',
        departureStation: parisNord,
        arrivalStation: lilleEurope,
        day: domain.DayOfWeek.monday,
        time: const domain.TimeOfDay(hour: 7, minute: 30),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      domain.Trip(
        id: 'mock_trip_2',
        departureStation: parisNord,
        arrivalStation: lyonPartDieu,
        day: domain.DayOfWeek.monday,
        time: const domain.TimeOfDay(hour: 8, minute: 15),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      domain.Trip(
        id: 'mock_trip_3',
        departureStation: lyonPartDieu,
        arrivalStation: marseilleStCharles,
        day: domain.DayOfWeek.tuesday,
        time: const domain.TimeOfDay(hour: 9, minute: 0),
        notificationsEnabled: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      domain.Trip(
        id: 'mock_trip_4',
        departureStation: parisNord,
        arrivalStation: bordeauxStJean,
        day: domain.DayOfWeek.saturday,
        time: const domain.TimeOfDay(hour: 10, minute: 45),
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      domain.Trip(
        id: 'mock_trip_5',
        departureStation: lilleEurope,
        arrivalStation: parisNord,
        day: domain.DayOfWeek.monday,
        time: const domain.TimeOfDay(hour: 18, minute: 30),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  static List<Train> getMockTrains([DateTime? now]) {
    now ??= DateTime(2025, 1, 6, 7);
    const parisNord = Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    );

    const lilleEurope = Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    );

    String buildExternalUrl(String trainNumber, Station departureStation) {
      final code = departureStation.id.split(':').last;
      return 'https://www.sncf-connect.com/journeyTimelineDetails?number=$trainNumber&departureCode=$code';
    }

    return [
      // Trains depuis Paris Nord vers Lille (pour le trajet 1)
      Train(
        id: 'mock_train_1',
        direction: 'Lille Europe',
        departureTime: now.add(const Duration(minutes: 15)),
        baseDepartureTime: now.add(const Duration(minutes: 15)),
        arrivalTime: now.add(const Duration(hours: 1, minutes: 5)),
        baseArrivalTime: now.add(const Duration(hours: 1, minutes: 5)),
        status: TrainStatus.onTime,
        station: parisNord,
        additionalInfo: [],
        externalUrl: buildExternalUrl('5300', parisNord),
      ),
      Train(
        id: 'mock_train_2',
        direction: 'Lille Europe',
        departureTime: now.add(const Duration(minutes: 45)),
        baseDepartureTime: now.add(const Duration(minutes: 45)),
        arrivalTime: now.add(const Duration(hours: 1, minutes: 35)),
        baseArrivalTime: now.add(const Duration(hours: 1, minutes: 35)),
        status: TrainStatus.onTime,
        station: parisNord,
        additionalInfo: [],
        externalUrl: buildExternalUrl('5302', parisNord),
      ),
      // Trains depuis Paris Nord vers Lyon (pour le trajet 2)
      Train(
        id: 'mock_train_3',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(minutes: 32)),
        baseDepartureTime: now.add(const Duration(minutes: 30)),
        arrivalTime: now.add(const Duration(hours: 2, minutes: 5)),
        baseArrivalTime: now.add(const Duration(hours: 2, minutes: 3)),
        status: TrainStatus.delayed,
        delayMinutes: 2,
        station: parisNord,
        additionalInfo: [],
        departurePlatform: '12',
        arrivalPlatform: 'H',
        externalUrl: buildExternalUrl('6612', parisNord),
      ),
      Train(
        id: 'mock_train_4',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 1, minutes: 10)),
        baseDepartureTime: now.add(const Duration(hours: 1, minutes: 10)),
        arrivalTime: now.add(const Duration(hours: 2, minutes: 43)),
        baseArrivalTime: now.add(const Duration(hours: 2, minutes: 43)),
        status: TrainStatus.onTime,
        station: parisNord,
        additionalInfo: [],
        departurePlatform: '14',
        arrivalPlatform: 'J',
        externalUrl: buildExternalUrl('6614', parisNord),
      ),
      Train(
        id: 'mock_train_5',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 2, minutes: 5)),
        baseDepartureTime: now.add(const Duration(hours: 2)),
        arrivalTime: now.add(const Duration(hours: 3, minutes: 33)),
        baseArrivalTime: now.add(const Duration(hours: 3, minutes: 28)),
        status: TrainStatus.delayed,
        delayMinutes: 5,
        station: parisNord,
        additionalInfo: [],
        departurePlatform: '6',
        arrivalPlatform: 'K',
        externalUrl: buildExternalUrl('6616', parisNord),
      ),
      // Train depuis Lille vers Paris (pour le trajet 5)
      Train(
        id: 'mock_train_6',
        direction: 'Paris Nord',
        departureTime: now.add(const Duration(hours: 3, minutes: 20)),
        baseDepartureTime: now.add(const Duration(hours: 3, minutes: 20)),
        arrivalTime: now.add(const Duration(hours: 4, minutes: 10)),
        baseArrivalTime: now.add(const Duration(hours: 4, minutes: 10)),
        status: TrainStatus.onTime,
        station: lilleEurope,
        additionalInfo: [],
        externalUrl: buildExternalUrl('7910', lilleEurope),
      ),
      // Train annulé pour tester ce cas
      Train(
        id: 'mock_train_7',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 3)),
        baseDepartureTime: now.add(const Duration(hours: 3)),
        status: TrainStatus.cancelled,
        station: parisNord,
        additionalInfo: ['Train annulé'],
        externalUrl: buildExternalUrl('6620', parisNord),
      ),
      // Train en cours (départ dans le passé, arrivée dans le futur) - Paris → Lille
      Train(
        id: 'mock_train_in_progress',
        direction: 'Lille Europe',
        departureTime: now.subtract(const Duration(minutes: 30)), // Départ il y a 30 min
        baseDepartureTime: now.subtract(const Duration(minutes: 30)),
        arrivalTime: now.add(const Duration(minutes: 35)), // Arrivée dans 35 min
        baseArrivalTime: now.add(const Duration(minutes: 35)),
        status: TrainStatus.onTime,
        station: parisNord,
        additionalInfo: [],
        externalUrl: buildExternalUrl('5308', parisNord),
      ),
    ];
  }

  /// Retourne les trains mock pour une station spécifique
  static List<Train> getMockTrainsForStation(Station station) {
    final allTrains = getMockTrains();
    return allTrains.where((train) => train.station.id == station.id).toList();
  }

  /// Retourne les trains mock pour un trajet (départ → arrivée)
  static List<Train> getMockTrainsForTrip(domain.Trip trip) {
    final allTrains = getMockTrains();
    // Filtrer les trains qui correspondent au trajet
    return allTrains.where((train) {
      // Vérifier que le train part de la bonne station
      if (train.station.id != trip.departureStation.id) return false;
      // Vérifier que la direction contient la destination
      return train.direction.contains(trip.arrivalStation.name);
    }).toList();
  }

  /// Retourne les stations intermédiaires pour un trajet (mock)
  static List<Station> getIntermediateStationsForTrip(domain.Trip trip) {
    // Définir les stations intermédiaires selon le trajet
    const parisNord = Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    );

    const lilleEurope = Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    );

    const lyonPartDieu = Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Lyon Part-Dieu',
      latitude: 45.7606,
      longitude: 4.8604,
    );

    const marseilleStCharles = Station(
      id: 'stop_point:SNCF:87751000',
      name: 'Marseille St-Charles',
      latitude: 43.3032,
      longitude: 5.3842,
    );

    const bordeauxStJean = Station(
      id: 'stop_point:SNCF:87581009',
      name: 'Bordeaux St-Jean',
      latitude: 44.8258,
      longitude: -0.5563,
    );

    // Stations intermédiaires réalistes
    const arras = Station(
      id: 'stop_point:SNCF:87286000',
      name: 'Arras',
      latitude: 50.2914,
      longitude: 2.7811,
    );

    const creil = Station(
      id: 'stop_point:SNCF:87276004',
      name: 'Creil',
      latitude: 49.2578,
      longitude: 2.4697,
    );

    const macon = Station(
      id: 'stop_point:SNCF:87724000',
      name: 'Mâcon-Ville',
      latitude: 46.3078,
      longitude: 4.8322,
    );

    const valence = Station(
      id: 'stop_point:SNCF:87760000',
      name: 'Valence TGV',
      latitude: 44.9908,
      longitude: 4.9431,
    );

    const avignon = Station(
      id: 'stop_point:SNCF:87751000',
      name: 'Avignon TGV',
      latitude: 43.9214,
      longitude: 4.7858,
    );

    const tours = Station(
      id: 'stop_point:SNCF:87571000',
      name: 'Tours',
      latitude: 47.3925,
      longitude: 0.6944,
    );

    const poitiers = Station(
      id: 'stop_point:SNCF:87585000',
      name: 'Poitiers',
      latitude: 46.5808,
      longitude: 0.3406,
    );

    // Retourner les stations intermédiaires selon le trajet
    if (trip.departureStation.id == parisNord.id && trip.arrivalStation.id == lilleEurope.id) {
      // Paris → Lille : Arras, Creil
      return [arras, creil];
    } else if (trip.departureStation.id == parisNord.id &&
        trip.arrivalStation.id == lyonPartDieu.id) {
      // Paris → Lyon : Mâcon
      return [macon];
    } else if (trip.departureStation.id == lyonPartDieu.id &&
        trip.arrivalStation.id == marseilleStCharles.id) {
      // Lyon → Marseille : Valence, Avignon
      return [valence, avignon];
    } else if (trip.departureStation.id == parisNord.id &&
        trip.arrivalStation.id == bordeauxStJean.id) {
      // Paris → Bordeaux : Tours, Poitiers
      return [tours, poitiers];
    } else if (trip.departureStation.id == lilleEurope.id &&
        trip.arrivalStation.id == parisNord.id) {
      // Lille → Paris : Arras, Creil
      return [creil, arras];
    }

    // Par défaut, retourner une liste vide ou quelques stations génériques
    return [];
  }
}
