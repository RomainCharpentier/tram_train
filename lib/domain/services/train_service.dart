import '../models/train.dart';
import '../models/station.dart';
import '../../infrastructure/gateways/sncf_gateway.dart';

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

  /// Recherche des trajets entre deux gares
  Future<List<Train>> findJourneysBetween(Station fromStation, Station toStation) async {
    // Cast vers SncfGateway pour accéder aux méthodes spécifiques
    if (_gateway is SncfGateway) {
      final sncfGateway = _gateway as SncfGateway;
      return await sncfGateway.findJourneysBetween(fromStation, toStation);
    }
    
    // Fallback si ce n'est pas un SncfGateway
    throw UnsupportedError('findJourneysBetween n\'est supporté que par SncfGateway');
  }
}
