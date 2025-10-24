import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/train.dart';
import '../../domain/models/station.dart';
import '../../domain/providers/train_repository.dart';
import 'sncf_departure_model.dart';

class SncfTrainRepository implements TrainRepository {
  final http.Client _httpClient;
  final String _apiKey;

  const SncfTrainRepository({
    required http.Client httpClient,
    required String apiKey,
  }) : _httpClient = httpClient, _apiKey = apiKey;

  @override
  Future<List<Train>> getDepartures(Station station) async {
    final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:${station.id}/departures';
    
    try {
      final response = await _httpClient.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final departures = (data['departures'] as List<dynamic>?)
            ?.map((departure) => SncfDepartureModel.fromJson(departure))
            .toList() ?? [];
        
        return departures.map((departure) => _mapToTrain(departure, station)).toList();
      } else {
        throw TrainRepositoryException('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      throw TrainRepositoryException('Erreur lors de l\'appel API: $e');
    }
  }

  @override
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime) async {
    final formattedDateTime = dateTime.toIso8601String();
    final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:${station.id}/departures?datetime=$formattedDateTime';
    
    try {
      final response = await _httpClient.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final departures = (data['departures'] as List<dynamic>?)
            ?.map((departure) => SncfDepartureModel.fromJson(departure))
            .toList() ?? [];
        
        return departures.map((departure) => _mapToTrain(departure, station)).toList();
      } else {
        throw TrainRepositoryException('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      throw TrainRepositoryException('Erreur lors de l\'appel API: $e');
    }
  }

  Train _mapToTrain(SncfDepartureModel departure, Station station) {
    final departureTime = DateTime.parse(departure.departureDateTime);
    final baseDepartureTime = DateTime.parse(departure.baseDepartureDateTime);
    
    return Train.fromTimes(
      id: departure.id,
      direction: departure.direction,
      departureTime: departureTime,
      baseDepartureTime: baseDepartureTime,
      station: station,
      additionalInfo: departure.additionalInformations,
    );
  }
}

class TrainRepositoryException implements Exception {
  final String message;
  const TrainRepositoryException(this.message);
  
  @override
  String toString() => 'TrainRepositoryException: $message';
}
