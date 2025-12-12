import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/domain/models/station.dart';
import 'package:train_qil/domain/services/train_service.dart';

Future<void> main() async {
  final apiKey = Platform.environment['API_KEY'] ?? '61032076-d074-439e-8526-5c39a541479f';
  final httpClient = http.Client();
  final mapper = SncfMapper();
  final gw = SncfGateway(httpClient: httpClient, apiKey: apiKey, mapper: mapper);

  final trainService = TrainService(gw);

  const from = Station(id: 'SNCF:87590349', name: 'Babinière');
  const to = Station(id: 'SNCF:87481002', name: 'Nantes');
  final target = DateTime(2025, 11, 3, 8);

  print('📅 Cible: $target');

  try {
    final initial = await gw.findJourneysWithDepartureTime(from, to, target);
    print('📦 initial.count = ${initial.length}');
    if (initial.isNotEmpty) {
      print('   first.dep = ${initial.first.departureTime}');
    }

    final before = await trainService.findJourneyJustBefore(from, to, target);
    final after = await trainService.findJourneyJustAfter(from, to, target);

    print('⬅️ before = ${before?.departureTime}');
    print('➡️ after  = ${after?.departureTime}');
  } catch (e) {
    print('❌ erreur: $e');
  } finally {
    httpClient.close();
  }
}
