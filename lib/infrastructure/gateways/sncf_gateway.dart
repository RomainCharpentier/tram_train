import 'dart:convert';
import 'package:http/http.dart' as http;
import '../mappers/sncf_mapper.dart';
import '../../domain/models/train.dart';
import '../../domain/models/station.dart';
import '../../domain/services/train_service.dart';

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
  })  : _httpClient = httpClient,
        _apiKey = apiKey,
        _mapper = mapper;

  /// Récupère les départs depuis l'API SNCF
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/departures
  @override
  Future<List<Train>> getDepartures(Station station) async {
    final stationId = _normalizeStationId(station.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stationId/departures';

    try {
      final response = await _makeApiCall(apiUrl);
      final trains = _mapper.mapDeparturesToTrains(response, station);
      return trains;
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des départs: $e');
    }
  }

  /// Récupère les départs à une date/heure spécifique
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/departures?datetime={datetime}
  @override
  Future<List<Train>> getDeparturesAt(
      Station station, DateTime dateTime) async {
    final formattedDateTime = _formatDateTimeForApi(dateTime);
    final stationId = _normalizeStationId(station.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stationId/departures?datetime=$formattedDateTime&count=100';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDeparturesToTrains(response, station);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des départs: $e');
    }
  }

  /// Recherche des gares par nom
  /// Endpoint: GET /v1/coverage/sncf/places?q={query}&type[]=stop_area
  Future<List<Station>> searchStations(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/places?q=$encodedQuery&type[]=stop_area';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapPlacesToStations(response);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la recherche de gares: $e');
    }
  }

  /// Récupère tous les trajets passant par une gare (dans les 2 sens)
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/route_schedules
  Future<List<Train>> getTrainsPassingThrough(Station station) async {
    final stationId = _normalizeStationId(station.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stationId/route_schedules';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapRouteSchedulesToTrains(response, station);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des trajets: $e');
    }
  }

  /// Recherche de trajets entre deux gares
  /// Endpoint: GET /v1/coverage/sncf/journeys?from=stop_area:{fromId}&to=stop_area:{toId}
  Future<List<Train>> findJourneysBetween(
      Station fromStation, Station toStation) async {
    final fromId = _normalizeStationId(fromStation.id);
    final toId = _normalizeStationId(toStation.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/journeys?from=stop_area:$fromId&to=stop_area:$toId&count=20';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapJourneysToTrains(response, fromStation, toStation);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la recherche de trajets: $e');
    }
  }

  /// Normalise un ID de station pour l'API SNCF
  /// Enlève le préfixe 'stop_area:' s'il existe
  /// Rejette les IDs temporaires (TEMP_)
  String _normalizeStationId(String stationId) {
    // Rejeter les IDs temporaires
    if (stationId.startsWith('TEMP_')) {
      throw SncfGatewayException(
        'Station temporaire invalide: $stationId. Veuillez rechercher la station à nouveau.',
      );
    }
    return stationId.replaceFirst(RegExp(r'^stop_area:'), '');
  }

  /// Recherche de trajets avec horaire de départ
  /// Endpoint: GET /v1/coverage/sncf/journeys?from=stop_area:{fromId}&to=stop_area:{toId}&datetime={datetime}
  Future<List<Train>> findJourneysWithDepartureTime(
      Station fromStation, Station toStation, DateTime departureTime) async {
    final formattedDateTime = _formatDateTimeForApi(departureTime);
    final fromId = _normalizeStationId(fromStation.id);
    final toId = _normalizeStationId(toStation.id);
    final uri = Uri.https(
      'api.sncf.com',
      '/v1/coverage/sncf/journeys',
      {
        'from': 'stop_area:$fromId',
        'to': 'stop_area:$toId',
        'datetime_represents': 'departure',
        'datetime': formattedDateTime,
        'count': '50',
      },
    );

    try {
      // ignore: avoid_print
      print('🔗 Journeys(departure) URL: $uri');
      final response = await _makeApiCallUri(uri);
      return _mapper.mapJourneysToTrains(response, fromStation, toStation);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la recherche de trajets: $e');
    }
  }

  /// Récupère la réponse brute de journeys (pour pagination via links prev/next)
  Future<Map<String, dynamic>> getJourneysRaw(
    Station fromStation,
    Station toStation,
    DateTime time, {
    required String represents, // 'departure' ou 'arrival'
  }) async {
    final formattedDateTime = _formatDateTimeForApi(time);
    final fromId = _normalizeStationId(fromStation.id);
    final toId = _normalizeStationId(toStation.id);
    final uri = Uri.https(
      'api.sncf.com',
      '/v1/coverage/sncf/journeys',
      {
        'from': 'stop_area:$fromId',
        'to': 'stop_area:$toId',
        'datetime_represents': represents,
        'datetime': formattedDateTime,
        'count': '50',
      },
    );

    // ignore: avoid_print
    print('🔗 Journeys($represents) URL: $uri');
    return await _makeApiCallUri(uri);
  }

  /// Suivre un lien de pagination (prev/next) et mapper en trains
  Future<List<Train>> getJourneysByHref(
    String href,
    Station fromStation,
    Station toStation,
  ) async {
    // ignore: avoid_print
    print('🔗 Journeys(page) HREF: $href');
    final response = await _makeApiCall(href);
    return _mapper.mapJourneysToTrains(response, fromStation, toStation);
  }

  /// Recherche de trajets avec horaire d'arrivée
  /// Endpoint: GET /v1/coverage/sncf/journeys?from=stop_area:{fromId}&to=stop_area:{toId}&datetime_represents=arrival&datetime={datetime}
  Future<List<Train>> findJourneysWithArrivalTime(
      Station fromStation, Station toStation, DateTime arrivalTime) async {
    final formattedDateTime = _formatDateTimeForApi(arrivalTime);
    final fromId = _normalizeStationId(fromStation.id);
    final toId = _normalizeStationId(toStation.id);
    final uri = Uri.https(
      'api.sncf.com',
      '/v1/coverage/sncf/journeys',
      {
        'from': 'stop_area:$fromId',
        'to': 'stop_area:$toId',
        'datetime_represents': 'arrival',
        'datetime': formattedDateTime,
        'count': '50',
      },
    );

    try {
      // ignore: avoid_print
      print('🔗 Journeys(arrival) URL: $uri');
      final response = await _makeApiCallUri(uri);
      return _mapper.mapJourneysToTrains(response, fromStation, toStation);
    } catch (e) {
      throw SncfGatewayException('Erreur lors de la recherche de trajets: $e');
    }
  }

  /// Récupère les informations générales sur les trajets
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/stop_area:{id}/stop_schedules
  Future<Map<String, dynamic>> getStationInfo(Station station) async {
    final stationId = _normalizeStationId(station.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stationId/stop_schedules';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapStationInfo(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des informations: $e');
    }
  }

  /// Récupère les perturbations sur une ligne
  /// Endpoint: GET /v1/coverage/sncf/disruptions
  Future<List<Map<String, dynamic>>> getDisruptions() async {
    const apiUrl = 'https://api.sncf.com/v1/coverage/sncf/disruptions';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDisruptions(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des perturbations: $e');
    }
  }

  /// Récupère les perturbations pour une ligne spécifique
  /// Endpoint: GET /v1/coverage/sncf/disruptions?filter=line.id:{lineId}
  Future<List<Map<String, dynamic>>> getDisruptionsForLine(
      String lineId) async {
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/disruptions?filter=line.id:$lineId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDisruptions(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des perturbations de ligne: $e');
    }
  }

  /// Récupère les perturbations pour une gare spécifique
  /// Endpoint: GET /v1/coverage/sncf/disruptions?filter=stop_area.id:{stationId}
  Future<List<Map<String, dynamic>>> getDisruptionsForStation(
      String stationId) async {
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/disruptions?filter=stop_area.id:$stationId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapDisruptions(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des perturbations de gare: $e');
    }
  }

  /// Récupère les informations détaillées d'une ligne
  /// Endpoint: GET /v1/coverage/sncf/lines/{lineId}
  Future<Map<String, dynamic>> getLineInfo(String lineId) async {
    final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/lines/$lineId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapLineInfo(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des informations de ligne: $e');
    }
  }

  /// Récupère les arrêts d'une ligne
  /// Endpoint: GET /v1/coverage/sncf/lines/{lineId}/stop_areas
  Future<List<Station>> getLineStations(String lineId) async {
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/lines/$lineId/stop_areas';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapLineStations(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des arrêts de ligne: $e');
    }
  }

  /// Récupère les horaires d'une ligne pour une date donnée
  /// Endpoint: GET /v1/coverage/sncf/lines/{lineId}/schedules?datetime={datetime}
  Future<List<Map<String, dynamic>>> getLineSchedules(
      String lineId, DateTime dateTime) async {
    final formattedDateTime = dateTime.toIso8601String();
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/lines/$lineId/schedules?datetime=$formattedDateTime';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapLineSchedules(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des horaires de ligne: $e');
    }
  }

  /// Récupère les prochains passages d'une ligne à une gare
  /// Endpoint: GET /v1/coverage/sncf/stop_areas/{stationId}/arrivals?filter=line.id:{lineId}
  Future<List<Train>> getNextArrivalsForLine(
      Station station, String lineId) async {
    final stationId = _normalizeStationId(station.id);
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/$stationId/arrivals?filter=line.id:$lineId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapArrivalsToTrains(response, station);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des prochains passages: $e');
    }
  }

  /// Récupère les informations de trafic en temps réel
  /// Endpoint: GET /v1/coverage/sncf/traffic_reports
  Future<List<Map<String, dynamic>>> getTrafficReports() async {
    const apiUrl = 'https://api.sncf.com/v1/coverage/sncf/traffic_reports';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapTrafficReports(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des rapports de trafic: $e');
    }
  }

  /// Récupère les informations de trafic pour une ligne spécifique
  /// Endpoint: GET /v1/coverage/sncf/traffic_reports?filter=line.id:{lineId}
  Future<List<Map<String, dynamic>>> getTrafficReportsForLine(
      String lineId) async {
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/traffic_reports?filter=line.id:$lineId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapTrafficReports(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des rapports de trafic de ligne: $e');
    }
  }

  /// Récupère les informations de trafic pour une gare spécifique
  /// Endpoint: GET /v1/coverage/sncf/traffic_reports?filter=stop_area.id:{stationId}
  Future<List<Map<String, dynamic>>> getTrafficReportsForStation(
      String stationId) async {
    final apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/traffic_reports?filter=stop_area.id:$stationId';

    try {
      final response = await _makeApiCall(apiUrl);
      return _mapper.mapTrafficReports(response);
    } catch (e) {
      throw SncfGatewayException(
          'Erreur lors de la récupération des rapports de trafic de gare: $e');
    }
  }

  /// Effectue un appel API avec authentification
  Future<Map<String, dynamic>> _makeApiCall(String url) async {
    // ignore: avoid_print
    print('➡️ GET $url');
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

  /// Effectue un appel API (URI déjà encodée)
  Future<Map<String, dynamic>> _makeApiCallUri(Uri uri) async {
    // ignore: avoid_print
    print('➡️ GET $uri');
    final response = await _httpClient.get(
      uri,
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

  /// Formatte une DateTime au format attendu par l'API SNCF: YYYYMMDDTHHMMSS
  String _formatDateTimeForApi(DateTime dt) {
    // L'API attend une date locale au format compact, sans timezone
    String two(int n) => n.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final m = two(dt.month);
    final d = two(dt.day);
    final h = two(dt.hour);
    final min = two(dt.minute);
    final s = two(dt.second);
    return '$y$m${d}T$h$min$s';
  }
}

class SncfGatewayException implements Exception {
  final String message;
  const SncfGatewayException(this.message);

  @override
  String toString() => 'SncfGatewayException: $message';
}
