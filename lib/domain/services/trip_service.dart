import '../models/trip.dart';
import '../models/station.dart';

abstract class TripStorage {
  Future<void> saveTrip(Trip trip);
  Future<List<Trip>> getAllTrips();
  Future<void> deleteTrip(String tripId);
}

class TripService {
  final TripStorage _storage;

  const TripService(this._storage);

  Future<Trip> createTrip({
    required Station station,
    required String dayOfWeek,
    required String time,
  }) async {
    final trip = Trip(
      id: Trip.generateId(),
      station: station,
      dayOfWeek: dayOfWeek,
      time: time,
      createdAt: DateTime.now(),
    );
    
    await _storage.saveTrip(trip);
    return trip;
  }

  Future<List<Trip>> getAllTrips() async {
    return await _storage.getAllTrips();
  }

  Future<void> deleteTrip(String tripId) async {
    await _storage.deleteTrip(tripId);
  }

  Future<void> updateTrip(Trip trip) async {
    await _storage.saveTrip(trip);
  }

  List<Trip> getTripsByDay(List<Trip> trips, String dayOfWeek) {
    return trips.where((trip) => trip.dayOfWeek == dayOfWeek).toList();
  }

  List<Trip> getTripsByStation(List<Trip> trips, Station station) {
    return trips.where((trip) => trip.station.id == station.id).toList();
  }
}
