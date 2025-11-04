import '../../../domain/services/station_search_service.dart';

/// Implémentation mock de StationHistoryGateway
class MockStationHistoryGateway implements StationHistoryGateway {
  final List<String> _searchHistory = [];

  @override
  Future<void> addSearchQuery(String query) async {
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
  }

  @override
  Future<List<String>> getRecentQueries() async {
    return _searchHistory.take(5).toList();
  }

  @override
  Future<void> clearHistory() async {
    _searchHistory.clear();
  }
}

