import 'package:http/http.dart' as http;
import 'package:train_qil/domain/services/trip_service.dart';
import 'package:train_qil/domain/services/train_service.dart';
import 'package:train_qil/domain/services/station_search_service.dart';
import 'package:train_qil/domain/services/notification_pause_service.dart';
import 'package:train_qil/domain/services/theme_service.dart';
import 'package:train_qil/domain/services/notification_service.dart';
import 'package:train_qil/domain/services/favorite_station_service.dart';
import 'package:train_qil/domain/services/trip_reminder_service.dart';
import 'package:train_qil/domain/services/clock_service.dart';
import 'package:train_qil/infrastructure/gateways/local_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/infrastructure/gateways/sncf_search_gateway.dart';
import 'package:train_qil/infrastructure/gateways/notification_pause_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/favorite_station_storage_gateway.dart';
import 'package:train_qil/infrastructure/gateways/mocks/mock_trip_storage.dart';
import 'package:train_qil/infrastructure/gateways/mocks/mock_train_gateway.dart';
import 'package:train_qil/infrastructure/gateways/mocks/mock_station_search_gateway.dart';
import 'package:train_qil/infrastructure/gateways/mocks/mock_station_history_gateway.dart';
import 'package:train_qil/infrastructure/gateways/mocks/mock_favorite_station_storage.dart';
import 'package:train_qil/infrastructure/mappers/trip_mapper.dart';
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/env_config.dart';

/// Classe de gestion de l'injection de dépendances
class DependencyInjection {
  static final DependencyInjection _instance = DependencyInjection._internal();
  factory DependencyInjection() => _instance;
  DependencyInjection._internal();

  static DependencyInjection get instance => _instance;

  static ClockService? _staticClockService;

  static ClockService get _getClockServiceInstance {
    const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
    _staticClockService ??=
        useMockData ? MockClockService(DateTime(2025, 1, 6, 7)) : SystemClockService();
    return _staticClockService!;
  }

  // Services
  ClockService get clockService => _getClockServiceInstance;

  late final TripService tripService;
  late final TrainService trainService;
  late final StationSearchService stationSearchService;
  late final NotificationPauseService notificationPauseService;
  late final ThemeService themeService;
  late final NotificationService notificationService;
  late final FavoriteStationService favoriteStationService;
  late final TripReminderService tripReminderService;

  // Gateways (utiliser les interfaces pour permettre le mocking)
  late final LocalStorageGateway localStorageGateway;
  late final TrainGateway trainGateway;
  late final StationSearchGateway stationSearchGateway;
  late final NotificationPauseStorage notificationPauseStorageGateway;
  late final FavoriteStationStorage favoriteStationStorageGateway;

  // Gateways concrètes (pour compatibilité si besoin)
  SncfGateway? _sncfGateway;
  SncfSearchGateway? _sncfSearchGateway;

  SncfGateway? get sncfGateway => _sncfGateway;
  SncfSearchGateway? get sncfSearchGateway => _sncfSearchGateway;

  // Mappers
  late final TripMapper tripMapper;
  late final SncfMapper sncfMapper;

  // HTTP Client
  late final http.Client httpClient;

  static Future<void> initialize() async {
    final instance = DependencyInjection.instance;
    const useMockData = bool.fromEnvironment('USE_MOCK_DATA');

    // Toujours réinitialiser _staticClockService pour garantir la bonne valeur
    final mockNow = DateTime(2025, 1, 6, 7);
    _staticClockService = useMockData ? MockClockService(mockNow) : SystemClockService();

    instance.tripMapper = TripMapper();
    instance.sncfMapper = SncfMapper();

    if (!useMockData) {
      instance.httpClient = http.Client();
    }

    if (useMockData) {
      instance.localStorageGateway = LocalStorageGateway(
        mapper: instance.tripMapper,
      );
      final mockTripStorage = MockTripStorage();
      instance.tripService = TripService(mockTripStorage);

      // Utiliser les mocks pour les interfaces
      final mockTrainGateway = MockTrainGateway();
      instance.trainGateway = mockTrainGateway;
      instance.trainService = TrainService(instance.trainGateway);

      // Exposer aussi le mock comme sncfGateway pour compatibilité
      // (les méthodes supplémentaires sont disponibles directement sur MockTrainGateway)
      instance._sncfGateway = null; // null en mode mock car MockTrainGateway != SncfGateway

      instance.stationSearchGateway = MockStationSearchGateway();
      final mockHistoryGateway = MockStationHistoryGateway();
      instance.stationSearchService = StationSearchService(
        searchGateway: instance.stationSearchGateway,
        historyGateway: mockHistoryGateway,
      );

      instance.favoriteStationStorageGateway = MockFavoriteStationStorage();
    } else {
      instance.localStorageGateway = LocalStorageGateway(mapper: instance.tripMapper);
      instance._sncfGateway = SncfGateway(
        httpClient: instance.httpClient,
        apiKey: EnvConfig.apiKey ?? 'default-key',
        mapper: instance.sncfMapper,
      );
      instance._sncfSearchGateway = SncfSearchGateway(
        httpClient: instance.httpClient,
        apiKey: EnvConfig.apiKey ?? 'default-key',
        mapper: instance.sncfMapper,
      );

      // Utiliser les interfaces
      instance.trainGateway = instance._sncfGateway!;
      instance.stationSearchGateway = instance._sncfSearchGateway!;

      instance.tripService = TripService(instance.localStorageGateway);
      instance.trainService = TrainService(instance.trainGateway);
      instance.stationSearchService = StationSearchService(
        searchGateway: instance.stationSearchGateway,
      );

      instance.favoriteStationStorageGateway = FavoriteStationStorageGateway();
    }

    // Gateways qui restent les mêmes (pas de mocks pour l'instant)
    instance.notificationPauseStorageGateway = NotificationPauseStorageGateway();
    instance.notificationPauseService =
        NotificationPauseService(storage: instance.notificationPauseStorageGateway);
    instance.favoriteStationService =
        FavoriteStationService(instance.favoriteStationStorageGateway);
    instance.themeService = ThemeService();
    instance.notificationService = NotificationService();
    instance.tripReminderService = TripReminderService(
      tripService: instance.tripService,
      clockService: instance.clockService,
    );

    // Initialisation des services
    await instance.themeService.initialize();
    await instance.notificationService.initialize();
    await instance.tripReminderService.refreshSchedules();
  }
}
