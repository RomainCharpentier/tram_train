import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/models/trip.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/services/trip_service.dart';

class MockTripStorage implements TripStorage {
  final List<Trip> _trips = [];

  @override
  Future<void> saveTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
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

void main() {
  group('TripService', () {
    late TripService tripService;
    late MockTripStorage mockStorage;

    setUp(() {
      mockStorage = MockTripStorage();
      tripService = TripService(mockStorage);
    });

    test('should save trip successfully', () async {
      // Arrange
      const station1 = Station(id: '1', name: 'Station 1');
      const station2 = Station(id: '2', name: 'Station 2');
      final trip = Trip(
        id: 'trip_1',
        departureStation: station1,
        arrivalStation: station2,
        days: [DayOfWeek.monday, DayOfWeek.friday],
        time: const TimeOfDay(hour: 8, minute: 30),
        createdAt: DateTime.now(),
      );

      // Act
      await tripService.saveTrip(trip);

      // Assert
      final trips = await tripService.getAllTrips();
      expect(trips.length, 1);
      expect(trips.first.id, 'trip_1');
    });

    test('should get all trips', () async {
      // Arrange
      const station1 = Station(id: '1', name: 'Station 1');
      const station2 = Station(id: '2', name: 'Station 2');
      final trip1 = Trip(
        id: 'trip_1',
        departureStation: station1,
        arrivalStation: station2,
        days: [DayOfWeek.monday],
        time: const TimeOfDay(hour: 8, minute: 30),
        createdAt: DateTime.now(),
      );
      final trip2 = Trip(
        id: 'trip_2',
        departureStation: station2,
        arrivalStation: station1,
        days: [DayOfWeek.friday],
        time: const TimeOfDay(hour: 17, minute: 0),
        createdAt: DateTime.now(),
      );

      await tripService.saveTrip(trip1);
      await tripService.saveTrip(trip2);

      // Act
      final trips = await tripService.getAllTrips();

      // Assert
      expect(trips.length, 2);
    });

    test('should delete trip successfully', () async {
      // Arrange
      const station1 = Station(id: '1', name: 'Station 1');
      const station2 = Station(id: '2', name: 'Station 2');
      final trip = Trip(
        id: 'trip_1',
        departureStation: station1,
        arrivalStation: station2,
        days: [DayOfWeek.monday],
        time: const TimeOfDay(hour: 8, minute: 30),
        createdAt: DateTime.now(),
      );
      await tripService.saveTrip(trip);

      // Act
      await tripService.deleteTrip('trip_1');

      // Assert
      final trips = await tripService.getAllTrips();
      expect(trips.length, 0);
    });

    test('should filter trips by day', () async {
      // Arrange
      const station1 = Station(id: '1', name: 'Station 1');
      const station2 = Station(id: '2', name: 'Station 2');
      final mondayTrip = Trip(
        id: 'trip_1',
        departureStation: station1,
        arrivalStation: station2,
        days: [DayOfWeek.monday],
        time: const TimeOfDay(hour: 8, minute: 30),
        createdAt: DateTime.now(),
      );
      final fridayTrip = Trip(
        id: 'trip_2',
        departureStation: station2,
        arrivalStation: station1,
        days: [DayOfWeek.friday],
        time: const TimeOfDay(hour: 17, minute: 0),
        createdAt: DateTime.now(),
      );

      await tripService.saveTrip(mondayTrip);
      await tripService.saveTrip(fridayTrip);

      // Act
      final allTrips = await tripService.getAllTrips();
      final mondayTrips = tripService.getTripsByDay(allTrips, DayOfWeek.monday);

      // Assert
      expect(mondayTrips.length, 1);
      expect(mondayTrips.first.id, 'trip_1');
    });

    test('should get active trips', () async {
      // Arrange
      const station1 = Station(id: '1', name: 'Station 1');
      const station2 = Station(id: '2', name: 'Station 2');
      final activeTrip = Trip(
        id: 'trip_1',
        departureStation: station1,
        arrivalStation: station2,
        days: [DayOfWeek.monday],
        time: const TimeOfDay(hour: 8, minute: 30),
        isActive: true,
        createdAt: DateTime.now(),
      );
      final inactiveTrip = Trip(
        id: 'trip_2',
        departureStation: station2,
        arrivalStation: station1,
        days: [DayOfWeek.friday],
        time: const TimeOfDay(hour: 17, minute: 0),
        isActive: false,
        createdAt: DateTime.now(),
      );

      await tripService.saveTrip(activeTrip);
      await tripService.saveTrip(inactiveTrip);

      // Act
      final allTrips = await tripService.getAllTrips();
      final activeTrips = tripService.getActiveTrips(allTrips);

      // Assert
      expect(activeTrips.length, 1);
      expect(activeTrips.first.id, 'trip_1');
    });
  });
}
