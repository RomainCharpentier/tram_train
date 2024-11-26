import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tram_train/env_config.dart';

class TrainList extends StatefulWidget {
  const TrainList({super.key});

  @override
  _TrainListState createState() => _TrainListState();
}

class _TrainListState extends State<TrainList> {
  List<Map<String, dynamic>> _departures = [];
  final String _selectedStopId = 'SNCF:87590349'; // ID de Babinière par défaut

  @override
  void initState() {
    super.initState();
    fetchTrainDepartures(_selectedStopId);
  }

  // Charger les départs depuis l'API
  Future<void> fetchTrainDepartures(String stopId) async {
    String apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stopId/departures';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${EnvConfig.apiKey}'
        }, // Utilisation de EnvConfig
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _departures =
              List<Map<String, dynamic>>.from(data['departures'] ?? []);
        });
      } else {
        print("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur lors de l'appel API : $e");
    }
  }

  // Calculer l'écart en minutes et le statut du train
  Map<String, dynamic> calculateTrainStatus(Map<String, dynamic> stopDateTime) {
    final baseDepartureTime =
        DateTime.parse(stopDateTime['base_departure_date_time']);
    final departureTime = DateTime.parse(stopDateTime['departure_date_time']);
    final difference = departureTime.difference(baseDepartureTime).inMinutes;

    String status;
    if (stopDateTime['data_freshness'] == 'cancelled') {
      status = "Annulé";
    } else if (difference > 0) {
      status = "En retard (+$difference min)";
    } else if (difference < 0) {
      status = "En avance (${difference.abs()} min)";
    } else {
      status = "À l'heure";
    }

    return {
      'status': status,
      'difference': difference,
    };
  }

  // Formater la date au format dd/MM/yyyy hh:mm
  String _formatDate(String dateTime) {
    final parsedDate = DateTime.parse(dateTime);
    return "${parsedDate.day.toString().padLeft(2, '0')}/"
        "${parsedDate.month.toString().padLeft(2, '0')}/"
        "${parsedDate.year} "
        "${parsedDate.hour.toString().padLeft(2, '0')}:"
        "${parsedDate.minute.toString().padLeft(2, '0')}";
  }

  // Construire une ligne de DataTable
  DataRow _buildDataRow(Map<String, dynamic> departure) {
    final stopDateTime = departure['stop_date_time'];
    final direction = departure['display_informations']['direction'];
    final trainTime = stopDateTime['base_departure_date_time'];
    final additionalInfo = stopDateTime['additional_informations'] ?? [];
    final statusInfo = calculateTrainStatus(stopDateTime);

    // Déterminer la couleur de la ligne en fonction du statut
    final rowColor = statusInfo['status'] == "Annulé"
        ? Colors.red[100]
        : direction.contains("Nantes")
            ? Colors.lightBlue[50]
            : Colors.orange[50];

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) => rowColor),
      cells: <DataCell>[
        DataCell(Text(direction.contains("Nantes") ? "Nantes" : "Chapelle")),
        DataCell(Text(_formatDate(trainTime))),
        DataCell(Text(statusInfo['status'])),
        DataCell(Text(
            additionalInfo.isNotEmpty ? additionalInfo.join(", ") : "Aucune")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des trains'),
      ),
      body: _departures.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text(
                      'Direction',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Heure',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Statut',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Infos additionnelles',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _departures
                    .map((departure) => _buildDataRow(departure))
                    .toList(),
              ),
            ),
    );
  }
}
