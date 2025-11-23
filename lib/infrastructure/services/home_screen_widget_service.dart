import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/train.dart';

class HomeScreenWidgetService {
  static const String _androidWidgetName = 'TripWidgetProvider';

  Future<void> updateWidget(Trip trip, Train? nextTrain) async {
    try {
      await HomeWidget.saveWidgetData<String>('title', 'Prochain départ');
      await HomeWidget.saveWidgetData<String>('description', trip.description);

      if (nextTrain != null) {
        final timeStr = DateFormat('HH:mm').format(nextTrain.departureTime);
        await HomeWidget.saveWidgetData<String>('time', timeStr);
        
        String statusText = 'À l\'heure';
        switch (nextTrain.status) {
          case TrainStatus.delayed:
            final delay = nextTrain.delayMinutes ?? 0;
            statusText = 'Retard ${delay}m';
            break;
          case TrainStatus.cancelled:
            statusText = 'Supprimé';
            break;
          case TrainStatus.early:
             final advance = nextTrain.delayMinutes ?? 0;
             statusText = 'Avance ${advance}m';
             break;
          case TrainStatus.onTime:
            statusText = 'À l\'heure';
            break;
          case TrainStatus.unknown:
            statusText = 'Inconnu';
            break;
        }
        await HomeWidget.saveWidgetData<String>('status', statusText);
      } else {
        await HomeWidget.saveWidgetData<String>('time', '--:--');
        await HomeWidget.saveWidgetData<String>('status', 'Aucun train');
      }

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Ignore errors on unsupported platforms or if widget not present
      debugPrint('Error updating widget: $e');
    }
  }
}
