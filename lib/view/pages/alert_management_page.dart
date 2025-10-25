import 'package:flutter/material.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/station.dart';
import '../../dependency_injection.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class AlertManagementPage extends StatefulWidget {
  const AlertManagementPage({super.key});

  @override
  State<AlertManagementPage> createState() => _AlertManagementPageState();
}

class _AlertManagementPageState extends State<AlertManagementPage> {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await DependencyInjection.instance.alertService.getAllAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createAlert() async {
    final result = await showDialog<Alert?>(
      context: context,
      builder: (context) => _CreateAlertDialog(),
    );

    if (result != null) {
      try {
        await DependencyInjection.instance.alertService.createAlert(
          title: result.title,
          message: result.message,
          type: result.type,
          station: result.station,
          lineId: result.lineId,
          startTime: result.startTime,
          endTime: result.endTime,
          isActive: result.isActive,
        );
        _loadAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte créée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteAlert(Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'alerte "${alert.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DependencyInjection.instance.alertService.deleteAlert(alert.id);
        _loadAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte supprimée')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _toggleAlert(Alert alert) async {
    try {
      await DependencyInjection.instance.alertService.toggleAlert(
        alert.id,
        !alert.isActive,
      );
      _loadAlerts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Alertes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAlert,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return custom.CustomErrorWidget(
        message: _error!,
        onRetry: _loadAlerts,
      );
    }

    if (_alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune alerte configurée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur + pour créer une alerte',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert.isActive ? Colors.green : Colors.grey,
          child: Icon(
            _getAlertIcon(alert.type),
            color: Colors.white,
          ),
        ),
        title: Text(alert.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 4),
            Text(
              'Gare: ${alert.station.name}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${_formatDateTime(alert.startTime)} - ${_formatDateTime(alert.endTime)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.isActive,
              onChanged: (_) => _toggleAlert(alert),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAlert(alert),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.delay:
        return Icons.schedule;
      case AlertType.cancellation:
        return Icons.cancel;
      case AlertType.disruption:
        return Icons.warning;
      case AlertType.scheduleChange:
        return Icons.update;
      case AlertType.maintenance:
        return Icons.build;
      case AlertType.information:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _CreateAlertDialog extends StatefulWidget {
  @override
  State<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<_CreateAlertDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _lineIdController = TextEditingController();
  
  AlertType _selectedType = AlertType.information;
  Station _selectedStation = const Station(
    id: 'SNCF:87590349',
    name: 'Babinière',
    description: 'Gare de Babinière',
  );
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une alerte'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AlertType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: AlertType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lineIdController,
              decoration: const InputDecoration(
                labelText: 'ID de ligne',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Début'),
                    subtitle: Text(_formatDateTime(_startTime)),
                    onTap: _selectStartTime,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_formatDateTime(_endTime)),
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _createAlert,
          child: const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
      );
      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _createAlert() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final alert = Alert(
      id: Alert.generateId(),
      title: _titleController.text,
      message: _messageController.text,
      type: _selectedType,
      station: _selectedStation,
      lineId: _lineIdController.text.isNotEmpty ? _lineIdController.text : 'T1',
      startTime: _startTime,
      endTime: _endTime,
      isActive: _isActive,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(alert);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
