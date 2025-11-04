import '../../../domain/models/trip.dart';
import '../../../domain/services/trip_service.dart';
import 'data/mock_data.dart';

/// Implémentation mock de TripStorage
class MockTripStorage implements TripStorage {
  final List<Trip> _trips = [];

  MockTripStorage() {
    // Initialiser avec les données mock
    _trips.addAll(MockData.getMockTrips());
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
    } else {
      _trips.add(trip);
    }
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    return List.from(_trips);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((trip) => trip.id == tripId);
  }

  @override
  Future<void> clearAllTrips() async {
    _trips.clear();
  }
}

