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

  if (trip.days.isEmpty) {
    return baseToday.isBefore(now)
        ? baseToday.add(const Duration(days: 7))
        : baseToday;
  }

  int bestDelta = 8; // > 7 pour initialiser
  for (final d in trip.days) {
    final targetWeekday = d.index + 1; // 1 = Lundi ... 7 = Dimanche
    int delta = (targetWeekday - baseToday.weekday) % 7;
    if (delta == 0 && baseToday.isBefore(now)) {
      delta = 7; // même jour mais heure passée -> semaine suivante
    }
    if (delta < bestDelta) bestDelta = delta;
  }

  return baseToday.add(Duration(days: bestDelta % 7));
}

String formatRefLabel(DateTime dt) {
  const names = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];
  final dayName = names[(dt.weekday - 1).clamp(0, 6)];
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mn = dt.minute.toString().padLeft(2, '0');
  return '$dayName $dd/$mm • $hh:$mn';
}

void main() {
  // Simule: aujourd'hui = Samedi 01/11/2025 20:00
  final simulatedNow = DateTime(2025, 11, 1, 20, 0, 0);

  final from = Station(id: 'SNCF:87590349', name: 'Babinière');
  final to = Station(id: 'SNCF:87481002', name: 'Nantes');

  final trip = Trip(
    id: 'debug',
    departureStation: from,
    arrivalStation: to,
    days: const [DayOfWeek.monday],
    time: const TimeOfDay(hour: 8, minute: 0),
    createdAt: simulatedNow,
  );

  final ref = computeReferenceDateTimeForTrip(trip, simulatedNow);
  print('Ref weekday: ${ref.weekday} (1=Lundi)');
  print('Ref label:  ${formatRefLabel(ref)}');
  // Attendu: Lundi 03/11/2025 • 08:00, weekday=1
}
