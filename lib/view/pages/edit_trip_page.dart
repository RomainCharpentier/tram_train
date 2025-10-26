import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../dependency_injection.dart';
import 'station_search_page.dart';

class EditTripPage extends StatefulWidget {
  final domain.Trip trip;
  
  const EditTripPage({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  late Station _departureStation;
  late Station _arrivalStation;
  late List<domain.DayOfWeek> _selectedDays;
  late flutter.TimeOfDay _selectedTime;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _departureStation = widget.trip.departureStation;
    _arrivalStation = widget.trip.arrivalStation;
    _selectedDays = List.from(widget.trip.days);
    _selectedTime = flutter.TimeOfDay(
      hour: widget.trip.time.hour,
      minute: widget.trip.time.minute,
    );
    _isActive = widget.trip.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le trajet'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Station de départ
            Card(
              child: ListTile(
                leading: const Icon(Icons.train, color: Color(0xFF4A90E2)),
                title: Text(_departureStation.name),
                subtitle: Text(_departureStation.description ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectStation(true),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Station d'arrivée
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF2E5BBA)),
                title: Text(_arrivalStation.name),
                subtitle: Text(_arrivalStation.description ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectStation(false),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Jours de la semaine
            const Text(
              'Jours de la semaine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: domain.DayOfWeek.values.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF4A90E2),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Heure de départ
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Color(0xFF4A90E2)),
                title: Text('Départ à ${_selectedTime.format(context)}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectTime,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statut actif
            Card(
              child: SwitchListTile(
                title: const Text('Trajet actif'),
                subtitle: const Text('Ce trajet sera affiché sur le tableau de bord'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: const Color(0xFF4A90E2),
              ),
            ),
            
            const Spacer(),
            
            // Bouton de sauvegarde
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _selectedDays.isNotEmpty;
    
    return ElevatedButton(
      onPressed: canSave ? _saveTrip : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Enregistrer les modifications',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _selectStation(bool isDeparture) async {
    final result = await Navigator.push<Station>(
      context,
      MaterialPageRoute(
        builder: (context) => StationSearchPage(
          departureStation: isDeparture ? null : _departureStation,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        if (isDeparture) {
          _departureStation = result;
        } else {
          _arrivalStation = result;
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveTrip() async {
    try {
      final updatedTrip = widget.trip.copyWith(
        departureStation: _departureStation,
        arrivalStation: _arrivalStation,
        days: _selectedDays,
        time: domain.TimeOfDay(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        ),
        isActive: _isActive,
      );

      await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trajet modifié avec succès !'),
            backgroundColor: Color(0xFF4A90E2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}