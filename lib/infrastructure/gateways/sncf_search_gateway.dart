import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/station.dart';
import '../../domain/models/search_result.dart';
import '../../domain/services/station_search_service.dart';
import '../mappers/sncf_mapper.dart';
import '../services/api_cache_service.dart';
import '../services/retry_service.dart';

/// Gateway pour la recherche de gares via l'API SNCF
class SncfSearchGateway implements StationSearchGateway {
  final http.Client _httpClient;
  final String _apiKey;
  final SncfMapper _mapper;
  final ApiCacheService _cacheService;

  SncfSearchGateway({
    required http.Client httpClient,
    required String apiKey,
    required SncfMapper mapper,
    ApiCacheService? cacheService,
  })  : _httpClient = httpClient,
        _apiKey = apiKey,
        _mapper = mapper,
        _cacheService = cacheService ?? ApiCacheService();

  @override
  Future<List<SearchResult<Station>>> searchStations(String query) async {
    if (query.trim().isEmpty) return [];

    // Vérifier le cache (TTL: 1 heure pour les recherches de gares)
    final cacheKey = ApiCacheService.generateKey('search_stations', {'query': query});
    final cachedResponse = await _cacheService.get<Map<String, dynamic>>(
      cacheKey,
      const Duration(hours: 1),
    );

    Map<String, dynamic> response;
    if (cachedResponse != null) {
      response = cachedResponse;
    } else {
      try {
        // Recherche via l'API SNCF places
        final encodedQuery = Uri.encodeComponent(query);
        final apiUrl =
            'https://api.sncf.com/v1/coverage/sncf/places?q=$encodedQuery&type[]=stop_area';

        response = await RetryService.retry(
          operation: () => _makeApiCall(apiUrl),
          maxAttempts: 3,
          delay: const Duration(seconds: 2),
        );
        // Mettre en cache la réponse brute
        await _cacheService.set(cacheKey, response, const Duration(hours: 1));
      } catch (e) {
        throw SncfSearchException('Erreur lors de la recherche: $e');
      }
    }

    final places = response['places'] as List<dynamic>? ?? [];
    final results = <SearchResult<Station>>[];

    for (final place in places) {
      final station = _mapper.mapPlaceToStation(place);
      final score = _calculateSearchScore(query, station.name);
      final highlight = _highlightMatch(query, station.name);

      results.add(SearchResult.partial(
        station,
        score,
        highlight: highlight,
        metadata: {
          'place_id': place['id'],
          'distance': place['distance'],
          'administrative_regions': place['administrative_regions'],
        },
      ));
    }

    // Trier par score décroissant
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  @override
  Future<List<SearchResult<Station>>> searchNearbyStations({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async {
    try {
      final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/places?'
          'type[]=stop_area&'
          'count=20&'
          'distance=$radiusKm&'
          'coord=${longitude.toStringAsFixed(6)},${latitude.toStringAsFixed(6)}';

      final response = await _makeApiCall(apiUrl);
      final places = response['places'] as List<dynamic>? ?? [];

      final results = <SearchResult<Station>>[];

      for (final place in places) {
        final station = _mapper.mapPlaceToStation(place);
        final distance = place['distance'] as double? ?? 0.0;
        final score = _calculateDistanceScore(distance, radiusKm);

        results.add(SearchResult.partial(
          station,
          score,
          metadata: {
            'distance': distance,
            'place_id': place['id'],
            'administrative_regions': place['administrative_regions'],
          },
        ));
      }

      // Trier par distance
      results.sort((a, b) {
        final distanceA = a.metadata?['distance'] as double? ?? double.infinity;
        final distanceB = b.metadata?['distance'] as double? ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });

      return results;
    } catch (e) {
      throw SncfSearchException('Erreur lors de la recherche de proximité: $e');
    }
  }

  @override
  Future<List<SearchResult<Station>>> searchStationsByLine(String lineId) async {
    try {
      final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/lines/$lineId/stop_areas';

      final response = await _makeApiCall(apiUrl);
      final stopAreas = response['stop_areas'] as List<dynamic>? ?? [];

      final results = <SearchResult<Station>>[];

      for (final stopArea in stopAreas) {
        final station = _mapper.mapStopAreaToStation(stopArea);
        results.add(SearchResult.exact(
          station,
          metadata: {
            'line_id': lineId,
            'stop_area_id': stopArea['id'],
          },
        ));
      }

      return results;
    } catch (e) {
      throw SncfSearchException('Erreur lors de la recherche par ligne: $e');
    }
  }

  @override
  Future<List<SearchResult<Station>>> searchStationsByType(TransportType type) async {
    try {
      String physicalMode = '';
      switch (type) {
        case TransportType.train:
          physicalMode = 'physical_mode:Train';
          break;
        case TransportType.tram:
          physicalMode = 'physical_mode:Tramway';
          break;
        case TransportType.bus:
          physicalMode = 'physical_mode:Bus';
          break;
        case TransportType.metro:
          physicalMode = 'physical_mode:Metro';
          break;
        case TransportType.all:
          return await searchStations(''); // Recherche générale
      }

      final apiUrl = 'https://api.sncf.com/v1/coverage/sncf/places?'
          'type[]=stop_area&'
          'filter=$physicalMode&'
          'count=50';

      final response = await _makeApiCall(apiUrl);
      final places = response['places'] as List<dynamic>? ?? [];

      final results = <SearchResult<Station>>[];

      for (final place in places) {
        final station = _mapper.mapPlaceToStation(place);
        results.add(SearchResult.exact(
          station,
          metadata: {
            'transport_type': type.displayName,
            'place_id': place['id'],
          },
        ));
      }

      return results;
    } catch (e) {
      throw SncfSearchException('Erreur lors de la recherche par type: $e');
    }
  }

  @override
  Future<List<SearchResult<Station>>> getFavoriteStations() async {
    // Cette méthode sera implémentée avec le service des favorites
    return [];
  }

  @override
  Future<List<SearchResult<Station>>> advancedSearch({
    String? query,
    String? lineId,
    TransportType? transportType,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    // Recherche avancée combinant plusieurs critères
    if (query != null && query.isNotEmpty) {
      return await searchStations(query);
    }

    if (lineId != null) {
      return await searchStationsByLine(lineId);
    }

    if (transportType != null) {
      return await searchStationsByType(transportType);
    }

    if (latitude != null && longitude != null) {
      return await searchNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm ?? 5,
      );
    }

    return [];
  }

  /// Calcule le score de correspondance pour une recherche
  double _calculateSearchScore(String query, String stationName) {
    final queryLower = query.toLowerCase();
    final nameLower = stationName.toLowerCase();

    if (nameLower == queryLower) return 1.0;
    if (nameLower.startsWith(queryLower)) return 0.9;
    if (nameLower.contains(queryLower)) return 0.7;

    // Score basé sur la similarité (algorithme simple)
    final similarity = _calculateSimilarity(queryLower, nameLower);
    return similarity * 0.6;
  }

  /// Calcule le score basé sur la distance
  double _calculateDistanceScore(double distance, int radiusKm) {
    if (distance <= 1.0) return 1.0;
    if (distance <= 2.0) return 0.8;
    if (distance <= 5.0) return 0.6;
    return 0.4;
  }

  /// Calcule la similarité entre deux chaînes
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    if (longer.isEmpty) return 1.0;

    final distance = _levenshteinDistance(longer, shorter);
    return (longer.length - distance) / longer.length;
  }

  /// Calcule la distance de Levenshtein
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Met en évidence la correspondance dans le texte
  String _highlightMatch(String query, String text) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(queryLower)) return text;

    final index = textLower.indexOf(queryLower);
    return '${text.substring(0, index)}<mark>${text.substring(index, index + query.length)}</mark>${text.substring(index + query.length)}';
  }

  /// Effectue un appel API avec authentification
  Future<Map<String, dynamic>> _makeApiCall(String url) async {
    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}'},
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw const SncfSearchException('Timeout: La requête a pris trop de temps');
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw SncfSearchException('Erreur API: ${response.statusCode}');
    }
  }
}

/// Exception pour les erreurs de recherche SNCF
class SncfSearchException implements Exception {
  final String message;
  const SncfSearchException(this.message);

  @override
  String toString() => 'SncfSearchException: $message';
}
