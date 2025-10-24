import 'package:flutter/material.dart';
import '../../domain/services/trip_controller.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;
import '../../dependency_injection.dart';

class TripManagementPage extends StatefulWidget {
  final TripController controller;

  const TripManagementPage({
    super.key,
    required this.controller,
  });

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

  String? _selectedDay;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    widget.controller.loadTrips();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
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
    if (widget.controller.isLoading) {
      return const LoadingWidget();
    }

    if (widget.controller.error != null) {
      return custom.CustomErrorWidget(
        message: widget.controller.error!,
        onRetry: widget.controller.loadTrips,
      );
    }

    if (widget.controller.trips.isEmpty) {
      return const Center(
        child: Text('Aucun trajet enregistré'),
      );
    }

    return ListView.builder(
      itemCount: widget.controller.trips.length,
      itemBuilder: (context, index) {
        final trip = widget.controller.trips[index];
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

  void _createTrip() {
    if (_selectedDay != null && _selectedTime != null) {
      widget.controller.createTrip(
        station: DependencyInjection.babiniereStation,
        dayOfWeek: _selectedDay!,
        time: _selectedTime!.format(context),
      );
      
      // Reset form
      setState(() {
        _selectedDay = null;
        _selectedTime = null;
      });
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
            onPressed: () {
              Navigator.pop(context);
              widget.controller.deleteTrip(tripId);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
