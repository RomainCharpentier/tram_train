import '../../../domain/models/station.dart';
import '../../../domain/services/favorite_station_service.dart';

/// Stockage en mémoire pour les stations favorites (mode mock)
class MockFavoriteStationStorage implements FavoriteStationStorage {
  static final List<Station> _seededFavorites = [];

  final List<Station> _favorites = [];

  MockFavoriteStationStorage() {
    if (_seededFavorites.isNotEmpty) {
      _favorites
        ..clear()
        ..addAll(_seededFavorites);
    }
  }

  /// Permet d'initialiser des favoris avant la création du storage
  static void seedFavorites(List<Station> favorites) {
    _seededFavorites
      ..clear()
      ..addAll(favorites);
  }

  @override
  Future<void> addFavoriteStation(Station station) async {
    if (station.id.startsWith('TEMP_')) {
      throw ArgumentError('Impossible d\'ajouter une station temporaire aux favoris');
    }
    if (_favorites.any((s) => s.id == station.id)) {
      return;
    }
    _favorites.add(station);
  }

  @override
  Future<List<Station>> getAllFavoriteStations() async {
    return List.unmodifiable(_favorites);
  }

  @override
  Future<void> removeFavoriteStation(String stationId) async {
    _favorites.removeWhere((station) => station.id == stationId);
  }

  @override
  Future<bool> isFavoriteStation(String stationId) async {
    return _favorites.any((station) => station.id == stationId);
  }
}
