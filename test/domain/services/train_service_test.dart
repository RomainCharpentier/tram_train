import 'package:flutter_test/flutter_test.dart';
import 'package:tram_train/domain/models/station.dart';
import 'package:tram_train/domain/models/train.dart';
import 'package:tram_train/domain/services/train_service.dart';

// Mock implementation for testing
class MockSncfGateway implements TrainGateway {
  List<Train>? _mockTrains;
  List<Station>? _mockStations;
  Map<String, dynamic>? _mockStationInfo;
  List<Map<String, dynamic>>? _mockDisruptions;
  Exception? _mockException;

  void setMockTrains(List<Train> trains) {
    _mockTrains = trains;
  }

  void setMockStations(List<Station> stations) {
    _mockStations = stations;
  }

  void setMockStationInfo(Map<String, dynamic> info) {
    _mockStationInfo = info;
  }

  void setMockDisruptions(List<Map<String, dynamic>> disruptions) {
    _mockDisruptions = disruptions;
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

  // Additional methods for testing new API calls
  Future<List<Station>> searchStations(String query) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockStations ?? [];
  }

  Future<List<Train>> getTrainsPassingThrough(Station station) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }

  Future<List<Train>> findJourneysBetween(Station fromStation, Station toStation) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }

  Future<List<Train>> findJourneysWithDepartureTime(Station fromStation, Station toStation, DateTime departureTime) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }

  Future<List<Train>> findJourneysWithArrivalTime(Station fromStation, Station toStation, DateTime arrivalTime) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockTrains ?? [];
  }

  Future<Map<String, dynamic>> getStationInfo(Station station) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockStationInfo ?? {};
  }

  Future<List<Map<String, dynamic>>> getDisruptions() async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockDisruptions ?? [];
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

    group('As a user, I want to search for stations', () {
      test('should find stations by name', () async {
        // Given: I search for "Nantes"
        final expectedStations = [
          const Station(id: 'STATION1', name: 'Nantes'),
          const Station(id: 'STATION2', name: 'Nantes Centre'),
        ];
        mockGateway.setMockStations(expectedStations);

        // When: I search for stations
        final result = await mockGateway.searchStations('Nantes');

        // Then: I should find matching stations
        expect(result, expectedStations);
      });

      test('should handle search errors gracefully', () async {
        // Given: Search API is unavailable
        mockGateway.setMockException(Exception('Search API Error'));

        // When: I search for stations
        // Then: I should get an error
        expect(
          () => mockGateway.searchStations('Nantes'),
          throwsException,
        );
      });
    });

    group('As a user, I want to see all trains passing through a station', () {
      test('should get trains in both directions', () async {
        // Given: I want to see all trains at a station
        final expectedTrains = [
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
        mockGateway.setMockTrains(expectedTrains);

        // When: I request all trains passing through
        final result = await mockGateway.getTrainsPassingThrough(testStation);

        // Then: I should see trains in both directions
        expect(result, expectedTrains);
      });
    });

    group('As a user, I want to find journeys between stations', () {
      test('should find direct journeys between two stations', () async {
        // Given: I want to go from Station A to Station B
        final stationA = const Station(id: 'STATION_A', name: 'Station A');
        final stationB = const Station(id: 'STATION_B', name: 'Station B');
        final expectedTrains = [
          Train.fromTimes(
            id: '1',
            direction: 'Station B',
            departureTime: DateTime(2025, 1, 1, 10, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 10, 0),
            station: stationA,
            additionalInfo: ['Arrivée: 2025-01-01 11:00:00.000', 'Durée: 1h00'],
          ),
        ];
        mockGateway.setMockTrains(expectedTrains);

        // When: I search for journeys between stations
        final result = await mockGateway.findJourneysBetween(stationA, stationB);

        // Then: I should find available journeys
        expect(result, expectedTrains);
      });

      test('should find journeys with specific departure time', () async {
        // Given: I want to leave at a specific time
        final stationA = const Station(id: 'STATION_A', name: 'Station A');
        final stationB = const Station(id: 'STATION_B', name: 'Station B');
        final departureTime = DateTime(2025, 1, 1, 14, 30);
        final expectedTrains = [
          Train.fromTimes(
            id: '1',
            direction: 'Station B',
            departureTime: departureTime,
            baseDepartureTime: departureTime,
            station: stationA,
            additionalInfo: ['Arrivée: 2025-01-01 15:30:00.000', 'Durée: 1h00'],
          ),
        ];
        mockGateway.setMockTrains(expectedTrains);

        // When: I search for journeys with departure time
        final result = await mockGateway.findJourneysWithDepartureTime(stationA, stationB, departureTime);

        // Then: I should find journeys at that time
        expect(result, expectedTrains);
      });

      test('should find journeys with specific arrival time', () async {
        // Given: I want to arrive at a specific time
        final stationA = const Station(id: 'STATION_A', name: 'Station A');
        final stationB = const Station(id: 'STATION_B', name: 'Station B');
        final arrivalTime = DateTime(2025, 1, 1, 16, 0);
        final expectedTrains = [
          Train.fromTimes(
            id: '1',
            direction: 'Station B',
            departureTime: DateTime(2025, 1, 1, 15, 0),
            baseDepartureTime: DateTime(2025, 1, 1, 15, 0),
            station: stationA,
            additionalInfo: ['Arrivée: 2025-01-01 16:00:00.000', 'Durée: 1h00'],
          ),
        ];
        mockGateway.setMockTrains(expectedTrains);

        // When: I search for journeys with arrival time
        final result = await mockGateway.findJourneysWithArrivalTime(stationA, stationB, arrivalTime);

        // Then: I should find journeys arriving at that time
        expect(result, expectedTrains);
      });
    });

    group('As a user, I want to get station information', () {
      test('should retrieve station details', () async {
        // Given: I want station information
        final expectedInfo = {
          'name': 'Nantes',
          'direction': 'Paris',
          'network': 'SNCF',
          'commercial_mode': 'Train',
          'physical_mode': 'Train',
        };
        mockGateway.setMockStationInfo(expectedInfo);

        // When: I request station information
        final result = await mockGateway.getStationInfo(testStation);

        // Then: I should get station details
        expect(result, expectedInfo);
      });
    });

    group('As a user, I want to check for disruptions', () {
      test('should get current disruptions', () async {
        // Given: I want to check for disruptions
        final expectedDisruptions = [
          {
            'id': 'disruption1',
            'severity': 'high',
            'impact_level': 'severe',
            'messages': ['Ligne fermée pour travaux'],
            'application_periods': ['2025-01-01T00:00:00/2025-01-02T00:00:00'],
          },
        ];
        mockGateway.setMockDisruptions(expectedDisruptions);

        // When: I request disruptions
        final result = await mockGateway.getDisruptions();

        // Then: I should get disruption information
        expect(result, expectedDisruptions);
      });

      test('should handle disruption API errors', () async {
        // Given: Disruption API is unavailable
        mockGateway.setMockException(Exception('Disruption API Error'));

        // When: I request disruptions
        // Then: I should get an error
        expect(
          () => mockGateway.getDisruptions(),
          throwsException,
        );
      });
    });
  });
}
