import '../models/train.dart';
import '../models/station.dart';

abstract class TrainRepository {
  Future<List<Train>> getDepartures(Station station);
  Future<List<Train>> getDeparturesAt(Station station, DateTime dateTime);
}
