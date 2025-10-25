import 'package:http/http.dart' as http;
import 'domain/models/station.dart';
import 'domain/services/train_service.dart';
import 'domain/services/trip_service.dart';
import 'domain/services/alert_service.dart';
import 'domain/services/notification_pause_service.dart';
import 'domain/services/favorite_station_service.dart';
import 'domain/services/station_search_service.dart';
import 'infrastructure/gateways/sncf_gateway.dart';
import 'infrastructure/gateways/local_storage_gateway.dart';
import 'infrastructure/gateways/alert_storage_gateway.dart';
import 'infrastructure/gateways/notification_pause_storage_gateway.dart';
import 'infrastructure/gateways/favorite_station_storage_gateway.dart';
import 'infrastructure/gateways/notification_gateway.dart';
import 'infrastructure/gateways/sncf_search_gateway.dart';
import 'infrastructure/gateways/station_history_gateway.dart';
import 'infrastructure/mappers/sncf_mapper.dart';
import 'infrastructure/mappers/trip_mapper.dart';
import 'env_config.dart';

class DependencyInjection {
  static late final DependencyInjection _instance;
  static DependencyInjection get instance => _instance;

  late final TrainService _trainService;
  late final TripService _tripService;
  late final AlertService _alertService;
  late final NotificationPauseService _notificationPauseService;
  late final FavoriteStationService _favoriteStationService;
  late final StationSearchService _stationSearchService;

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
    
    // Initialiser les nouveaux gateways
    final alertStorage = AlertStorageGateway();
    final notificationPauseStorage = NotificationPauseStorageGateway();
    final favoriteStationStorage = FavoriteStationStorageGateway();
    final notificationGateway = SimpleNotificationGateway();
    
    // Initialiser les gateways de recherche
    final sncfSearchGateway = SncfSearchGateway(
      httpClient: http.Client(),
      apiKey: EnvConfig.apiKey ?? '',
      mapper: sncfMapper,
    );
    final stationHistoryGateway = StationHistoryGatewayImpl();
    
    // Initialiser les nouveaux services
    _notificationPauseService = NotificationPauseService(storage: notificationPauseStorage);
    _favoriteStationService = FavoriteStationService(storage: favoriteStationStorage);
    _alertService = AlertService(
      storage: alertStorage,
      notificationGateway: notificationGateway,
      pauseService: _notificationPauseService,
    );
    _stationSearchService = StationSearchService(
      searchGateway: sncfSearchGateway,
      historyGateway: stationHistoryGateway,
    );
  }

  TrainService get trainService => _trainService;
  TripService get tripService => _tripService;
  AlertService get alertService => _alertService;
  NotificationPauseService get notificationPauseService => _notificationPauseService;
  FavoriteStationService get favoriteStationService => _favoriteStationService;
  StationSearchService get stationSearchService => _stationSearchService;
}
