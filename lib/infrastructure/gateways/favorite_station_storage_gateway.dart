import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/favorite_station.dart';
import '../../domain/models/station.dart';
import '../../domain/services/favorite_station_service.dart';

/// Gateway pour le stockage local des gares favorites
class FavoriteStationStorageGateway implements FavoriteStationStorage {
  static const String _favoritesKey = 'favorite_stations';

  @override
  Future<void> saveFavoriteStation(FavoriteStation favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getAllFavoriteStations();
    
    // Remplacer la gare favorite existante ou ajouter la nouvelle
    final existingIndex = favorites.indexWhere((f) => f.id == favorite.id);
    if (existingIndex != -1) {
      favorites[existingIndex] = favorite;
    } else {
      favorites.add(favorite);
    }
    
    final favoritesJson = favorites.map((favorite) => _favoriteToJson(favorite)).toList();
    await prefs.setString(_favoritesKey, json.encode(favoritesJson));
  }

  @override
  Future<List<FavoriteStation>> getAllFavoriteStations() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson == null) return [];
    
    final List<dynamic> favoritesList = json.decode(favoritesJson);
    return favoritesList.map((json) => _favoriteFromJson(json)).toList();
  }

  @override
  Future<void> deleteFavoriteStation(String favoriteId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getAllFavoriteStations();
    
    favorites.removeWhere((favorite) => favorite.id == favoriteId);
    
    final favoritesJson = favorites.map((favorite) => _favoriteToJson(favorite)).toList();
    await prefs.setString(_favoritesKey, json.encode(favoritesJson));
  }

  /// Convertit une gare favorite en JSON
  Map<String, dynamic> _favoriteToJson(FavoriteStation favorite) {
    return {
      'id': favorite.id,
      'station': {
        'id': favorite.station.id,
        'name': favorite.station.name,
        'description': favorite.station.description,
      },
      'nickname': favorite.nickname,
      'sortOrder': favorite.sortOrder,
      'createdAt': favorite.createdAt.toIso8601String(),
    };
  }

  /// Convertit un JSON en gare favorite
  FavoriteStation _favoriteFromJson(Map<String, dynamic> json) {
    return FavoriteStation(
      id: json['id'] as String,
      station: Station(
        id: json['station']['id'] as String,
        name: json['station']['name'] as String,
        description: json['station']['description'] as String,
      ),
      nickname: json['nickname'] as String?,
      sortOrder: json['sortOrder'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
