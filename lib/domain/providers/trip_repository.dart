import '../models/trip.dart';

abstract class TripRepository {
  Future<void> saveTrip(Trip trip);
  Future<List<Trip>> getAllTrips();
  Future<void> deleteTrip(String tripId);
  Future<void> updateTrip(Trip trip);
}
