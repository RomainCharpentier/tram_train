import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/station.dart';
import 'manage_trip_use_case.dart';

class TripController extends ChangeNotifier {
  final ManageTripUseCase _manageTripUseCase;
  
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;

  TripController(this._manageTripUseCase);

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrips() async {
    _setLoading(true);
    _clearError();

    try {
      _trips = await _manageTripUseCase.getAllTrips();
    } catch (e) {
      _setError('Erreur lors du chargement des trajets: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTrip({
    required Station station,
    required String dayOfWeek,
    required String time,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _manageTripUseCase.createTrip(
        station: station,
        dayOfWeek: dayOfWeek,
        time: time,
      );
      await loadTrips(); // Recharger la liste
    } catch (e) {
      _setError('Erreur lors de la création du trajet: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTrip(String tripId) async {
    _setLoading(true);
    _clearError();

    try {
      await _manageTripUseCase.deleteTrip(tripId);
      await loadTrips(); // Recharger la liste
    } catch (e) {
      _setError('Erreur lors de la suppression du trajet: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTrip(Trip trip) async {
    _setLoading(true);
    _clearError();

    try {
      await _manageTripUseCase.updateTrip(trip);
      await loadTrips(); // Recharger la liste
    } catch (e) {
      _setError('Erreur lors de la mise à jour du trajet: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<Trip> getTripsByDay(String dayOfWeek) {
    return _trips.where((trip) => trip.dayOfWeek == dayOfWeek).toList();
  }

  List<Trip> getTripsByStation(Station station) {
    return _trips.where((trip) => trip.station.id == station.id).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
