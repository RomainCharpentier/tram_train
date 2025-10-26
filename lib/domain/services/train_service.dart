import '../models/train.dart';
import '../models/station.dart';

abstract class TrainGateway {
  Future<List<Train>> getDepartures(Station station);
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime);
}

class TrainService {
  final TrainGateway _gateway;

  const TrainService(this._gateway);

  Future<List<Train>> getDepartures(Station station) async {
    return await _gateway.getDepartures(station);
  }

  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime) async {
    return await _gateway.getDeparturesAt(station, dateTime);
  }

  /// Récupère les prochains départs pour une gare
  Future<List<Train>> getNextDepartures(Station station) async {
    return await _gateway.getDepartures(station);
  }

  List<Train> filterByDirection(List<Train> trains, String direction) {
    return trains.where((train) => 
      train.direction.toLowerCase().contains(direction.toLowerCase())
    ).toList();
  }

  List<Train> filterByStatus(List<Train> trains, TrainStatus status) {
    return trains.where((train) => train.status == status).toList();
  }
}
