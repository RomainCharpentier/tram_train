import 'package:flutter/material.dart';
import '../../domain/models/trip.dart';
import '../../dependency_injection.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class TripManagementPage extends StatefulWidget {
  const TripManagementPage({super.key});

  @override
  State<TripManagementPage> createState() => _TripManagementPageState();
}

class _TripManagementPageState extends State<TripManagementPage> {
  final List<String> _daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedDay;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trips = await DependencyInjection.instance.tripService.getAllTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trajets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des trajets'),
      ),
      body: Column(
        children: [
          _buildTripForm(),
          const Divider(),
          Expanded(child: _buildTripsList()),
        ],
      ),
    );
  }

  Widget _buildTripForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter un trajet récurrent',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            hint: const Text('Sélectionner un jour'),
            value: _selectedDay,
            isExpanded: true,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectTime,
            child: Text(_selectedTime == null
                ? 'Sélectionner une heure'
                : 'Heure: ${_selectedTime!.format(context)}'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreateTrip() ? _createTrip : null,
              child: const Text('Enregistrer le trajet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return custom.CustomErrorWidget(
        message: _error!,
        onRetry: _loadTrips,
      );
    }

    if (_trips.isEmpty) {
      return const Center(
        child: Text('Aucun trajet enregistré'),
      );
    }

    return ListView.builder(
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return ListTile(
          leading: const Icon(Icons.route),
          title: Text('${trip.station.name} - ${trip.dayOfWeek}'),
          subtitle: Text('À ${trip.time}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTrip(trip.id),
          ),
        );
      },
    );
  }

  void _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  bool _canCreateTrip() {
    return _selectedDay != null && _selectedTime != null;
  }

  Future<void> _createTrip() async {
    if (_selectedDay != null && _selectedTime != null) {
      try {
        await DependencyInjection.instance.tripService.createTrip(
          station: DependencyInjection.babiniereStation,
          dayOfWeek: _selectedDay!,
          time: _selectedTime!.format(context),
        );
        
        // Reset form and reload trips
        setState(() {
          _selectedDay = null;
          _selectedTime = null;
        });
        _loadTrips();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    }
  }

  void _deleteTrip(String tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce trajet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DependencyInjection.instance.tripService.deleteTrip(tripId);
                _loadTrips();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la suppression: $e')),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
