// ignore_for_file: avoid_print
import 'package:train_qil/domain/models/trip.dart';
import 'package:train_qil/domain/models/station.dart';

DateTime computeReferenceDateTimeForTrip(Trip trip, DateTime now) {
  final baseToday = DateTime(
    now.year,
    now.month,
    now.day,
    trip.time.hour,
    trip.time.minute,
  );

  final targetWeekday = trip.day.index + 1;
  int delta = (targetWeekday - baseToday.weekday) % 7;
  if (delta == 0 && baseToday.isBefore(now)) {
    delta = 7;
  }

  return baseToday.add(Duration(days: delta % 7));
}

String formatRefLabel(DateTime dt) {
  const names = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final dayName = names[(dt.weekday - 1).clamp(0, 6)];
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mn = dt.minute.toString().padLeft(2, '0');
  return '$dayName $dd/$mm • $hh:$mn';
}

void main() {
  // Simule: aujourd'hui = Samedi 01/11/2025 20:00
  final simulatedNow = DateTime(2025, 11, 1, 20);

  const from = Station(id: 'SNCF:87590349', name: 'Babinière');
  const to = Station(id: 'SNCF:87481002', name: 'Nantes');

  final trip = Trip(
    id: 'debug',
    departureStation: from,
    arrivalStation: to,
    day: DayOfWeek.monday,
    time: const TimeOfDay(hour: 8, minute: 0),
    createdAt: simulatedNow,
  );

  final ref = computeReferenceDateTimeForTrip(trip, simulatedNow);
  print('Ref weekday: ${ref.weekday} (1=Lundi)');
  print('Ref label:  ${formatRefLabel(ref)}');
  // Attendu: Lundi 03/11/2025 • 08:00, weekday=1
}
