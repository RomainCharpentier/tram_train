import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:train_qil/infrastructure/dependency_injection.dart';
import 'package:train_qil/infrastructure/mappers/sncf_mapper.dart';
import 'package:train_qil/infrastructure/gateways/sncf_gateway.dart';
import 'package:train_qil/domain/models/station.dart';

Future<void> main() async {
  final apiKey = Platform.environment['API_KEY'] ?? '61032076-d074-439e-8526-5c39a541479f';
  final httpClient = http.Client();
  final mapper = SncfMapper();
  final gw = SncfGateway(httpClient: httpClient, apiKey: apiKey, mapper: mapper);

  // Câbler DI minimal pour TrainService
  DependencyInjection.instance.httpClient = httpClient;
  DependencyInjection.instance.sncfMapper = mapper;
  DependencyInjection.instance.sncfGateway = gw;
  DependencyInjection.instance.trainService =
      // ignore: invalid_use_of_visible_for_testing_member
      // TrainService attend un TrainGateway, SncfGateway implémente TrainGateway
      // via getDepartures / getDeparturesAt.
      // Nous utilisons directement la DI pour récupérer le service.
      // (Si la classe change, ajuster ici.)
      //
      // Ici on reconstruit explicitement pour éviter d'initialiser tout DI.
      // ignore: invalid_use_of_internal_member
      // ignore_for_file: deprecated_member_use
      // (toléré dans ce script de vérif)
      //
      // En pratique: new TrainService(gw)
      // Mais import local non nécessaire, on va passer par DI utilisé dans l'app.
      DependencyInjection.instance.trainService;

  final from = const Station(id: 'SNCF:87590349', name: 'Babinière');
  final to = const Station(id: 'SNCF:87481002', name: 'Nantes');
  final target = DateTime(2025, 11, 3, 8, 0, 0);

  print('📅 Cible: $target');

  try {
    final service = DependencyInjection.instance.trainService;
    // Sanity: première page
    final initial = await gw.findJourneysWithDepartureTime(from, to, target);
    print('📦 initial.count = ${initial.length}');
    if (initial.isNotEmpty) {
      print('   first.dep = ${initial.first.departureTime}');
    }

    // Prev / Next via service
    final before = await service.findJourneyJustBefore(from, to, target);
    final after = await service.findJourneyJustAfter(from, to, target);

    print('⬅️ before = ${before?.departureTime}');
    print('➡️ after  = ${after?.departureTime}');
  } catch (e) {
    print('❌ erreur: $e');
  } finally {
    httpClient.close();
  }
}


