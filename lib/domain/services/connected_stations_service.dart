import '../models/station.dart';

/// Service pour trouver les gares connectées à une gare donnée
class ConnectedStationsService {
  /// Gares connectées depuis Babinière (exemple)
  static const Map<String, List<Station>> _connectedStations = {
    'SNCF:87590349': [ // Babinière
      Station(id: 'SNCF:87590350', name: 'Nantes', description: 'Gare de Nantes'),
      Station(id: 'SNCF:87590351', name: 'Orvault', description: 'Gare d\'Orvault'),
      Station(id: 'SNCF:87590352', name: 'Sautron', description: 'Gare de Sautron'),
      Station(id: 'SNCF:87590353', name: 'Treillières', description: 'Gare de Treillières'),
      Station(id: 'SNCF:87590354', name: 'Blain', description: 'Gare de Blain'),
      Station(id: 'SNCF:87590355', name: 'Redon', description: 'Gare de Redon'),
      Station(id: 'SNCF:87590356', name: 'Rennes', description: 'Gare de Rennes'),
    ],
    'SNCF:87590350': [ // Nantes
      Station(id: 'SNCF:87590349', name: 'Babinière', description: 'Gare de Babinière'),
      Station(id: 'SNCF:87590357', name: 'Angers', description: 'Gare d\'Angers'),
      Station(id: 'SNCF:87590358', name: 'Le Mans', description: 'Gare du Mans'),
      Station(id: 'SNCF:87590359', name: 'Tours', description: 'Gare de Tours'),
      Station(id: 'SNCF:87590360', name: 'Orléans', description: 'Gare d\'Orléans'),
      Station(id: 'SNCF:87590361', name: 'Paris', description: 'Gare de Paris'),
    ],
  };

  /// Récupère les gares connectées à une gare donnée
  static List<Station> getConnectedStations(Station station) {
    return _connectedStations[station.id] ?? [];
  }

  /// Vérifie si deux gares sont connectées
  static bool areStationsConnected(Station station1, Station station2) {
    final connected = getConnectedStations(station1);
    return connected.any((s) => s.id == station2.id);
  }

  /// Récupère les gares connectées avec un filtre par nom
  static List<Station> getConnectedStationsWithFilter(Station station, String filter) {
    final connected = getConnectedStations(station);
    if (filter.isEmpty) return connected;
    
    return connected.where((s) => 
      s.name.toLowerCase().contains(filter.toLowerCase())
    ).toList();
  }
}

