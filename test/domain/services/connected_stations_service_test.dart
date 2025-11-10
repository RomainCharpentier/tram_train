import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/models/train.dart';
import 'package:train_qil/domain/services/connected_stations_service.dart';
import 'package:train_qil/domain/services/train_service.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';

void main() {
  late FakeTrainService fakeTrainService;
  final departure = Station(id: 'dep', name: 'Paris');
  final arrival = Station(id: 'arr', name: 'Lyon');

  setUpAll(() {
    fakeTrainService = FakeTrainService();
    final di = DependencyInjection.instance;
    (di as dynamic).trainService = fakeTrainService;
  });

  tearDown(() {
    fakeTrainService.reset();
  });

  test('getConnectedDestinationNames returns unique directions', () async {
    fakeTrainService.nextDepartures = [
      _train(direction: 'Lyon'),
      _train(direction: 'Marseille'),
      _train(direction: 'Lyon'),
    ];

    final names =
        await ConnectedStationsService.getConnectedDestinationNames(departure);

    expect(names..sort(), ['Lyon', 'Marseille']);
  });

  test('checkConnection returns connected when direct journey exists',
      () async {
    fakeTrainService.journeysBetween = [
      _train(direction: 'Lyon', isDirect: true),
      _train(direction: 'Lyon', isDirect: false),
    ];

    final result =
        await ConnectedStationsService.checkConnection(departure, arrival);

    expect(result.isConnected, isTrue);
    expect(result.directJourneys, 1);
    expect(result.totalJourneys, 2);
  });

  test(
      'checkConnection directOnly false returns connected even without direct journeys',
      () async {
    fakeTrainService.journeysBetween = [
      _train(direction: 'Lyon', isDirect: false),
    ];

    final result = await ConnectedStationsService.checkConnection(
      departure,
      arrival,
      directOnly: false,
    );

    expect(result.isConnected, isTrue);
    expect(result.directJourneys, 0);
    expect(result.totalJourneys, 1);
  });

  test('checkConnection returns error message when service throws', () async {
    fakeTrainService.shouldThrow = true;

    final result =
        await ConnectedStationsService.checkConnection(departure, arrival);

    expect(result.isConnected, isFalse);
    expect(result.message, contains('NON CONNECTÉ'));
  });
}

Train _train({
  required String direction,
  bool isDirect = true,
}) {
  return Train(
    id: direction,
    direction: direction,
    departureTime: DateTime.now(),
    status: TrainStatus.onTime,
    station: Station(id: 's', name: 'Station'),
    additionalInfo: [
      isDirect ? 'Type: Direct' : 'Type: Correspondance',
    ],
  );
}

class FakeTrainService extends TrainService {
  FakeTrainService() : super(_FakeTrainGateway());

  List<Train> nextDepartures = [];
  List<Train> journeysBetween = [];
  bool shouldThrow = false;

  void reset() {
    nextDepartures = [];
    journeysBetween = [];
    shouldThrow = false;
  }

  @override
  Future<List<Train>> getNextDepartures(Station station) async {
    if (shouldThrow) throw Exception('error');
    return nextDepartures;
  }

  @override
  Future<List<Train>> findJourneysBetween(
      Station fromStation, Station toStation) async {
    if (shouldThrow) throw Exception('error');
    return journeysBetween;
  }
}

class _FakeTrainGateway implements TrainGateway {
  @override
  Future<List<Train>> getDepartures(Station station) async => [];

  @override
  Future<List<Train>> getDeparturesAt(
          Station station, DateTime dateTime) async =>
      [];
}
