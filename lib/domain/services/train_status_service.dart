import '../models/train.dart';

abstract class TrainStatusService {
  TrainStatus calculateStatus(DateTime departureTime, DateTime baseDepartureTime);
  String formatStatusText(TrainStatus status, int? delayMinutes);
}
