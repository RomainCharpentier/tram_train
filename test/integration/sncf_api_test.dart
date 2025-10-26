import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/env_config.dart';

/// Tests d'intégration avec l'API SNCF réelle
/// Ces tests nécessitent une clé API valide dans .env.local
void main() {
  group('SNCF API Integration Tests', () {
    late SncfGateway sncfGateway;
    late Station testStation;

    setUpAll(() async {
      // Vérifier que la clé API est configurée
      if (EnvConfig.apiKey == null || EnvConfig.apiKey!.isEmpty) {
        fail('API_KEY manquante dans .env.local. Ces tests nécessitent une clé API SNCF valide.');
      }

      sncfGateway = SncfGateway(
        httpClient: http.Client(),
        apiKey: EnvConfig.apiKey!,
        mapper: SncfMapper(),
      );

      // Station de test : Nantes
      testStation = const Station(
        id: 'SNCF:87590349',
        name: 'Nantes',
        description: 'Gare de Nantes',
      );
    });

    group('Station Search API', () {
      test('should find stations by name', () async {
        // Test curl équivalent: 
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)" 
        //      "https://api.sncf.com/v1/coverage/sncf/places?q=Nantes&type[]=stop_area"
        
        final stations = await sncfGateway.searchStations('Nantes');
        
        expect(stations, isNotEmpty);
        expect(stations.any((station) => station.name.toLowerCase().contains('nantes')), isTrue);
        
        print('Found ${stations.length} stations for "Nantes":');
        for (final station in stations.take(3)) {
          print('  - ${station.name} (${station.id})');
        }
      });

      test('should find stations by partial name', () async {
        final stations = await sncfGateway.searchStations('Paris');
        
        expect(stations, isNotEmpty);
        expect(stations.any((station) => station.name.toLowerCase().contains('paris')), isTrue);
        
        print('Found ${stations.length} stations for "Paris":');
        for (final station in stations.take(3)) {
          print('  - ${station.name} (${station.id})');
        }
      });
    });

    group('Departures API', () {
      test('should get current departures from Nantes', () async {
        // Test curl équivalent:
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)"
        //      "https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/departures"
        
        final trains = await sncfGateway.getDepartures(testStation);
        
        expect(trains, isNotEmpty);
        print('Found ${trains.length} departures from ${testStation.name}:');
        for (final train in trains.take(5)) {
          print('  - ${train.direction} at ${train.departureTime} (${train.status})');
        }
      });

      test('should get departures at specific time', () async {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final specificTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
        
        final trains = await sncfGateway.getDeparturesAt(testStation, specificTime);
        
        print('Found ${trains.length} departures at ${specificTime}:');
        for (final train in trains.take(3)) {
          print('  - ${train.direction} at ${train.departureTime}');
        }
      });
    });

    group('Route Schedules API', () {
      test('should get all trains passing through Nantes', () async {
        // Test curl équivalent:
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)"
        //      "https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/route_schedules"
        
        final trains = await sncfGateway.getTrainsPassingThrough(testStation);
        
        expect(trains, isNotEmpty);
        print('Found ${trains.length} trains passing through ${testStation.name}:');
        for (final train in trains.take(5)) {
          print('  - ${train.direction} at ${train.departureTime}');
        }
      });
    });

    group('Journeys API', () {
      test('should find journeys between Nantes and Paris', () async {
        // Test curl équivalent:
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)"
        //      "https://api.sncf.com/v1/coverage/sncf/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008"
        
        final parisStation = const Station(
          id: 'SNCF:87384008',
          name: 'Paris',
          description: 'Gare de Paris',
        );
        
        final trains = await sncfGateway.findJourneysBetween(testStation, parisStation);
        
        expect(trains, isNotEmpty);
        print('Found ${trains.length} journeys from ${testStation.name} to ${parisStation.name}:');
        for (final train in trains.take(3)) {
          print('  - Departure: ${train.departureTime}');
          if (train.additionalInfo.isNotEmpty) {
            print('    ${train.additionalInfo.join(', ')}');
          }
        }
      });

      test('should find journeys with departure time', () async {
        final parisStation = const Station(
          id: 'SNCF:87384008',
          name: 'Paris',
          description: 'Gare de Paris',
        );
        
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final departureTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
        
        final trains = await sncfGateway.findJourneysWithDepartureTime(
          testStation, 
          parisStation, 
          departureTime
        );
        
        print('Found ${trains.length} journeys departing at ${departureTime}:');
        for (final train in trains.take(3)) {
          print('  - ${train.direction} at ${train.departureTime}');
        }
      });
    });

    group('Station Info API', () {
      test('should get station information', () async {
        // Test curl équivalent:
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)"
        //      "https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/stop_schedules"
        
        final stationInfo = await sncfGateway.getStationInfo(testStation);
        
        expect(stationInfo, isNotEmpty);
        print('Station info for ${testStation.name}:');
        stationInfo.forEach((key, value) {
          print('  $key: $value');
        });
      });
    });

    group('Disruptions API', () {
      test('should get current disruptions', () async {
        // Test curl équivalent:
        // curl -H "Authorization: Basic $(echo -n 'API_KEY:' | base64)"
        //      "https://api.sncf.com/v1/coverage/sncf/disruptions"
        
        final disruptions = await sncfGateway.getDisruptions();
        
        print('Found ${disruptions.length} current disruptions:');
        for (final disruption in disruptions.take(3)) {
          print('  - ${disruption['severity']}: ${disruption['messages']?.join(', ')}');
        }
      });
    });

    group('API Error Handling', () {
      test('should handle invalid station ID gracefully', () async {
        final invalidStation = const Station(
          id: 'INVALID:123456',
          name: 'Invalid Station',
          description: 'This station does not exist',
        );
        
        expect(
          () => sncfGateway.getDepartures(invalidStation),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle API rate limiting', () async {
        // Test de limitation de débit en faisant plusieurs appels rapides
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(sncfGateway.searchStations('Test'));
        }
        
        // Au moins un appel devrait réussir
        final results = await Future.wait(futures, eagerError: false);
        final successfulResults = results.where((result) => result is List).length;
        
        expect(successfulResults, greaterThan(0));
        print('Rate limiting test: $successfulResults/5 calls succeeded');
      });
    });
  });
}
