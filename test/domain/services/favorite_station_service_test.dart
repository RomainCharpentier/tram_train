import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/services/favorite_station_service.dart';

void main() {
  late InMemoryFavoriteStorage storage;
  late FavoriteStationService service;

  setUp(() {
    storage = InMemoryFavoriteStorage();
    service = FavoriteStationService(storage);
  });

  final station = Station(id: '1', name: 'Paris');
  final station2 = Station(id: '2', name: 'Lyon');

  test('addFavoriteStation stores the station', () async {
    await service.addFavoriteStation(station);

    expect(await service.getAllFavoriteStations(), [station]);
  });

  test('removeFavoriteStation deletes station by id', () async {
    await service.addFavoriteStation(station);
    await service.addFavoriteStation(station2);

    await service.removeFavoriteStation(station.id);

    final favorites = await service.getAllFavoriteStations();
    expect(favorites, [station2]);
  });

  test('isFavoriteStation returns true when station exists', () async {
    await service.addFavoriteStation(station);

    expect(await service.isFavoriteStation(station.id), isTrue);
    expect(await service.isFavoriteStation('unknown'), isFalse);
  });
}

class InMemoryFavoriteStorage implements FavoriteStationStorage {
  final List<Station> _favorites = [];

  @override
  Future<void> addFavoriteStation(Station station) async {
    _favorites.removeWhere((s) => s.id == station.id);
    _favorites.add(station);
  }

  @override
  Future<List<Station>> getAllFavoriteStations() async =>
      List.unmodifiable(_favorites);

  @override
  Future<bool> isFavoriteStation(String stationId) async =>
      _favorites.any((s) => s.id == stationId);

  @override
  Future<void> removeFavoriteStation(String stationId) async {
    _favorites.removeWhere((s) => s.id == stationId);
  }
}
