import '../models/trip.dart';
import '../models/station.dart';

abstract class TripStorage {
  Future<void> saveTrip(Trip trip);
  Future<List<Trip>> getAllTrips();
  Future<void> deleteTrip(String tripId);
  Future<void> clearAllTrips();
}

class TripService {
  final TripStorage _storage;

  const TripService(this._storage);

  /// Sauvegarde un trajet (création ou mise à jour)
  Future<void> saveTrip(Trip trip) async {
    await _storage.saveTrip(trip);
  }

  /// Récupère tous les trajets
  Future<List<Trip>> getAllTrips() async {
    return await _storage.getAllTrips();
  }

  /// Supprime un trajet
  Future<void> deleteTrip(String tripId) async {
    await _storage.deleteTrip(tripId);
  }

  /// Supprime tous les trajets
  Future<void> clearAllTrips() async {
    await _storage.clearAllTrips();
  }

  /// Supprime un trajet et tous les doublons (mêmes gares et même heure)
  Future<void> deleteTripAndSimilar(Trip tripToDelete) async {
    final all = await _storage.getAllTrips();
    final remaining = all.where((t) {
      final sameDeparture =
          t.departureStation.name == tripToDelete.departureStation.name;
      final sameArrival =
          t.arrivalStation.name == tripToDelete.arrivalStation.name;
      final sameTime = t.time.hour == tripToDelete.time.hour &&
          t.time.minute == tripToDelete.time.minute;
      final isSame = sameDeparture && sameArrival && sameTime;
      return !isSame;
    }).toList();

    await _storage.clearAllTrips();
    for (final t in remaining) {
      await _storage.saveTrip(t);
    }
  }

  /// Récupère les trajets pour un jour spécifique
  List<Trip> getTripsByDay(List<Trip> trips, DayOfWeek day) {
    return trips.where((trip) => trip.days.contains(day)).toList();
  }

  /// Récupère les trajets pour une gare de départ
  List<Trip> getTripsByDepartureStation(List<Trip> trips, Station station) {
    return trips
        .where((trip) => trip.departureStation.id == station.id)
        .toList();
  }

  /// Récupère les trajets pour une gare d'arrivée
  List<Trip> getTripsByArrivalStation(List<Trip> trips, Station station) {
    return trips.where((trip) => trip.arrivalStation.id == station.id).toList();
  }

  /// Récupère les trajets actifs
  List<Trip> getActiveTrips(List<Trip> trips) {
    return trips.where((trip) => trip.isActive).toList();
  }

  /// Récupère les trajets pour aujourd'hui
  List<Trip> getTodayTrips(List<Trip> trips) {
    return trips.where((trip) => trip.isForToday).toList();
  }

  /// Récupère les trajets actifs pour aujourd'hui
  List<Trip> getActiveTodayTrips(List<Trip> trips) {
    return trips.where((trip) => trip.isActiveToday).toList();
  }
}
