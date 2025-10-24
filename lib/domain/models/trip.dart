import 'station.dart';

class Trip {
  final String id;
  final Station station;
  final String dayOfWeek;
  final String time;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.station,
    required this.dayOfWeek,
    required this.time,
    required this.createdAt,
  });

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool isForToday() {
    final today = DateTime.now().weekday;
    final dayMap = {
      1: 'Lundi',
      2: 'Mardi', 
      3: 'Mercredi',
      4: 'Jeudi',
      5: 'Vendredi',
      6: 'Samedi',
      7: 'Dimanche',
    };
    return dayMap[today] == dayOfWeek;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Trip(id: $id, station: ${station.name}, day: $dayOfWeek, time: $time)';
}
