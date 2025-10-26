import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';
import 'station_search_page.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  Station? _departureStation;
  Station? _arrivalStation;
  final List<domain.DayOfWeek> _selectedDays = [];
  flutter.TimeOfDay? _selectedTime;
  bool _isActive = true;
  bool _notificationsEnabled = true;
  bool _directTrainsOnly = true; // Nouvelle option pour trajets directs uniquement
  String? _connectionError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un trajet'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Station de départ
            Card(
              color: _connectionError != null 
                  ? (_connectionError!.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.train, 
                  color: _connectionError != null 
                      ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                      : const Color(0xFF4A90E2),
                ),
                title: Text(
                  _departureStation?.name ?? 'Sélectionner la station de départ',
                  style: TextStyle(
                    color: _connectionError != null 
                        ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                        : null
                  ),
                ),
                subtitle: _departureStation != null 
                    ? Text(
                        _departureStation!.description ?? '',
                        style: TextStyle(
                          color: _connectionError != null 
                              ? (_connectionError!.startsWith('✅') ? Colors.green.shade700 : Colors.red.shade700)
                              : null
                        ),
                      )
                    : Text(
                        'Choisissez votre station de départ',
                        style: TextStyle(
                          color: _connectionError != null 
                              ? (_connectionError!.startsWith('✅') ? Colors.green.shade700 : Colors.red.shade700)
                              : null
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null 
                      ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                      : null,
                ),
                onTap: () => _selectStation(true),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Bouton d'inversion des stations
            Center(
              child: IconButton(
                onPressed: _swapStations,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                tooltip: 'Inverser les stations',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Station d'arrivée
            Card(
              color: _connectionError != null 
                  ? (_connectionError!.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.location_on, 
                  color: _connectionError != null 
                      ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                      : (_departureStation != null 
                          ? const Color(0xFF2E5BBA) 
                          : Colors.grey),
                ),
                title: Text(
                  _arrivalStation?.name ?? 'Sélectionner la station d\'arrivée',
                  style: TextStyle(
                    color: _connectionError != null 
                        ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                        : (_departureStation != null ? null : Colors.grey),
                  ),
                ),
                subtitle: _arrivalStation != null 
                    ? Text(
                        _arrivalStation!.description ?? '',
                        style: TextStyle(
                          color: _connectionError != null 
                              ? (_connectionError!.startsWith('✅') ? Colors.green.shade700 : Colors.red.shade700)
                              : null
                        ),
                      )
                    : Text(
                        _departureStation != null 
                            ? 'Choisissez votre station d\'arrivée'
                            : 'Sélectionnez d\'abord la station de départ',
                        style: TextStyle(
                          color: _connectionError != null 
                              ? (_connectionError!.startsWith('✅') ? Colors.green.shade700 : Colors.red.shade700)
                              : (_departureStation != null ? null : Colors.grey),
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null 
                      ? (_connectionError!.startsWith('✅') ? Colors.green : Colors.red)
                      : (_departureStation != null ? null : Colors.grey),
                ),
                onTap: _departureStation != null 
                    ? () => _selectStation(false)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez d\'abord sélectionner la station de départ'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
              ),
            ),
            
            // Message d'erreur/succès de connexion
            if (_connectionError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionError!.startsWith('✅') 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _connectionError!.startsWith('✅') 
                        ? Colors.green.shade200 
                        : Colors.red.shade200
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionError!.startsWith('✅') ? Icons.check_circle : Icons.warning,
                      color: _connectionError!.startsWith('✅') 
                          ? Colors.green.shade600 
                          : Colors.red.shade600
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionError!,
                        style: TextStyle(
                          color: _connectionError!.startsWith('✅') 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
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
                  label: Text(day.displayName),
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
                activeThumbColor: const Color(0xFF4A90E2),
              ),
            ),
            
            Card(
              child: SwitchListTile(
                title: const Text('Notifications activées'),
                subtitle: const Text('Recevoir des notifications pour ce trajet'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeThumbColor: const Color(0xFF4A90E2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Option pour trajets directs uniquement
            Card(
              child: SwitchListTile(
                title: const Text('Trajets directs uniquement'),
                subtitle: const Text('Exclure les trajets avec correspondances'),
                value: _directTrainsOnly,
                onChanged: (value) {
                  setState(() {
                    _directTrainsOnly = value;
                    // Re-valider la connexion si les gares sont déjà sélectionnées
                    if (_departureStation != null && _arrivalStation != null) {
                      _validateConnection();
                    }
                  });
                },
                activeThumbColor: const Color(0xFF4A90E2),
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
      
      // Validation immédiate si on sélectionne une gare d'arrivée
      if (!isDeparture && _departureStation != null) {
        _validateConnection();
      }
    }
  }
  
  /// Valide la connexion entre les gares sélectionnées
  Future<void> _validateConnection() async {
    if (_departureStation == null || _arrivalStation == null) return;
    
    try {
      // Utiliser la nouvelle méthode avec plus d'informations
      final result = await ConnectedStationsService.checkConnection(
        _departureStation!,
        _arrivalStation!,
        directOnly: _directTrainsOnly,
      );

      setState(() {
        if (!result.isConnected) {
          _connectionError = '⚠️ ${result.message}';
        } else {
          _connectionError = '✅ ${result.message}';
        }
      });
    } catch (e) {
      setState(() {
        _connectionError = 'Erreur lors de la validation: $e';
      });
    }
  }

  void _swapStations() {
    setState(() {
      final temp = _departureStation;
      _departureStation = _arrivalStation;
      _arrivalStation = temp;
    });
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
      // Vérifier que les gares sont connectées
      final result = await ConnectedStationsService.checkConnection(
        _departureStation!,
        _arrivalStation!,
        directOnly: _directTrainsOnly,
      );

      if (!result.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ ${result.message}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return; // Bloquer la sauvegarde
      }

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
        notificationsEnabled: _notificationsEnabled,
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.tripService.saveTrip(trip);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trajet enregistré avec succès !'),
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