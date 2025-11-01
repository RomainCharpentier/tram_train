import 'dart:convert';

import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/domain/models/station.dart';

void main() {
  final mapper = SncfMapper();
  final from = const Station(id: 'SNCF:87590349', name: 'Babinière');
  final to = const Station(id: 'SNCF:87481002', name: 'Nantes');

  // JSON minimal qui ressemble à la réponse SNCF avec un départ lundi 2025-11-03 08:14:00
  final raw = {
    'journeys': [
      {
        'id': 'test-journey-1',
        'sections': [
          {
            'from': {
              'departure_date_time': '20251103T081400',
              'name': from.name,
            },
            'display_informations': {
              'physical_mode': 'Tramway',
              'commercial_mode': 'Aléop',
            },
          },
          {
            'to': {
              'arrival_date_time': '20251103T082900',
              'name': to.name,
            },
          }
        ]
      }
    ]
  };

  final trains = mapper.mapJourneysToTrains(
    json.decode(json.encode(raw)) as Map<String, dynamic>,
    from,
    to,
  );

  for (final t in trains) {
    final dt = t.departureTime;
    print('Parsed departure: ${dt.toIso8601String()} (weekday=${dt.weekday})');
  }

  if (trains.isEmpty || trains.first.departureTime.weekday != DateTime.monday) {
    throw StateError('Expected Monday for parsed journey datetime');
  }
  print('OK: mapper preserves Monday for journey datetime.');
}


