import '../models/station.dart';

/// Interface abstraite pour le stockage des stations favorites
abstract class FavoriteStationStorage {
  Future<void> addFavoriteStation(Station station);
  Future<List<Station>> getAllFavoriteStations();
  Future<void> removeFavoriteStation(String stationId);
  Future<bool> isFavoriteStation(String stationId);
}

/// Service de gestion des stations favorites
class FavoriteStationService {
  final FavoriteStationStorage _storage;

  const FavoriteStationService(this._storage);

  /// Ajoute une station aux favoris
  Future<void> addFavoriteStation(Station station) async {
    await _storage.addFavoriteStation(station);
  }

  /// Récupère toutes les stations favorites
  Future<List<Station>> getAllFavoriteStations() async {
    return await _storage.getAllFavoriteStations();
  }

  /// Supprime une station des favoris
  Future<void> removeFavoriteStation(String stationId) async {
    await _storage.removeFavoriteStation(stationId);
  }

  /// Vérifie si une station est en favori
  Future<bool> isFavoriteStation(String stationId) async {
    return await _storage.isFavoriteStation(stationId);
  }
}
