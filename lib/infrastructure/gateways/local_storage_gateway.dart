import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../mappers/trip_mapper.dart';
import '../../domain/models/trip.dart';
import '../../domain/services/trip_service.dart';

/// Gateway pour le stockage local
class LocalStorageGateway implements TripStorage {
  final TripMapper _mapper;
  static const String _tripsKey = 'savedTrips';

  const LocalStorageGateway({
    required TripMapper mapper,
  }) : _mapper = mapper;

  /// Sauvegarde un trajet
  Future<void> saveTrip(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTrips = await getAllTrips();

    final existingIndex = existingTrips.indexWhere((t) => t.id == trip.id);
    if (existingIndex != -1) {
      existingTrips[existingIndex] = trip;
    } else {
      existingTrips.add(trip);
    }

    final tripsJson =
        existingTrips.map((trip) => json.encode(_mapper.toJson(trip))).toList();
    await prefs.setStringList(_tripsKey, tripsJson);
  }

  /// Récupère tous les trajets
  Future<List<Trip>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripsKey) ?? [];

    return tripsJson
        .map((tripJson) => _mapper.fromJson(json.decode(tripJson)))
        .toList();
  }

  /// Supprime un trajet
  Future<void> deleteTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTrips = await getAllTrips();

    existingTrips.removeWhere((trip) => trip.id == tripId);

    final tripsJson =
        existingTrips.map((trip) => json.encode(_mapper.toJson(trip))).toList();
    await prefs.setStringList(_tripsKey, tripsJson);
  }

  /// Supprime tous les trajets
  Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tripsKey);
  }
}
