import 'package:http/http.dart' as http;
import 'package:train_qil/domain/services/trip_service.dart';
import 'package:train_qil/domain/services/train_service.dart';
import 'package:train_qil/domain/services/station_search_service.dart';
import 'package:train_qil/domain/services/notification_pause_service.dart';
import 'package:train_qil/domain/services/theme_service.dart';
import 'package:train_qil/domain/services/notification_service.dart';
import 'package:train_qil/domain/services/favorite_station_service.dart';
import 'package:train_qil/infrastructure/gateways/local_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/infrastructure/gateways/sncf_search_gateway.dart';
import 'package:train_qil/infrastructure/gateways/notification_pause_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/favorite_station_storage_gateway.dart';
import 'package:train_qil/infrastructure/mappers/trip_mapper.dart';
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/env_config.dart';

/// Classe de gestion de l'injection de dépendances
class DependencyInjection {
  static final DependencyInjection _instance = DependencyInjection._internal();
  factory DependencyInjection() => _instance;
  DependencyInjection._internal();

  static DependencyInjection get instance => _instance;

  // Services
  late final TripService tripService;
  late final TrainService trainService;
  late final StationSearchService stationSearchService;
  late final NotificationPauseService notificationPauseService;
  late final ThemeService themeService;
  late final NotificationService notificationService;
  late final FavoriteStationService favoriteStationService;

  // Gateways
  late final LocalStorageGateway localStorageGateway;
  late final SncfGateway sncfGateway;
  late final SncfSearchGateway sncfSearchGateway;
  late final NotificationPauseStorageGateway notificationPauseStorageGateway;
  late final FavoriteStationStorageGateway favoriteStationStorageGateway;

  // Mappers
  late final TripMapper tripMapper;
  late final SncfMapper sncfMapper;

  // HTTP Client
  late final http.Client httpClient;

  /// Initialise toutes les dépendances
  static Future<void> initialize() async {
    final instance = DependencyInjection.instance;

    // Initialisation des mappers
    instance.tripMapper = TripMapper();
    instance.sncfMapper = SncfMapper();

    // Initialisation du client HTTP
    instance.httpClient = http.Client();

    // Initialisation des gateways
    instance.localStorageGateway =
        LocalStorageGateway(mapper: instance.tripMapper);
    instance.sncfGateway = SncfGateway(
      httpClient: instance.httpClient,
      apiKey: EnvConfig.apiKey ?? 'default-key',
      mapper: instance.sncfMapper,
    );
    instance.sncfSearchGateway = SncfSearchGateway(
      httpClient: instance.httpClient,
      apiKey: EnvConfig.apiKey ?? 'default-key',
      mapper: instance.sncfMapper,
    );
    instance.notificationPauseStorageGateway =
        NotificationPauseStorageGateway();
    instance.favoriteStationStorageGateway =
        FavoriteStationStorageGateway();

    // Initialisation des services
    instance.tripService = TripService(instance.localStorageGateway);
    instance.trainService = TrainService(instance.sncfGateway);
    instance.stationSearchService = StationSearchService(
      searchGateway: instance.sncfSearchGateway,
    );
    instance.notificationPauseService = NotificationPauseService(
        storage: instance.notificationPauseStorageGateway);
    instance.favoriteStationService = FavoriteStationService(
        instance.favoriteStationStorageGateway);
    instance.themeService = ThemeService();
    instance.notificationService = NotificationService();

    // Initialisation des services
    await instance.themeService.initialize();
    await instance.notificationService.initialize();
  }
}
