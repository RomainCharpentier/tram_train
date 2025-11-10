import 'package:flutter/material.dart' hide TimeOfDay;
import '../theme/theme_x.dart';
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';
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
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _departureStation = widget.trip.departureStation;
    _arrivalStation = widget.trip.arrivalStation;
    _selectedDays = [widget.trip.day];
    _selectedTime = flutter.TimeOfDay(
      hour: widget.trip.time.hour,
      minute: widget.trip.time.minute,
    );
    _isActive = widget.trip.isActive;
    _notificationsEnabled = widget.trip.notificationsEnabled;
  }

  Widget _buildSaveButton() {
    final canSave = _selectedDays.isNotEmpty;

    return ElevatedButton(
      onPressed: canSave ? _saveTrip : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
          showFavoriteButton: false,
          onStationTap: (station) => Navigator.pop(context, station),
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

      if (!isDeparture) {
        _validateConnection();
      }
    }
  }

  Future<void> _validateConnection() async {
    try {
      await ConnectedStationsService.checkConnection(
        _departureStation,
        _arrivalStation,
        directOnly: false,
      );
    } catch (e) {}
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
      final result = await ConnectedStationsService.checkConnection(
        _departureStation,
        _arrivalStation,
        directOnly: false,
      );

      if (!result.isConnected) {
        if (mounted) {
          _showSnackBar('⚠️ ${result.message}', context.theme.warning);
        }
        return;
      }

      final updatedTrip = widget.trip.copyWith(
        departureStation: _departureStation,
        arrivalStation: _arrivalStation,
        day: _selectedDays.first,
        time: domain.TimeOfDay(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        ),
        isActive: _isActive,
        notificationsEnabled: _notificationsEnabled,
      );

      await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
      await DependencyInjection.instance.tripReminderService.refreshSchedules();

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('✅ Trajet modifié avec succès !',
            Theme.of(context).colorScheme.primary);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la modification : $e',
            Theme.of(context).colorScheme.error);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDepartureStationCard(),
            const SizedBox(height: 8),
            _buildSwapButton(),
            const SizedBox(height: 8),
            _buildArrivalStationCard(),
            const SizedBox(height: 24),
            _buildDaysSection(),
            const SizedBox(height: 24),
            _buildTimeCard(),
            const SizedBox(height: 24),
            _buildActiveSwitch(),
            _buildNotificationsSwitch(),
            const Spacer(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Modifier le trajet'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildDepartureStationCard() {
    return Card(
      child: ListTile(
        leading:
            Icon(Icons.train, color: Theme.of(context).colorScheme.primary),
        title: Text(_departureStation.name),
        subtitle: Text(_departureStation.description ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _selectStation(true),
      ),
    );
  }

  Widget _buildArrivalStationCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.location_on,
            color: Theme.of(context).colorScheme.secondary),
        title: Text(_arrivalStation.name),
        subtitle: Text(_arrivalStation.description ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _selectStation(false),
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: IconButton(
        onPressed: _swapStations,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
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
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.access_time,
            color: Theme.of(context).colorScheme.primary),
        title: Text('Départ à ${_selectedTime.format(context)}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _selectTime,
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return Card(
      child: SwitchListTile(
        title: const Text('Trajet actif'),
        subtitle: const Text('Ce trajet sera affiché sur le tableau de bord'),
        value: _isActive,
        onChanged: (value) => setState(() => _isActive = value),
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationsSwitch() {
    return Card(
      child: SwitchListTile(
        title: const Text('Notifications activées'),
        subtitle: const Text('Recevoir des notifications pour ce trajet'),
        value: _notificationsEnabled,
        onChanged: (value) => setState(() => _notificationsEnabled = value),
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
