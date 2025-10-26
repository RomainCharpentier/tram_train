import '../models/station.dart';
import '../models/search_result.dart';

/// Service pour la recherche intelligente de gares
class StationSearchService {
  final StationSearchGateway _searchGateway;
  final StationHistoryGateway? _historyGateway;

  const StationSearchService({
    required StationSearchGateway searchGateway,
    StationHistoryGateway? historyGateway,
  }) : _searchGateway = searchGateway, _historyGateway = historyGateway;

  /// Recherche des gares par nom avec suggestions intelligentes
  Future<List<SearchResult<Station>>> searchStations(String query) async {
    if (query.trim().isEmpty) {
      return await getRecentStations();
    }

    final results = await _searchGateway.searchStations(query);
    
    // Enregistrer la recherche dans l'historique
    if (_historyGateway != null) {
      await _historyGateway!.addSearchQuery(query);
    }
    
    return results;
  }

  /// Recherche des gares les plus proches
  Future<List<SearchResult<Station>>> searchNearbyStations({
    double? latitude,
    double? longitude,
    int radiusKm = 5,
  }) async {
    if (latitude == null || longitude == null) {
      return [];
    }

    return await _searchGateway.searchNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Recherche par ligne
  Future<List<SearchResult<Station>>> searchStationsByLine(String lineId) async {
    return await _searchGateway.searchStationsByLine(lineId);
  }

  /// Recherche par type de transport
  Future<List<SearchResult<Station>>> searchStationsByType(TransportType type) async {
    return await _searchGateway.searchStationsByType(type);
  }

  /// Récupère les gares récemment consultées
  Future<List<SearchResult<Station>>> getRecentStations() async {
    if (_historyGateway == null) {
      return [];
    }
    
    final recentQueries = await _historyGateway!.getRecentQueries();
    final results = <SearchResult<Station>>[];

    for (final query in recentQueries) {
      final stations = await _searchGateway.searchStations(query);
      results.addAll(stations);
    }

    return results;
  }

  /// Récupère les gares favorites avec recherche
  Future<List<SearchResult<Station>>> getFavoriteStations() async {
    return await _searchGateway.getFavoriteStations();
  }

  /// Recherche intelligente avec suggestions
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];

    if (_historyGateway == null) {
      return [];
    }
    
    final recentQueries = await _historyGateway!.getRecentQueries();
    final suggestions = recentQueries
        .where((query) => query.toLowerCase().contains(partialQuery.toLowerCase()))
        .take(5)
        .toList();

    return suggestions;
  }

  /// Recherche avancée avec filtres
  Future<List<SearchResult<Station>>> advancedSearch({
    String? query,
    String? lineId,
    TransportType? transportType,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    return await _searchGateway.advancedSearch(
      query: query,
      lineId: lineId,
      transportType: transportType,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}

/// Types de transport disponibles
enum TransportType {
  train('Train'),
  tram('Tram'),
  bus('Bus'),
  metro('Métro'),
  all('Tous');

  const TransportType(this.displayName);
  final String displayName;
}

/// Interface pour la recherche de gares
abstract class StationSearchGateway {
  Future<List<SearchResult<Station>>> searchStations(String query);
  Future<List<SearchResult<Station>>> searchNearbyStations({
    required double latitude,
    required double longitude,
    required int radiusKm,
  });
  Future<List<SearchResult<Station>>> searchStationsByLine(String lineId);
  Future<List<SearchResult<Station>>> searchStationsByType(TransportType type);
  Future<List<SearchResult<Station>>> getFavoriteStations();
  Future<List<SearchResult<Station>>> advancedSearch({
    String? query,
    String? lineId,
    TransportType? transportType,
    double? latitude,
    double? longitude,
    int? radiusKm,
  });
}

/// Interface pour l'historique des recherches
abstract class StationHistoryGateway {
  Future<void> addSearchQuery(String query);
  Future<List<String>> getRecentQueries();
  Future<void> clearHistory();
}
