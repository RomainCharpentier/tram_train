import 'package:flutter/material.dart';
import '../models/train.dart';
import '../models/station.dart';
import 'get_train_departures_use_case.dart';

class TrainListController extends ChangeNotifier {
  final GetTrainDeparturesUseCase _getTrainDeparturesUseCase;
  
  List<Train> _trains = [];
  bool _isLoading = false;
  String? _error;
  Station? _selectedStation;

  TrainListController(this._getTrainDeparturesUseCase);

  List<Train> get trains => _trains;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Station? get selectedStation => _selectedStation;

  Future<void> loadDepartures(Station station) async {
    _selectedStation = station;
    _setLoading(true);
    _clearError();

    try {
      _trains = await _getTrainDeparturesUseCase.execute(station);
    } catch (e) {
      _setError('Erreur lors du chargement des trains: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    if (_selectedStation != null) {
      await loadDepartures(_selectedStation!);
    }
  }

  List<Train> getTrainsByDirection(String direction) {
    return _trains.where((train) => 
      train.direction.toLowerCase().contains(direction.toLowerCase())
    ).toList();
  }

  List<Train> getTrainsByStatus(TrainStatus status) {
    return _trains.where((train) => train.status == status).toList();
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
