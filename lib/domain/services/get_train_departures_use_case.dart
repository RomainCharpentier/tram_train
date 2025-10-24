import '../models/train.dart';
import '../models/station.dart';
import '../providers/train_repository.dart';

class GetTrainDeparturesUseCase {
  final TrainRepository _trainRepository;

  const GetTrainDeparturesUseCase(this._trainRepository);

  Future<List<Train>> execute(Station station) async {
    try {
      return await _trainRepository.getDepartures(station);
    } catch (e) {
      throw GetTrainDeparturesException('Erreur lors de la récupération des départs: $e');
    }
  }

  Future<List<Train>> executeAt(Station station, DateTime dateTime) async {
    try {
      return await _trainRepository.getDeparturesAt(station, dateTime);
    } catch (e) {
      throw GetTrainDeparturesException('Erreur lors de la récupération des départs: $e');
    }
  }
}

class GetTrainDeparturesException implements Exception {
  final String message;
  const GetTrainDeparturesException(this.message);
  
  @override
  String toString() => 'GetTrainDeparturesException: $message';
}
