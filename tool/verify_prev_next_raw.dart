// ignore_for_file: avoid_print
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/domain/models/station.dart';

Future<void> main() async {
  final apiKey =
      Platform.environment['API_KEY'] ?? '61032076-d074-439e-8526-5c39a541479f';
  final httpClient = http.Client();
  final mapper = SncfMapper();
  final gw =
      SncfGateway(httpClient: httpClient, apiKey: apiKey, mapper: mapper);

  const from = Station(id: 'SNCF:87590349', name: 'Babinière');
  const to = Station(id: 'SNCF:87481002', name: 'Nantes');
  final target = DateTime(2025, 11, 3, 8);

  print('📅 Cible: $target');
  try {
    final raw =
        await gw.getJourneysRaw(from, to, target, represents: 'departure');
    final links = (raw['links'] as List? ?? []).cast<Map<String, dynamic>>();
    final prev = links.firstWhere((l) => l['rel'] == 'prev', orElse: () => {});
    final next = links.firstWhere((l) => l['rel'] == 'next', orElse: () => {});
    print('🔗 prev.href = ${prev['href']}');
    print('🔗 next.href = ${next['href']}');

    if (prev['href'] is String) {
      final trains =
          await gw.getJourneysByHref(prev['href'] as String, from, to);
      trains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      final before =
          trains.where((t) => t.departureTime.isBefore(target)).toList();
      print('⬅️ prev page before count = ${before.length}');
      if (before.isNotEmpty) {
        print('   last before = ${before.last.departureTime}');
      }
    }

    if (next['href'] is String) {
      final trains =
          await gw.getJourneysByHref(next['href'] as String, from, to);
      trains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      final after =
          trains.where((t) => !t.departureTime.isBefore(target)).toList();
      print('➡️ next page after count = ${after.length}');
      if (after.isNotEmpty) {
        print('   first after = ${after.first.departureTime}');
      }
    }
  } on Object catch (e) {
    print('❌ erreur: $e');
  } finally {
    httpClient.close();
  }
}
