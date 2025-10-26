import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/train.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';

/// Service pour gérer les connexions entre gares
class ConnectedStationsService {
  /// Récupère les gares connectées à une gare donnée (approche modulaire et flexible)
  static Future<List<Station>> getConnectedStations(Station station) async {
    print('🔍 Recherche des gares connectées pour: ${station.name} (ID: ${station.id})');
    
    try {
      final trainService = DependencyInjection.instance.trainService;
      
      // Utiliser l'API SNCF pour récupérer les destinations depuis cette gare
      print('🌐 Appel API SNCF pour: ${station.name}');
      final departures = await trainService.getNextDepartures(station);
      
      // Extraire toutes les destinations disponibles
      final allDestinations = <String, Station>{};
      
      for (final departure in departures) {
        final direction = departure.direction;
        if (direction.isNotEmpty && !allDestinations.containsKey(direction)) {
          // Créer une station temporaire pour chaque destination
          allDestinations[direction] = Station(
            id: 'TEMP_${direction.hashCode}',
            name: direction,
            description: 'Destination depuis ${station.name}',
          );
        }
      }
      
      print('📍 Destinations trouvées via API: ${allDestinations.length}');
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
  static Future<bool> areStationsConnected(Station departure, Station arrival) async {
    print('🔍 Vérification de connexion: ${departure.name} → ${arrival.name}');
    
    try {
      // Récupérer les gares connectées depuis la gare de départ
      final connectedStations = await getConnectedStations(departure);
      
      print('📍 Gares connectées disponibles: ${connectedStations.length}');
      for (final station in connectedStations) {
        print('  - ${station.name} (${station.id})');
      }
      
      // Vérifier si la gare d'arrivée est dans la liste des gares connectées
      final isConnected = connectedStations.any((station) => 
        station.id == arrival.id || 
        _areStationNamesSimilar(station.name, arrival.name)
      );
      
      print('✅ Résultat: ${isConnected ? 'CONNECTÉ' : 'NON CONNECTÉ'}');
      return isConnected;
      
    } catch (e) {
      print('❌ Erreur lors de la vérification de connexion: $e');
      return false;
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
}