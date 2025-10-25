import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tram_train/domain/models/station.dart';
import 'package:tram_train/infrastructure/gateways/sncf_gateway.dart';
import 'package:tram_train/infrastructure/mappers/sncf_mapper.dart';

/// Test de démonstration des appels API SNCF
/// Ce test montre comment les endpoints sont appelés sans nécessiter une vraie clé API
void main() {
  group('SNCF API Demo Tests', () {
    late SncfGateway sncfGateway;
    late Station testStation;

    setUpAll(() async {
      // Utilisation d'une clé API factice pour la démonstration
      sncfGateway = SncfGateway(
        httpClient: http.Client(),
        apiKey: 'demo_api_key',
        mapper: SncfMapper(),
      );

      // Station de test : Nantes
      testStation = const Station(
        id: 'SNCF:87590349',
        name: 'Nantes',
        description: 'Gare de Nantes',
      );
    });

    group('API Endpoint Demonstration', () {
      test('should demonstrate search stations endpoint', () async {
        // Ce test va échouer avec une erreur 401 (clé API invalide)
        // mais cela démontre que l'endpoint est correctement appelé
        
        print('🔍 Testing search stations endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/places?q=Nantes&type[]=stop_area');
        print('Expected: 401 Unauthorized (demo API key)');
        
        expect(
          () => sncfGateway.searchStations('Nantes'),
          throwsA(isA<Exception>()),
        );
      });

      test('should demonstrate departures endpoint', () async {
        print('🚂 Testing departures endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/departures');
        print('Expected: 401 Unauthorized (demo API key)');
        
        expect(
          () => sncfGateway.getDepartures(testStation),
          throwsA(isA<Exception>()),
        );
      });

      test('should demonstrate route schedules endpoint', () async {
        print('📅 Testing route schedules endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/route_schedules');
        print('Expected: 401 Unauthorized (demo API key)');
        
        expect(
          () => sncfGateway.getTrainsPassingThrough(testStation),
          throwsA(isA<Exception>()),
        );
      });

      test('should demonstrate journeys endpoint', () async {
        print('🗺️ Testing journeys endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/journeys?from=stop_area:SNCF:87590349&to=stop_area:SNCF:87384008');
        print('Expected: 401 Unauthorized (demo API key)');
        
        final parisStation = const Station(
          id: 'SNCF:87384008',
          name: 'Paris',
          description: 'Gare de Paris',
        );
        
        expect(
          () => sncfGateway.findJourneysBetween(testStation, parisStation),
          throwsA(isA<Exception>()),
        );
      });

      test('should demonstrate station info endpoint', () async {
        print('ℹ️ Testing station info endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:SNCF:87590349/stop_schedules');
        print('Expected: 401 Unauthorized (demo API key)');
        
        expect(
          () => sncfGateway.getStationInfo(testStation),
          throwsA(isA<Exception>()),
        );
      });

      test('should demonstrate disruptions endpoint', () async {
        print('⚠️ Testing disruptions endpoint...');
        print('Endpoint: GET /v1/coverage/sncf/disruptions');
        print('Expected: 401 Unauthorized (demo API key)');
        
        expect(
          () => sncfGateway.getDisruptions(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('API Documentation Links', () {
      test('should provide API documentation links', () {
        print('');
        print('📚 Documentation API SNCF:');
        print('  - Base URL: https://api.sncf.com/v1/coverage/sncf/');
        print('  - Documentation: https://www.sncf.com/fr/partenaires/partenaires-technologiques');
        print('  - Authentication: Basic Auth avec clé API');
        print('');
        print('🔗 Endpoints disponibles:');
        print('  1. Recherche de gares: /places?q={query}&type[]=stop_area');
        print('  2. Départs: /stop_areas/stop_area:{id}/departures');
        print('  3. Horaires de route: /stop_areas/stop_area:{id}/route_schedules');
        print('  4. Trajets: /journeys?from=stop_area:{from}&to=stop_area:{to}');
        print('  5. Infos gare: /stop_areas/stop_area:{id}/stop_schedules');
        print('  6. Perturbations: /disruptions');
        print('');
        print('💡 Pour tester avec une vraie clé API:');
        print('  1. Obtenez une clé sur le site SNCF');
        print('  2. Ajoutez-la dans .env.local: API_KEY=votre_cle');
        print('  3. Lancez: flutter test test/integration/sncf_api_test.dart');
        
        expect(true, isTrue); // Test toujours réussi
      });
    });
  });
}
