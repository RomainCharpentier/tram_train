import 'package:flutter_test/flutter_test.dart';
import 'package:tram_train/domain/models/station.dart';
import 'package:tram_train/domain/models/train.dart';
import 'package:tram_train/domain/services/train_service.dart';

// Mock implementation for testing
class MockSncfGateway implements TrainGateway {
  List<Train>? _mockTrains;
  Exception? _mockException;

  void setMockTrains(List<Train> trains) {
    _mockTrains = trains;
  }

  void setMockException(Exception exception) {
    _mockException = exception;
  }

  @override
  Future<List<Train>> getDepartures(Station station) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }

  @override
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }
}

void main() {
  group('TrainService Use Cases', () {
    late MockSncfGateway mockGateway;
    late TrainService trainService;
    late Station testStation;

    setUp(() {
      mockGateway = MockSncfGateway();
      trainService = TrainService(mockGateway);
      testStation = const Station(
        id: 'TEST:123',
        name: 'Test Station',
      );
    });

    group('As a user, I want to see train departures', () {
      test('should return trains when API is available', () async {
        // Given: API returns train data
        final expectedTrains = [
          Train.fromTimes(
            id: '1',
            direction: 'Paris',
            departureTime: DateTime(2025, 1, 1, 10, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 10, 0),
            station: testStation,
            additionalInfo: [],
          ),
        ];
        mockGateway.setMockTrains(expectedTrains);

        // When: I request train departures
        final result = await trainService.getDepartures(testStation);

        // Then: I should see the trains
        expect(result, expectedTrains);
      });

      test('should handle API errors gracefully', () async {
        // Given: API is unavailable
        mockGateway.setMockException(Exception('API Error'));

        // When: I request train departures
        // Then: I should get an error
        expect(
          () => trainService.getDepartures(testStation),
          throwsException,
        );
      });
    });

    group('As a user, I want to filter trains by destination', () {
      test('should show only trains going to my destination', () {
        // Given: I have trains to different destinations
        final trains = [
          Train.fromTimes(
            id: '1',
            direction: 'Paris',
            departureTime: DateTime(2025, 1, 1, 10, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 10, 0),
            station: testStation,
            additionalInfo: [],
          ),
          Train.fromTimes(
            id: '2',
            direction: 'Nantes',
            departureTime: DateTime(2025, 1, 1, 11, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 11, 0),
            station: testStation,
            additionalInfo: [],
          ),
        ];

        // When: I filter by destination "Paris"
        final result = trainService.filterByDirection(trains, 'Paris');

        // Then: I should only see Paris trains
        expect(result.length, 1);
        expect(result.first.direction, 'Paris');
      });

      test('should be case insensitive when filtering', () {
        // Given: I have trains with mixed case directions
        final trains = [
          Train.fromTimes(
            id: '1',
            direction: 'Paris',
            departureTime: DateTime(2025, 1, 1, 10, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 10, 0),
            station: testStation,
            additionalInfo: [],
          ),
        ];

        // When: I search with lowercase "paris"
        final result = trainService.filterByDirection(trains, 'paris');

        // Then: I should still find the train
        expect(result.length, 1);
      });
    });

    group('As a user, I want to see train delays', () {
      test('should show only delayed trains when filtering', () {
        // Given: I have trains with different statuses
        final trains = [
          Train.fromTimes(
            id: '1',
            direction: 'Paris',
            departureTime: DateTime(2025, 1, 1, 10, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 10, 0),
            station: testStation,
            additionalInfo: [],
          ),
          Train.fromTimes(
            id: '2',
            direction: 'Nantes',
            departureTime: DateTime(2025, 1, 1, 11, 10),
            baseDepartureTime: DateTime(2025, 1, 1, 11, 0),
            station: testStation,
            additionalInfo: [],
          ),
        ];

        // When: I filter for delayed trains only
        final result = trainService.filterByStatus(trains, TrainStatus.delayed);

        // Then: I should only see delayed trains
        expect(result.length, 1);
        expect(result.first.status, TrainStatus.delayed);
      });
    });
  });
}
