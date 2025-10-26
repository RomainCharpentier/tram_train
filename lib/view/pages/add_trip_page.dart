import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../dependency_injection.dart';
import 'station_search_page.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  Station? _departureStation;
  Station? _arrivalStation;
  List<domain.DayOfWeek> _selectedDays = [];
  flutter.TimeOfDay? _selectedTime;
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un trajet'),
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
                title: Text(_departureStation?.name ?? 'Sélectionner la station de départ'),
                subtitle: _departureStation != null 
                    ? Text(_departureStation!.description ?? '')
                    : const Text('Choisissez votre station de départ'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectStation(true),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Station d'arrivée
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF2E5BBA)),
                title: Text(_arrivalStation?.name ?? 'Sélectionner la station d\'arrivée'),
                subtitle: _arrivalStation != null 
                    ? Text(_arrivalStation!.description ?? '')
                    : const Text('Choisissez votre station d\'arrivée'),
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
                title: Text(_selectedTime != null 
                    ? 'Départ à ${_selectedTime!.format(context)}'
                    : 'Sélectionner l\'heure de départ'),
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
    final canSave = _departureStation != null && 
                   _arrivalStation != null && 
                   _selectedDays.isNotEmpty && 
                   _selectedTime != null;
    
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
        'Enregistrer le trajet',
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
      initialTime: _selectedTime ?? const flutter.TimeOfDay(hour: 8, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (_departureStation == null || _arrivalStation == null || _selectedTime == null) {
      return;
    }

    try {
      final trip = domain.Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        departureStation: _departureStation!,
        arrivalStation: _arrivalStation!,
        days: _selectedDays,
        time: domain.TimeOfDay(
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
        ),
        isActive: _isActive,
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.tripService.saveTrip(trip);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trajet enregistré avec succès !'),
            backgroundColor: Color(0xFF4A90E2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}