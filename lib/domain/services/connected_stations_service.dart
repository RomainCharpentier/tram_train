import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/train.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';

/// Service pour gérer les connexions entre gares
class ConnectedStationsService {
  /// Récupère les gares connectées à une gare donnée (destinations finales uniquement)
  static Future<List<Station>> getConnectedStations(Station station) async {
    print('🔍 Recherche des gares connectées pour: ${station.name} (ID: ${station.id})');
    
    try {
      final trainService = DependencyInjection.instance.trainService;
      
      // Utiliser l'API SNCF pour récupérer les départs depuis cette gare
      print('🌐 Appel API SNCF pour: ${station.name}');
      final departures = await trainService.getNextDepartures(station);
      
      // Extraire seulement les destinations finales (pas les arrêts intermédiaires)
      final allDestinations = <String, Station>{};
      
      for (final departure in departures) {
        final direction = departure.direction;
        if (direction.isNotEmpty && !allDestinations.containsKey(direction)) {
          allDestinations[direction] = Station(
            id: 'TEMP_${direction.hashCode}',
            name: direction,
            description: 'Destination depuis ${station.name}',
          );
        }
      }
      
      print('📍 Destinations finales trouvées via API: ${allDestinations.length}');
      for (final destination in allDestinations.values) {
        print('  - ${destination.name} (${destination.id})');
      }
      
      return allDestinations.values.toList();
      
    } catch (e) {
      print('❌ Erreur API pour ${station.name}: $e');
      
      // Fallback : retourner une liste vide pour forcer la recherche globale
      print('📍 Aucune connexion trouvée - Recherche globale recommandée');
      return [];
    }
  }
  
  /// Vérifie si deux gares sont connectées directement
  static Future<bool> areStationsConnected(Station departure, Station arrival, {bool directOnly = true}) async {
    print('🔍 Vérification de connexion: ${departure.name} → ${arrival.name} (direct uniquement: $directOnly)');
    
    try {
      final trainService = DependencyInjection.instance.trainService;
      
      // Utiliser l'API des trajets pour vérifier s'il existe un trajet direct
      print('🌐 Vérification via API des trajets: ${departure.name} → ${arrival.name}');
      final journeys = await trainService.findJourneysBetween(departure, arrival);
      
      // Filtrer les trajets selon le critère (direct ou tous)
      List<Train> filteredJourneys = journeys;
      if (directOnly) {
        // Filtrer pour ne garder que les trajets directs
        filteredJourneys = journeys.where((journey) => journey.isDirect).toList();
        print('🔍 Filtrage des trajets directs: ${journeys.length} → ${filteredJourneys.length}');
      }
      
      final isConnected = filteredJourneys.isNotEmpty;
      
      print('🚂 Trajets trouvés: ${journeys.length} (filtrés: ${filteredJourneys.length})');
      if (filteredJourneys.isNotEmpty) {
        print('✅ Résultat: CONNECTÉ - ${filteredJourneys.length} trajet(s) trouvé(s)');
        
        // Afficher les détails des trajets pour debug
        for (int i = 0; i < filteredJourneys.length && i < 3; i++) {
          final journey = filteredJourneys[i];
          print('  Trajet ${i + 1}: ${journey.direction} (${journey.status})');
        }
        if (filteredJourneys.length > 3) {
          print('  ... et ${filteredJourneys.length - 3} autres trajets');
        }
      } else {
        print('❌ Résultat: NON CONNECTÉ - Aucun trajet trouvé');
      }
      
      return isConnected;
    } catch (e) {
      print('❌ Erreur lors de la vérification de connexion: $e');
      
      // Fallback : vérifier via les destinations finales
      print('🔄 Fallback: vérification via destinations finales');
      try {
        final connectedStations = await getConnectedStations(departure);
        final isConnected = connectedStations.any((s) =>
            _areStationNamesSimilar(s.name, arrival.name) || s.id == arrival.id);
        
        print('📍 Gares connectées disponibles: ${connectedStations.length}');
        for (var s in connectedStations) {
          print('  - ${s.name} (${s.id})');
        }
        print('✅ Résultat fallback: ${isConnected ? 'CONNECTÉ' : 'NON CONNECTÉ'}');
        return isConnected;
      } catch (fallbackError) {
        print('❌ Erreur fallback: $fallbackError');
        return false;
      }
    }
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
    Station departureStation, 
    String searchQuery
  ) async {
    final allConnectedStations = await getConnectedStations(departureStation);
    
    if (searchQuery.isEmpty) {
      return allConnectedStations;
    }
    
    final query = searchQuery.toLowerCase();
    return allConnectedStations.where((station) =>
      station.name.toLowerCase().contains(query) ||
      (station.description?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  /// Normalise un nom de gare pour la comparaison
  static String _normalizeStationName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)-]'), '') // Supprime parenthèses, tirets
        .replaceAll(RegExp(r'\s+'), ' ') // Remplace multiples espaces par un seul
        .trim();
  }
}