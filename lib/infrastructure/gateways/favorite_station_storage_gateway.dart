import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/station.dart';
import '../../domain/services/favorite_station_service.dart';

/// Gateway pour le stockage local des stations favorites
class FavoriteStationStorageGateway implements FavoriteStationStorage {
  static const String _favoritesKey = 'favorite_stations';

  @override
  Future<void> addFavoriteStation(Station station) async {
    // Ne pas permettre d'ajouter des stations temporaires
    if (station.id.startsWith('TEMP_')) {
      throw ArgumentError('Cannot add temporary station to favorites');
    }

    final prefs = await SharedPreferences.getInstance();
    final favorites = await getAllFavoriteStations();

    // Vérifier si la station n'est pas déjà en favori
    if (favorites.any((s) => s.id == station.id)) {
      return;
    }

    favorites.add(station);

    final favoritesJson =
        favorites.map((s) => _stationToJson(s)).toList();
    await prefs.setString(_favoritesKey, json.encode(favoritesJson));
  }

  @override
  Future<List<Station>> getAllFavoriteStations() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson == null) return [];

    try {
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      final stations = favoritesList.map((json) => _stationFromJson(json)).toList();
      
      // Filtrer les stations avec des IDs invalides (temporaires)
      final validStations = stations.where((s) => !s.id.startsWith('TEMP_')).toList();
      
      // Si des stations invalides ont été trouvées, les supprimer de la liste
      if (validStations.length != stations.length) {
        final validFavoritesJson = validStations.map((s) => _stationToJson(s)).toList();
        await prefs.setString(_favoritesKey, json.encode(validFavoritesJson));
      }
      
      return validStations;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> removeFavoriteStation(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getAllFavoriteStations();

    favorites.removeWhere((station) => station.id == stationId);

    final favoritesJson =
        favorites.map((s) => _stationToJson(s)).toList();
    await prefs.setString(_favoritesKey, json.encode(favoritesJson));
  }

  @override
  Future<bool> isFavoriteStation(String stationId) async {
    final favorites = await getAllFavoriteStations();
    return favorites.any((station) => station.id == stationId);
  }

  /// Convertit une station en JSON
  Map<String, dynamic> _stationToJson(Station station) {
    return {
      'id': station.id,
      'name': station.name,
      'description': station.description,
      'latitude': station.latitude,
      'longitude': station.longitude,
    };
  }

  /// Convertit un JSON en station
  Station _stationFromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }
}
