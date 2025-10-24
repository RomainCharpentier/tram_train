import '../models/trip.dart';
import '../models/station.dart';
import '../providers/trip_repository.dart';

class ManageTripUseCase {
  final TripRepository _tripRepository;

  const ManageTripUseCase(this._tripRepository);

  Future<Trip> createTrip({
    required Station station,
    required String dayOfWeek,
    required String time,
  }) async {
    try {
      final trip = Trip(
        id: Trip.generateId(),
        station: station,
        dayOfWeek: dayOfWeek,
        time: time,
        createdAt: DateTime.now(),
      );
      
      await _tripRepository.saveTrip(trip);
      return trip;
    } catch (e) {
      throw ManageTripException('Erreur lors de la création du trajet: $e');
    }
  }

  Future<List<Trip>> getAllTrips() async {
    try {
      return await _tripRepository.getAllTrips();
    } catch (e) {
      throw ManageTripException('Erreur lors de la récupération des trajets: $e');
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripRepository.deleteTrip(tripId);
    } catch (e) {
      throw ManageTripException('Erreur lors de la suppression du trajet: $e');
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      await _tripRepository.updateTrip(trip);
    } catch (e) {
      throw ManageTripException('Erreur lors de la mise à jour du trajet: $e');
    }
  }
}

class ManageTripException implements Exception {
  final String message;
  const ManageTripException(this.message);
  
  @override
  String toString() => 'ManageTripException: $message';
}
