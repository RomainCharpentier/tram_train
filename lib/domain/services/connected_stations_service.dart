import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';

/// Résultat de vérification de connexion entre deux gares
class ConnectionResult {
  final bool isConnected;
  final int totalJourneys;
  final int directJourneys;
  final String message;

  ConnectionResult({
    required this.isConnected,
    required this.totalJourneys,
    required this.directJourneys,
    required this.message,
  });
}

/// Service pour gérer les connexions entre gares
class ConnectedStationsService {
  /// Récupère les noms des destinations connectées à une gare donnée
  static Future<List<String>> getConnectedDestinationNames(
      Station station) async {
    try {
      final trainService = DependencyInjection.instance.trainService;

      // Utiliser l'API SNCF pour récupérer les départs depuis cette gare
      final departures = await trainService.getNextDepartures(station);

      // Extraire seulement les destinations finales (pas les arrêts intermédiaires)
      final destinationNames = <String>{};

      for (final departure in departures) {
        final direction = departure.direction;
        if (direction.isNotEmpty) {
          destinationNames.add(direction);
        }
      }

      return destinationNames.toList();
    } on Object catch (_) {
      // Fallback : retourner une liste vide
      return [];
    }
  }

  /// Récupère les gares connectées à une gare donnée (destinations finales uniquement)
  /// Cette méthode est dépréciée - utiliser getConnectedDestinationNames à la place
  @Deprecated(
      'Utiliser getConnectedDestinationNames et faire une recherche globale')
  static Future<List<Station>> getConnectedStations(Station station) async {
    // Retourner une liste vide pour forcer la recherche globale
    return [];
  }

  /// Vérifie si deux gares sont connectées
  static Future<ConnectionResult> checkConnection(
      Station departure, Station arrival,
      {bool directOnly = true}) async {
    try {
      final trainService = DependencyInjection.instance.trainService;

      // Utiliser l'API des trajets pour vérifier s'il existe un trajet
      final journeys =
          await trainService.findJourneysBetween(departure, arrival);

      final totalJourneys = journeys.length;
      final directJourneys =
          journeys.where((journey) => journey.isDirect).length;

      // Déterminer le résultat selon les critères
      if (totalJourneys == 0) {
        return ConnectionResult(
          isConnected: false,
          totalJourneys: 0,
          directJourneys: 0,
          message: 'Aucun trajet trouvé',
        );
      }

      if (directOnly) {
        // Mode "direct uniquement"
        if (directJourneys > 0) {
          return ConnectionResult(
            isConnected: true,
            totalJourneys: totalJourneys,
            directJourneys: directJourneys,
            message: 'CONNECTÉ - $directJourneys trajet(s) direct(s) trouvé(s)',
          );
        } else {
          return ConnectionResult(
            isConnected: false,
            totalJourneys: totalJourneys,
            directJourneys: 0,
            message:
                'NON CONNECTÉ - Aucun trajet direct trouvé ($totalJourneys trajet(s) avec correspondances)',
          );
        }
      } else {
        // Mode "tous les trajets"
        return ConnectionResult(
          isConnected: true,
          totalJourneys: totalJourneys,
          directJourneys: directJourneys,
          message:
              'CONNECTÉ - $totalJourneys trajet(s) trouvé(s) ($directJourneys direct(s))',
        );
      }
    } on Object catch (_) {
      // Fallback : vérifier via les destinations finales
      try {
        // ignore: deprecated_member_use_from_same_package
        final connectedStations = await getConnectedStations(departure);
        final isConnected = connectedStations.any((s) =>
            _areStationNamesSimilar(s.name, arrival.name) ||
            s.id == arrival.id);

        return ConnectionResult(
          isConnected: isConnected,
          totalJourneys: isConnected ? 1 : 0,
          directJourneys: isConnected ? 1 : 0,
          message: isConnected
              ? 'CONNECTÉ - Vérifié via destinations'
              : 'NON CONNECTÉ - Aucune connexion trouvée',
        );
      } on Object catch (_) {
        return ConnectionResult(
          isConnected: false,
          totalJourneys: 0,
          directJourneys: 0,
          message: 'NON CONNECTÉ - Erreur lors de la vérification',
        );
      }
    }
  }

  /// Vérifie si deux gares sont connectées directement (méthode de compatibilité)
  @Deprecated('Utiliser checkConnection à la place')
  static Future<bool> areStationsConnected(Station departure, Station arrival,
      {bool directOnly = true}) async {
    final result =
        await checkConnection(departure, arrival, directOnly: directOnly);
    return result.isConnected;
  }

  /// Compare deux noms de gares de manière flexible
  static bool _areStationNamesSimilar(String name1, String name2) {
    // Normaliser les noms (supprimer les parenthèses, tirets, espaces multiples)
    final normalized1 = name1
        .replaceAll(RegExp(r'[()\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    final normalized2 = name2
        .replaceAll(RegExp(r'[()\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    // Vérifier l'égalité exacte ou si un nom contient l'autre
    return normalized1 == normalized2 ||
        normalized1.contains(normalized2) ||
        normalized2.contains(normalized1);
  }

  /// Récupère les gares connectées avec filtrage par nom
  static Future<List<Station>> getConnectedStationsWithFilter(
      Station departureStation, String searchQuery) async {
    // ignore: deprecated_member_use_from_same_package
    final allConnectedStations = await getConnectedStations(departureStation);

    if (searchQuery.isEmpty) {
      return allConnectedStations;
    }

    final query = searchQuery.toLowerCase();
    return allConnectedStations
        .where((station) =>
            station.name.toLowerCase().contains(query) ||
            (station.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }
}
