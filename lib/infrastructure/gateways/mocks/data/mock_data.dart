import '../../../../domain/models/trip.dart' as domain;
import '../../../../domain/models/train.dart';
import '../../../../domain/models/station.dart';

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
    final parisNord = Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    );

    final lilleEurope = Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    );

    final lyonPartDieu = Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Lyon Part-Dieu',
      latitude: 45.7606,
      longitude: 4.8604,
    );

    final marseilleStCharles = Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Marseille St-Charles',
      latitude: 43.3032,
      longitude: 5.3842,
    );

    final bordeauxStJean = Station(
      id: 'stop_point:SNCF:87581009',
      name: 'Bordeaux St-Jean',
      latitude: 44.8258,
      longitude: -0.5563,
    );

    return [
      domain.Trip(
        id: 'mock_trip_1',
        departureStation: parisNord,
        arrivalStation: lilleEurope,
        days: [
          domain.DayOfWeek.monday,
          domain.DayOfWeek.tuesday,
          domain.DayOfWeek.wednesday,
          domain.DayOfWeek.thursday,
          domain.DayOfWeek.friday
        ],
        time: const domain.TimeOfDay(hour: 7, minute: 30),
        isActive: true,
        notificationsEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      domain.Trip(
        id: 'mock_trip_2',
        departureStation: parisNord,
        arrivalStation: lyonPartDieu,
        days: [domain.DayOfWeek.monday, domain.DayOfWeek.wednesday, domain.DayOfWeek.friday],
        time: const domain.TimeOfDay(hour: 8, minute: 15),
        isActive: true,
        notificationsEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      domain.Trip(
        id: 'mock_trip_3',
        departureStation: lyonPartDieu,
        arrivalStation: marseilleStCharles,
        days: [domain.DayOfWeek.tuesday, domain.DayOfWeek.thursday],
        time: const domain.TimeOfDay(hour: 9, minute: 0),
        isActive: true,
        notificationsEnabled: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      domain.Trip(
        id: 'mock_trip_4',
        departureStation: parisNord,
        arrivalStation: bordeauxStJean,
        days: [domain.DayOfWeek.saturday, domain.DayOfWeek.sunday],
        time: const domain.TimeOfDay(hour: 10, minute: 45),
        isActive: false,
        notificationsEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      domain.Trip(
        id: 'mock_trip_5',
        departureStation: lilleEurope,
        arrivalStation: parisNord,
        days: [
          domain.DayOfWeek.monday,
          domain.DayOfWeek.tuesday,
          domain.DayOfWeek.wednesday,
          domain.DayOfWeek.thursday,
          domain.DayOfWeek.friday
        ],
        time: const domain.TimeOfDay(hour: 18, minute: 30),
        isActive: true,
        notificationsEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  static List<Train> getMockTrains() {
    final now = DateTime.now();
    final parisNord = Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    );

    final lilleEurope = Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    );

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
        delayMinutes: null,
        station: parisNord,
        additionalInfo: [],
      ),
      Train(
        id: 'mock_train_2',
        direction: 'Lille Europe',
        departureTime: now.add(const Duration(minutes: 45)),
        baseDepartureTime: now.add(const Duration(minutes: 45)),
        arrivalTime: now.add(const Duration(hours: 1, minutes: 35)),
        baseArrivalTime: now.add(const Duration(hours: 1, minutes: 35)),
        status: TrainStatus.onTime,
        delayMinutes: null,
        station: parisNord,
        additionalInfo: [],
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
      ),
      Train(
        id: 'mock_train_4',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 1, minutes: 10)),
        baseDepartureTime: now.add(const Duration(hours: 1, minutes: 10)),
        arrivalTime: now.add(const Duration(hours: 2, minutes: 43)),
        baseArrivalTime: now.add(const Duration(hours: 2, minutes: 43)),
        status: TrainStatus.onTime,
        delayMinutes: null,
        station: parisNord,
        additionalInfo: [],
      ),
      Train(
        id: 'mock_train_5',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 2, minutes: 5)),
        baseDepartureTime: now.add(const Duration(hours: 2, minutes: 0)),
        arrivalTime: now.add(const Duration(hours: 3, minutes: 33)),
        baseArrivalTime: now.add(const Duration(hours: 3, minutes: 28)),
        status: TrainStatus.delayed,
        delayMinutes: 5,
        station: parisNord,
        additionalInfo: [],
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
        delayMinutes: null,
        station: lilleEurope,
        additionalInfo: [],
      ),
      // Train annulé pour tester ce cas
      Train(
        id: 'mock_train_7',
        direction: 'Lyon Part-Dieu',
        departureTime: now.add(const Duration(hours: 3, minutes: 0)),
        baseDepartureTime: now.add(const Duration(hours: 3, minutes: 0)),
        arrivalTime: null,
        baseArrivalTime: null,
        status: TrainStatus.cancelled,
        delayMinutes: null,
        station: parisNord,
        additionalInfo: ['Train annulé'],
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
}
