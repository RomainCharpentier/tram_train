import 'dart:convert';
import 'package:http/http.dart' as http;
import '../mappers/sncf_mapper.dart';
import '../../domain/models/train.dart';
import '../../domain/models/station.dart';
import '../../domain/services/train_service.dart';
import '../../env_config.dart';

/// Gateway pour l'API SNCF
/// Documentation: https://www.sncf.com/fr/partenaires/partenaires-technologiques
class SncfGateway implements TrainGateway {
  final http.Client _httpClient;
  final String _apiKey;
  final SncfMapper _mapper;

  const SncfGateway({
    required http.Client httpClient,
    required String apiKey,
    required SncfMapper mapper,
  }) : _httpClient = httpClient, _apiKey = apiKey, _mapper = mapper;

  /// Récupère les départs depuis l'API SNCF
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/departures
  Future<List<Train>> getDepartures(Station station) async {
    final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:${station.id}/departures';
    
    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDeparturesToTrains(response, station);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la récupération des départs: $e');
    }
  }

  /// Récupère les départs à une date/heure spécifique
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/departures?datetime={datetime}
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime) async {
    final formattedDateTime = dateTime.toIso8601String();
    final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:${station.id}/departures?datetime=$formattedDateTime';
    
    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDeparturesToTrains(response, station);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la récupération des départs: $e');
    }
  }

  /// Effectue un appel API avec authentification
  Future<Map<String, dynamic>> _makeApiCall(String url) async {
    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}'
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw SncfGatewayException('Erreur API: ${response.statusCode}');
    }
  }
}

class SncfGatewayException implements Exception {
  final String message;
  const SncfGatewayException(this.message);
  
  @override
  String toString() => 'SncfGatewayException: $message';
}
