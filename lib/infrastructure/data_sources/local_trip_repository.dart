import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/station.dart';
import '../../domain/providers/trip_repository.dart';

class LocalTripRepository implements TripRepository {
  static const String _tripsKey = 'savedTrips';

  @override
  Future<void> saveTrip(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTrips = await getAllTrips();
    
    // Vérifier si le trajet existe déjà
    final existingIndex = existingTrips.indexWhere((t) => t.id == trip.id);
    if (existingIndex != -1) {
      existingTrips[existingIndex] = trip;
    } else {
      existingTrips.add(trip);
    }
    
    final tripsJson = existingTrips.map((trip) => json.encode(_tripToJson(trip))).toList();
    await prefs.setStringList(_tripsKey, tripsJson);
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_tripsKey) ?? [];
    
    return tripsJson
        .map((tripJson) => _tripFromJson(json.decode(tripJson)))
        .toList();
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTrips = await getAllTrips();
    
    existingTrips.removeWhere((trip) => trip.id == tripId);
    
    final tripsJson = existingTrips.map((trip) => json.encode(_tripToJson(trip))).toList();
    await prefs.setStringList(_tripsKey, tripsJson);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await saveTrip(trip);
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'id': trip.id,
      'stationId': trip.station.id,
      'stationName': trip.station.name,
      'dayOfWeek': trip.dayOfWeek,
      'time': trip.time,
      'createdAt': trip.createdAt.toIso8601String(),
    };
  }

  Trip _tripFromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      station: Station(
        id: json['stationId'] as String,
        name: json['stationName'] as String,
      ),
      dayOfWeek: json['dayOfWeek'] as String,
      time: json['time'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
