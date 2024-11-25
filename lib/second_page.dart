import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tram_train/env_config.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  List<Map<String, dynamic>> _savedTrips = [];
  final String _selectedStopId = 'SNCF:87590349'; // ID de Babinière par défaut
  String? _selectedTrain;

  // Liste des jours de la semaine
  final List<String> _daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];
  String? _selectedDay;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    loadSavedTrips();
  }

  // Charger les trajets enregistrés depuis le stockage local
  Future<void> loadSavedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final trips = prefs.getStringList('savedTrips') ?? [];

    setState(() {
      _savedTrips = trips
          .map((trip) => json.decode(trip) as Map<String, dynamic>)
          .toList();
    });
  }

  // Sauvegarder un trajet dans le stockage local
  Future<void> saveTrip(String stopId, String day, String time) async {
    final prefs = await SharedPreferences.getInstance();
    final trip = {'stopId': stopId, 'day': day, 'time': time};
    _savedTrips.add(trip);

    // Convertir la liste de trajets en JSON
    final tripsJson = _savedTrips.map((trip) => json.encode(trip)).toList();
    await prefs.setStringList('savedTrips', tripsJson);

    setState(() {
      _savedTrips = _savedTrips;
    });
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy à HH:mm:ss').format(dateTime);
  }

  String formatDateFromString(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return formatDate(dateTime);
  }

  // Vérifier les horaires pour le trajet sauvegardé
  Future<void> checkTrainStatus(String stopId, String dateTime) async {
    String apiUrl =
        'https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area:$stopId/departures?datetime=$dateTime';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Basic ${EnvConfig.apiKey}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final departures = data['departures'] ?? [];

        // Afficher les informations du train sélectionné
        if (departures.isNotEmpty) {
          final trainInfo = departures.first['display_informations'] ?? {};
          final trainTime =
              departures.first['stop_date_time']['base_departure_date_time'];
          final trainStatus = trainInfo['headsign'] ?? 'Train inconnu';

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Train du ${formatDateFromString(dateTime)}'),
                content: Text(
                    'Train: $trainStatus à ${formatDateFromString(trainTime)}'),
                actions: <Widget>[
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Erreur lors de l'appel API : $e");
    }
  }

  // Affichage du formulaire pour ajouter un trajet récurrent
  void _addTrip() async {
    if (_selectedDay != null && _selectedTime != null) {
      final formattedTime = _selectedTime!.format(context);
      await saveTrip(_selectedStopId, _selectedDay!, formattedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer un Trajet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown pour sélectionner un jour
            DropdownButton<String>(
              hint: const Text("Sélectionner un jour"),
              value: _selectedDay,
              items: _daysOfWeek.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDay = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            // Bouton pour sélectionner une heure
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                  });
                }
              },
              child: Text(_selectedTime == null
                  ? "Sélectionner une heure"
                  : "Heure sélectionnée: ${_selectedTime!.format(context)}"),
            ),
            const SizedBox(height: 20),
            // Bouton pour enregistrer le trajet
            ElevatedButton(
              onPressed: _addTrip,
              child: const Text('Enregistrer le trajet'),
            ),
            const SizedBox(height: 20),
            // Affichage des trajets enregistrés
            Expanded(
              child: ListView.builder(
                itemCount: _savedTrips.length,
                itemBuilder: (context, index) {
                  final trip = _savedTrips[index];
                  final stopName = trip['stopId'] == 'SNCF:87590349'
                      ? 'Babinière'
                      : 'Nantes';
                  return ListTile(
                    title: Text('$stopName - ${trip['day']} à ${trip['time']}'),
                    onTap: () {
                      // Formatter la date et l'heure pour demain (prochain train)
                      final now = DateTime.now();
                      final nextTrainDate = now.add(const Duration(days: 7));
                      final formattedDate = DateFormat("yyyyMMdd'T'HHmmss")
                          .format(DateTime(
                              nextTrainDate.year,
                              nextTrainDate.month,
                              nextTrainDate.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute));
                      checkTrainStatus(
                          trip['stopId'], formattedDate); // Vérifier le train
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
