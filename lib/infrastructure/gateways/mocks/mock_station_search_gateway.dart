import '../../../domain/models/station.dart';
import '../../../domain/models/search_result.dart';
import '../../../domain/services/station_search_service.dart';

/// Implémentation mock de StationSearchGateway
class MockStationSearchGateway implements StationSearchGateway {
  final List<Station> _mockStations = [
    const Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Nord',
      latitude: 48.8809,
      longitude: 2.3553,
    ),
    const Station(
      id: 'stop_point:SNCF:87286025',
      name: 'Lille Europe',
      latitude: 50.6394,
      longitude: 3.0758,
    ),
    const Station(
      id: 'stop_point:SNCF:87751008',
      name: 'Lyon Part-Dieu',
      latitude: 45.7606,
      longitude: 4.8604,
    ),
    const Station(
      id: 'stop_point:SNCF:87751000',
      name: 'Marseille St-Charles',
      latitude: 43.3032,
      longitude: 5.3842,
    ),
    const Station(
      id: 'stop_point:SNCF:87581009',
      name: 'Bordeaux St-Jean',
      latitude: 44.8258,
      longitude: -0.5563,
    ),
    const Station(
      id: 'stop_point:SNCF:87471003',
      name: 'Paris Gare de Lyon',
      latitude: 48.8445,
      longitude: 2.3732,
    ),
    const Station(
      id: 'stop_point:SNCF:87113001',
      name: 'Paris Montparnasse',
      latitude: 48.8412,
      longitude: 2.3216,
    ),
    const Station(
      id: 'stop_point:SNCF:87384008',
      name: 'Paris Est',
      latitude: 48.8786,
      longitude: 2.3592,
    ),
    const Station(
      id: 'stop_point:SNCF:87722025',
      name: 'Nantes',
      latitude: 47.2184,
      longitude: -1.5416,
    ),
    const Station(
      id: 'stop_point:SNCF:87758001',
      name: 'Toulouse Matabiau',
      latitude: 43.6110,
      longitude: 1.4538,
    ),
    const Station(
      id: 'stop_point:SNCF:87686006',
      name: 'Strasbourg',
      latitude: 48.5734,
      longitude: 7.7521,
    ),
    const Station(
      id: 'stop_point:SNCF:87547000',
      name: 'Rennes',
      latitude: 48.1035,
      longitude: -1.6746,
    ),
  ];

  @override
  Future<List<SearchResult<Station>>> searchStations(String query) async {
    if (query.trim().isEmpty) return [];

    final queryLower = query.trim().toLowerCase();
    final queryWords = queryLower.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final results = <SearchResult<Station>>[];

    for (final station in _mockStations) {
      final stationNameLower = station.name.toLowerCase();

      // Vérifier si tous les mots de la requête sont présents dans le nom
      bool matches = true;
      if (queryWords.isNotEmpty) {
        matches = queryWords.every((word) => stationNameLower.contains(word));
      }

      if (matches) {
        // Calculer un score basé sur :
        // 1. Correspondance exacte = score maximal
        // 2. Commence par la requête = score élevé
        // 3. Contient la requête = score moyen
        // 4. Nombre de mots correspondants
        double score = 0.0;

        if (stationNameLower == queryLower) {
          score = 1.0;
        } else if (stationNameLower.startsWith(queryLower)) {
          score = 0.9;
        } else if (stationNameLower.contains(queryLower)) {
          score = 0.7;
        } else {
          // Score basé sur le nombre de mots correspondants
          final matchingWords = queryWords.where((word) => stationNameLower.contains(word)).length;
          score = matchingWords / queryWords.length * 0.6;
        }

        // Bonus si le nom commence par un mot de la requête
        if (queryWords.isNotEmpty && stationNameLower.startsWith(queryWords.first)) {
          score += 0.1;
        }

        results.add(SearchResult.partial(station, score.clamp(0.0, 1.0)));
      }
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
    // Retourner toutes les stations mock pour l'instant
    return _mockStations.map((s) => SearchResult.exact(s)).toList();
  }

  @override
  Future<List<SearchResult<Station>>> searchStationsByLine(String lineId) async {
    return [];
  }

  @override
  Future<List<SearchResult<Station>>> searchStationsByType(TransportType type) async {
    return _mockStations.map((s) => SearchResult.exact(s)).toList();
  }

  @override
  Future<List<SearchResult<Station>>> getFavoriteStations() async {
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
    if (query != null && query.isNotEmpty) {
      return await searchStations(query);
    }
    return _mockStations.map((s) => SearchResult.exact(s)).toList();
  }
}
