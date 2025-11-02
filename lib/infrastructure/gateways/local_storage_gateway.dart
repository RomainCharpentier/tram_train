import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    await _saveTrips(existingTrips);
  }

  Future<void> _saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson =
        trips.map((trip) => json.encode(_mapper.toJson(trip))).toList();
    await prefs.setStringList(_tripsKey, tripsJson);
  }

  /// Récupère tous les trajets
  Future<List<Trip>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripsKey) ?? [];

    final List<Trip> validTrips = [];
    for (final tripJson in tripsJson) {
      try {
        final decoded = json.decode(tripJson);
        final trip = _mapper.fromJson(decoded);
        validTrips.add(trip);
      } catch (e) {
        debugPrint('Erreur lors du décodage d\'un trajet: $e');
      }
    }

    if (validTrips.length != tripsJson.length && validTrips.isNotEmpty) {
      await _saveTrips(validTrips);
    }

    return validTrips;
  }

  /// Supprime un trajet
  Future<void> deleteTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTrips = await getAllTrips();

    existingTrips.removeWhere((trip) => trip.id == tripId);

    await _saveTrips(existingTrips);
  }

  /// Supprime tous les trajets
  Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tripsKey);
  }
}
