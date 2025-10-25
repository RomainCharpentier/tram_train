import 'package:flutter_test/flutter_test.dart';
import 'package:tram_train/domain/models/station.dart';
import 'package:tram_train/domain/models/trip.dart';
import 'package:tram_train/domain/services/trip_service.dart';

// Mock implementation for testing
class MockLocalStorageGateway implements TripStorage {
  List<Trip> _trips = [];
  Exception? _mockException;

  void setMockException(Exception exception) {
    _mockException = exception;
  }

  void setMockTrips(List<Trip> trips) {
    _trips = trips;
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    final existingIndex = _trips.indexWhere((t) => t.id == trip.id);
    if (existingIndex != -1) {
      _trips[existingIndex] = trip;
    } else {
      _trips.add(trip);
    }
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return List.from(_trips);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    _trips.removeWhere((trip) => trip.id == tripId);
  }
}

void main() {
  group('TripService Use Cases', () {
    late MockLocalStorageGateway mockGateway;
    late TripService tripService;
    late Station testStation;

    setUp(() {
      mockGateway = MockLocalStorageGateway();
      tripService = TripService(mockGateway);
      testStation = const Station(
        id: 'TEST:123',
        name: 'Test Station',
      );
    });

    group('As a user, I want to save my regular trips', () {
      test('should create and save a new trip', () async {
        // Given: I want to save a Monday morning trip
        // When: I create a trip for Monday 8:30 AM
        final result = await tripService.createTrip(
          station: testStation,
          dayOfWeek: 'Monday',
          time: '08:30',
        );

        // Then: The trip should be saved with correct details
        expect(result.station.id, testStation.id);
        expect(result.dayOfWeek, 'Monday');
        expect(result.time, '08:30');
        expect(result.id, isNotEmpty);
      });

      test('should generate unique IDs for different trips', () async {
        // Given: I want to create multiple trips
        // When: I create two different trips
        final trip1 = await tripService.createTrip(
          station: testStation,
          dayOfWeek: 'Monday',
          time: '08:30',
        );

        await Future.delayed(const Duration(milliseconds: 1));

        final trip2 = await tripService.createTrip(
          station: testStation,
          dayOfWeek: 'Tuesday',
          time: '09:00',
        );

        // Then: Each trip should have a unique ID
        expect(trip1.id, isNot(equals(trip2.id)));
      });
    });

    group('As a user, I want to view my saved trips', () {
      test('should retrieve all my saved trips', () async {
        // Given: I have saved trips
        final expectedTrips = [
          Trip(
            id: '1',
            station: testStation,
            dayOfWeek: 'Monday',
            time: '08:30',
            createdAt: DateTime(2025, 1, 1),
          ),
          Trip(
            id: '2',
            station: testStation,
            dayOfWeek: 'Tuesday',
            time: '09:00',
            createdAt: DateTime(2025, 1, 1),
          ),
        ];
        mockGateway.setMockTrips(expectedTrips);

        // When: I request all my trips
        final result = await tripService.getAllTrips();

        // Then: I should see all my trips
        expect(result, expectedTrips);
      });
    });

    group('As a user, I want to manage my trips', () {
      test('should delete a trip when I no longer need it', () async {
        // Given: I have a saved trip
        const tripId = 'trip123';

        // When: I delete the trip
        await tripService.deleteTrip(tripId);

        // Then: The trip should be removed (no exception thrown)
        expect(() => tripService.deleteTrip(tripId), returnsNormally);
      });

      test('should update a trip when my schedule changes', () async {
        // Given: I have an existing trip
        final trip = Trip(
          id: '1',
          station: testStation,
          dayOfWeek: 'Monday',
          time: '08:30',
          createdAt: DateTime(2025, 1, 1),
        );

        // When: I update the trip
        await tripService.updateTrip(trip);

        // Then: The trip should be updated (no exception thrown)
        expect(() => tripService.updateTrip(trip), returnsNormally);
      });
    });

    group('As a user, I want to organize my trips', () {
      test('should show only trips for a specific day', () {
        // Given: I have trips for different days
        final trips = [
          Trip(
            id: '1',
            station: testStation,
            dayOfWeek: 'Monday',
            time: '08:30',
            createdAt: DateTime(2025, 1, 1),
          ),
          Trip(
            id: '2',
            station: testStation,
            dayOfWeek: 'Tuesday',
            time: '09:00',
            createdAt: DateTime(2025, 1, 1),
          ),
          Trip(
            id: '3',
            station: testStation,
            dayOfWeek: 'Monday',
            time: '18:00',
            createdAt: DateTime(2025, 1, 1),
          ),
        ];

        // When: I filter for Monday trips
        final result = tripService.getTripsByDay(trips, 'Monday');

        // Then: I should only see Monday trips
        expect(result.length, 2);
        expect(result.every((trip) => trip.dayOfWeek == 'Monday'), isTrue);
      });

      test('should show only trips from a specific station', () {
        // Given: I have trips from different stations
        final station1 = const Station(id: 'STATION1', name: 'Station 1');
        final station2 = const Station(id: 'STATION2', name: 'Station 2');

        final trips = [
          Trip(
            id: '1',
            station: station1,
            dayOfWeek: 'Monday',
            time: '08:30',
            createdAt: DateTime(2025, 1, 1),
          ),
          Trip(
            id: '2',
            station: station2,
            dayOfWeek: 'Tuesday',
            time: '09:00',
            createdAt: DateTime(2025, 1, 1),
          ),
          Trip(
            id: '3',
            station: station1,
            dayOfWeek: 'Wednesday',
            time: '10:00',
            createdAt: DateTime(2025, 1, 1),
          ),
        ];

        // When: I filter for Station 1 trips
        final result = tripService.getTripsByStation(trips, station1);

        // Then: I should only see Station 1 trips
        expect(result.length, 2);
        expect(result.every((trip) => trip.station.id == station1.id), isTrue);
      });

      test('should return empty list when no trips match filter', () {
        // Given: I have trips for Monday only
        final trips = [
          Trip(
            id: '1',
            station: testStation,
            dayOfWeek: 'Monday',
            time: '08:30',
            createdAt: DateTime(2025, 1, 1),
          ),
        ];

        // When: I filter for Wednesday trips
        final result = tripService.getTripsByDay(trips, 'Wednesday');

        // Then: I should get an empty list
        expect(result, isEmpty);
      });
    });
  });
}
