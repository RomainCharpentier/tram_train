import '../models/station.dart';
import '../models/favorite_station.dart';

/// Service pour la gestion des gares favorites
class FavoriteStationService {
  final FavoriteStationStorage _storage;

  const FavoriteStationService({
    required FavoriteStationStorage storage,
  }) : _storage = storage;

  /// Ajoute une gare aux favorites
  Future<FavoriteStation> addFavoriteStation({
    required Station station,
    String? nickname,
    int? sortOrder,
  }) async {
    final favorite = FavoriteStation(
      id: FavoriteStation.generateId(),
      station: station,
      nickname: nickname,
      sortOrder: sortOrder ?? await _getNextSortOrder(),
      createdAt: DateTime.now(),
    );

    await _storage.saveFavoriteStation(favorite);
    return favorite;
  }

  /// Récupère toutes les gares favorites
  Future<List<FavoriteStation>> getAllFavoriteStations() async {
    final favorites = await _storage.getAllFavoriteStations();
    // Trier par ordre de préférence
    favorites.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return favorites;
  }

  /// Récupère une gare favorite par ID
  Future<FavoriteStation?> getFavoriteStationById(String id) async {
    final favorites = await _storage.getAllFavoriteStations();
    try {
      return favorites.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère une gare favorite par station
  Future<FavoriteStation?> getFavoriteStationByStation(Station station) async {
    final favorites = await _storage.getAllFavoriteStations();
    try {
      return favorites.firstWhere((f) => f.station.id == station.id);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une gare est dans les favorites
  Future<bool> isStationFavorite(Station station) async {
    final favorite = await getFavoriteStationByStation(station);
    return favorite != null;
  }

  /// Met à jour une gare favorite
  Future<void> updateFavoriteStation(FavoriteStation favorite) async {
    await _storage.saveFavoriteStation(favorite);
  }

  /// Supprime une gare des favorites
  Future<void> removeFavoriteStation(String favoriteId) async {
    await _storage.deleteFavoriteStation(favoriteId);
  }

  /// Supprime une gare des favorites par station
  Future<void> removeFavoriteStationByStation(Station station) async {
    final favorite = await getFavoriteStationByStation(station);
    if (favorite != null) {
      await _storage.deleteFavoriteStation(favorite.id);
    }
  }

  /// Met à jour l'ordre des gares favorites
  Future<void> updateSortOrder(List<String> favoriteIds) async {
    for (int i = 0; i < favoriteIds.length; i++) {
      final favorite = await getFavoriteStationById(favoriteIds[i]);
      if (favorite != null) {
        final updatedFavorite = favorite.copyWith(sortOrder: i);
        await _storage.saveFavoriteStation(updatedFavorite);
      }
    }
  }

  /// Met à jour le surnom d'une gare favorite
  Future<void> updateNickname(String favoriteId, String? nickname) async {
    final favorite = await getFavoriteStationById(favoriteId);
    if (favorite != null) {
      final updatedFavorite = favorite.copyWith(nickname: nickname);
      await _storage.saveFavoriteStation(updatedFavorite);
    }
  }

  /// Récupère le prochain ordre de tri
  Future<int> _getNextSortOrder() async {
    final favorites = await _storage.getAllFavoriteStations();
    if (favorites.isEmpty) return 0;
    return favorites.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Récupère les gares favorites triées par nom
  Future<List<FavoriteStation>> getFavoriteStationsSortedByName() async {
    final favorites = await getAllFavoriteStations();
    favorites.sort((a, b) => a.station.name.compareTo(b.station.name));
    return favorites;
  }

  /// Récupère les gares favorites triées par date d'ajout
  Future<List<FavoriteStation>> getFavoriteStationsSortedByDate() async {
    final favorites = await getAllFavoriteStations();
    favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return favorites;
  }
}

/// Interface pour le stockage des gares favorites
abstract class FavoriteStationStorage {
  Future<void> saveFavoriteStation(FavoriteStation favorite);
  Future<List<FavoriteStation>> getAllFavoriteStations();
  Future<void> deleteFavoriteStation(String favoriteId);
}
