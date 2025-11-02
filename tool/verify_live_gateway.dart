import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/domain/models/station.dart';

Future<void> main() async {
  // Clé API: prend API_KEY des variables d'env ou valeur connue de dev
  final apiKey =
      Platform.environment['API_KEY'] ?? '61032076-d074-439e-8526-5c39a541479f';

  final httpClient = http.Client();
  final mapper = SncfMapper();
  final gateway =
      SncfGateway(httpClient: httpClient, apiKey: apiKey, mapper: mapper);

  final from = const Station(id: 'SNCF:87590349', name: 'Babinière');
  final to = const Station(id: 'SNCF:87481002', name: 'Nantes');
  final requested = DateTime(2025, 11, 3, 8, 0, 0); // Lundi 03/11/2025 08:00

  print('🔐 API key starts with: ${apiKey.substring(0, 6)}…');
  print(
      '📅 Requested local datetime: $requested (weekday=${requested.weekday})');

  try {
    final trains =
        await gateway.findJourneysWithDepartureTime(from, to, requested);
    if (trains.isEmpty) {
      print('❌ Aucun trajet retourné');
      return;
    }

    final first = trains.first;
    final dep = first.departureTime;
    print('✅ First journey parsed');
    print('   departure: $dep (weekday=${dep.weekday})');
    print('   direction: ${first.direction}');

    final preview = trains
        .take(5)
        .map((t) =>
            '${t.departureTime.toIso8601String()} (wd=${t.departureTime.weekday})')
        .join('\n');
    print('   next times (up to 5):\n$preview');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    httpClient.close();
  }
}
