import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/models/search_result.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/services/station_search_service.dart';

void main() {
  late FakeStationSearchGateway searchGateway;
  late FakeStationHistoryGateway historyGateway;
  late StationSearchService service;

  setUp(() {
    searchGateway = FakeStationSearchGateway();
    historyGateway = FakeStationHistoryGateway();
    service = StationSearchService(
      searchGateway: searchGateway,
      historyGateway: historyGateway,
    );
  });

  test('searchStations returns recent stations when query empty', () async {
    historyGateway.recentQueries = ['Paris'];
    searchGateway.resultsByQuery['Paris'] = [
      SearchResult(
        data: Station(id: '1', name: 'Paris'),
        score: 1.0,
        type: SearchResultType.exact,
      ),
    ];

    final results = await service.searchStations(' ');

    expect(results, hasLength(1));
    expect(historyGateway.recordedQueries, isEmpty);
  });

  test('searchStations calls gateway and stores history', () async {
    searchGateway.resultsByQuery['Lyon'] = [
      SearchResult(
        data: Station(id: '2', name: 'Lyon'),
        score: 0.9,
        type: SearchResultType.partial,
      ),
    ];

    final results = await service.searchStations('Lyon');

    expect(results, hasLength(1));
    expect(historyGateway.recordedQueries, ['Lyon']);
  });

  test('searchNearbyStations returns empty when coordinates missing', () async {
    final results = await service.searchNearbyStations();
    expect(results, isEmpty);
  });

  test('getSearchSuggestions filters recent queries', () async {
    historyGateway.recentQueries = ['Paris', 'Lyon', 'Lille'];

    final suggestions = await service.getSearchSuggestions('li');

    expect(suggestions, ['Lille']);
  });
}

class FakeStationSearchGateway implements StationSearchGateway {
  final Map<String, List<SearchResult<Station>>> resultsByQuery = {};

  @override
  Future<List<SearchResult<Station>>> advancedSearch({
    String? query,
    String? lineId,
    TransportType? transportType,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async =>
      resultsByQuery[query] ?? [];

  @override
  Future<List<SearchResult<Station>>> getFavoriteStations() async =>
      resultsByQuery['favorites'] ?? [];

  @override
  Future<List<SearchResult<Station>>> searchNearbyStations({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async =>
      resultsByQuery['nearby'] ?? [];

  @override
  Future<List<SearchResult<Station>>> searchStations(String query) async =>
      resultsByQuery[query] ?? [];

  @override
  Future<List<SearchResult<Station>>> searchStationsByLine(
          String lineId) async =>
      resultsByQuery['line:$lineId'] ?? [];

  @override
  Future<List<SearchResult<Station>>> searchStationsByType(
          TransportType type) async =>
      resultsByQuery['type:${type.name}'] ?? [];
}

class FakeStationHistoryGateway implements StationHistoryGateway {
  List<String> recentQueries = [];
  final List<String> recordedQueries = [];

  @override
  Future<void> addSearchQuery(String query) async {
    recordedQueries.add(query);
    recentQueries.insert(0, query);
  }

  @override
  Future<void> clearHistory() async {
    recentQueries.clear();
    recordedQueries.clear();
  }

  @override
  Future<List<String>> getRecentQueries() async =>
      List.unmodifiable(recentQueries);
}
