import 'package:http/http.dart' as http;
import 'domain/models/station.dart';
import 'domain/providers/train_repository.dart';
import 'domain/providers/trip_repository.dart';
import 'infrastructure/data_sources/sncf_train_repository.dart';
import 'infrastructure/data_sources/local_trip_repository.dart';
import 'domain/services/get_train_departures_use_case.dart';
import 'domain/services/manage_trip_use_case.dart';
import 'domain/services/train_list_controller.dart';
import 'domain/services/trip_controller.dart';
import 'env_config.dart';

class DependencyInjection {
  static late final DependencyInjection _instance;
  static DependencyInjection get instance => _instance;

  late final TrainRepository _trainRepository;
  late final TripRepository _tripRepository;
  late final GetTrainDeparturesUseCase _getTrainDeparturesUseCase;
  late final ManageTripUseCase _manageTripUseCase;

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
    _trainRepository = SncfTrainRepository(
      httpClient: http.Client(),
      apiKey: EnvConfig.apiKey ?? '',
    );

    _tripRepository = LocalTripRepository();

    _getTrainDeparturesUseCase = GetTrainDeparturesUseCase(_trainRepository);
    _manageTripUseCase = ManageTripUseCase(_tripRepository);
  }

  TrainListController createTrainListController() {
    return TrainListController(_getTrainDeparturesUseCase);
  }

  TripController createTripController() {
    return TripController(_manageTripUseCase);
  }

  GetTrainDeparturesUseCase get getTrainDeparturesUseCase => _getTrainDeparturesUseCase;
  ManageTripUseCase get manageTripUseCase => _manageTripUseCase;
}
