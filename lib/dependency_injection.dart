import 'package:http/http.dart' as http;
import 'domain/models/station.dart';
import 'domain/services/train_service.dart';
import 'domain/services/trip_service.dart';
import 'infrastructure/gateways/sncf_gateway.dart';
import 'infrastructure/gateways/local_storage_gateway.dart';
import 'infrastructure/mappers/sncf_mapper.dart';
import 'infrastructure/mappers/trip_mapper.dart';
import 'env_config.dart';

class DependencyInjection {
  static late final DependencyInjection _instance;
  static DependencyInjection get instance => _instance;

  late final TrainService _trainService;
  late final TripService _tripService;

  static const Station babiniereStation = Station(
    id: 'SNCF:87590349',
    name: 'Babinière',
    description: 'Gare de Babinière',
  );

  static const Station nantesStation = Station(
    id: 'SNCF:87590349',
    name: 'Nantes',
    description: 'Gare de Nantes',
  );

  static Future<void> initialize() async {
    _instance = DependencyInjection._();
    await _instance._setupDependencies();
  }

  DependencyInjection._();

  Future<void> _setupDependencies() async {
    final sncfMapper = SncfMapper();
    final tripMapper = TripMapper();
    
    final sncfGateway = SncfGateway(
      httpClient: http.Client(),
      apiKey: EnvConfig.apiKey ?? '',
      mapper: sncfMapper,
    );
    
    final storageGateway = LocalStorageGateway(
      mapper: tripMapper,
    );

    _trainService = TrainService(sncfGateway);
    _tripService = TripService(storageGateway);
  }

  TrainService get trainService => _trainService;
  TripService get tripService => _tripService;
}
