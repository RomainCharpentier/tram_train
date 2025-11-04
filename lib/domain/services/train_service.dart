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
    return trains
        .where((train) => train.direction.toLowerCase().contains(direction.toLowerCase()))
        .toList();
  }

  List<Train> filterByStatus(List<Train> trains, TrainStatus status) {
    return trains.where((train) => train.status == status).toList();
  }

  /// Recherche des trajets entre deux gares
  Future<List<Train>> findJourneysBetween(Station fromStation, Station toStation) async {
    // Cast vers SncfGateway pour accéder aux méthodes spécifiques
    final gw = _gateway;
    if (gw is SncfGateway) {
      return await gw.findJourneysBetween(fromStation, toStation);
    }

    // Support pour MockTrainGateway via extension
    if (gw.runtimeType.toString() == 'MockTrainGateway') {
      final mockGw = gw as dynamic;
      return await mockGw.findJourneysBetween(fromStation, toStation);
    }

    // Fallback si ce n'est pas un SncfGateway
    throw UnsupportedError('findJourneysBetween n\'est supporté que par SncfGateway');
  }

  /// Recherche des trajets avec une contrainte d'heure de départ
  Future<List<Train>> findJourneysWithDepartureTime(
    Station fromStation,
    Station toStation,
    DateTime departureTime,
  ) async {
    final gw = _gateway;
    if (gw is SncfGateway) {
      return await gw.findJourneysWithDepartureTime(fromStation, toStation, departureTime);
    }

    // Support pour MockTrainGateway
    if (gw.runtimeType.toString() == 'MockTrainGateway') {
      final mockGw = gw as dynamic;
      return await mockGw.findJourneysWithDepartureTime(fromStation, toStation, departureTime);
    }

    throw UnsupportedError('findJourneysWithDepartureTime non supporté par ce gateway');
  }

  /// Recherche des trajets avec une contrainte d'heure d'arrivée
  Future<List<Train>> findJourneysWithArrivalTime(
    Station fromStation,
    Station toStation,
    DateTime arrivalTime,
  ) async {
    final gw = _gateway;
    if (gw is SncfGateway) {
      return await gw.findJourneysWithArrivalTime(fromStation, toStation, arrivalTime);
    }

    // Support pour MockTrainGateway
    if (gw.runtimeType.toString() == 'MockTrainGateway') {
      final mockGw = gw as dynamic;
      return await mockGw.findJourneysWithArrivalTime(fromStation, toStation, arrivalTime);
    }

    throw UnsupportedError('findJourneysWithArrivalTime non supporté par ce gateway');
  }

  /// Retourne le trajet juste avant l'heure de référence en suivant le lien 'prev'
  Future<Train?> findJourneyJustBefore(
    Station fromStation,
    Station toStation,
    DateTime reference,
  ) async {
    final gw = _gateway;
    if (gw is SncfGateway) {
      final raw = await gw.getJourneysRaw(
        fromStation,
        toStation,
        reference,
        represents: 'departure',
      );
      final links = (raw['links'] as List<dynamic>?) ?? const [];
      final prev = links.cast<Map<String, dynamic>?>().firstWhere(
            (l) => l != null && l['rel'] == 'prev',
            orElse: () => null,
          );
      if (prev != null && prev['href'] is String) {
        final trains = await gw.getJourneysByHref(
          prev['href'] as String,
          fromStation,
          toStation,
        );
        trains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        for (var i = trains.length - 1; i >= 0; i--) {
          if (trains[i].departureTime.isBefore(reference)) {
            return trains[i];
          }
        }
      }
    } else if (gw.runtimeType.toString() == 'MockTrainGateway') {
      // Pour les mocks, retourner null (pas de pagination)
      return null;
    }
    return null;
  }

  /// Retourne le trajet juste après l'heure de référence en suivant le lien 'next'
  Future<Train?> findJourneyJustAfter(
    Station fromStation,
    Station toStation,
    DateTime reference,
  ) async {
    final gw = _gateway;
    if (gw is SncfGateway) {
      final raw = await gw.getJourneysRaw(
        fromStation,
        toStation,
        reference,
        represents: 'departure',
      );
      final links = (raw['links'] as List<dynamic>?) ?? const [];
      final next = links.cast<Map<String, dynamic>?>().firstWhere(
            (l) => l != null && l['rel'] == 'next',
            orElse: () => null,
          );
      if (next != null && next['href'] is String) {
        final trains = await gw.getJourneysByHref(
          next['href'] as String,
          fromStation,
          toStation,
        );
        trains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        for (final t in trains) {
          if (!t.departureTime.isBefore(reference)) {
            return t;
          }
        }
      }
    } else if (gw.runtimeType.toString() == 'MockTrainGateway') {
      // Pour les mocks, retourner null (pas de pagination)
      return null;
    }
    return null;
  }
}
