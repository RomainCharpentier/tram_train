import 'package:flutter/material.dart';
import '../../domain/models/notification_pause.dart';
import '../../dependency_injection.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class NotificationPausePage extends StatefulWidget {
  const NotificationPausePage({super.key});

  @override
  State<NotificationPausePage> createState() => _NotificationPausePageState();
}

class _NotificationPausePageState extends State<NotificationPausePage> {
  List<NotificationPause> _pauses = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPauses();
  }

  Future<void> _loadPauses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pauses = await DependencyInjection.instance.notificationPauseService.getAllNotificationPauses();
      setState(() {
        _pauses = pauses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createPause() async {
    final result = await showDialog<NotificationPause?>(
      context: context,
      builder: (context) => _CreatePauseDialog(),
    );

    if (result != null) {
      try {
        await DependencyInjection.instance.notificationPauseService.createNotificationPause(
          name: result.name,
          startDate: result.startDate,
          endDate: result.endDate,
          description: result.description,
        );
        _loadPauses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pause créée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deletePause(NotificationPause pause) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la pause'),
        content: Text('Êtes-vous sûr de vouloir supprimer la pause "${pause.name}" ?'),
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
        await DependencyInjection.instance.notificationPauseService.deleteNotificationPause(pause.id);
        _loadPauses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pause supprimée')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pauses de Notifications'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPause,
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
        onRetry: _loadPauses,
      );
    }

    if (_pauses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune pause configurée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur + pour créer une pause',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pauses.length,
      itemBuilder: (context, index) {
        final pause = _pauses[index];
        return _buildPauseCard(pause);
      },
    );
  }

  Widget _buildPauseCard(NotificationPause pause) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pause.isActive ? Colors.orange : Colors.grey,
          child: Icon(
            pause.isActive ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
        title: Text(pause.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pause.description != null) ...[
              Text(pause.description!),
              const SizedBox(height: 4),
            ],
            Text(
              '${_formatDate(pause.startDate)} - ${_formatDate(pause.endDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Durée: ${pause.durationInDays} jour(s)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (pause.isActive)
              const Text(
                '🔴 ACTIVE - Notifications en pause',
                style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deletePause(pause),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreatePauseDialog extends StatefulWidget {
  @override
  State<_CreatePauseDialog> createState() => _CreatePauseDialogState();
}

class _CreatePauseDialogState extends State<_CreatePauseDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une pause de notifications'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la pause',
                border: OutlineInputBorder(),
                hintText: 'Ex: Vacances d\'été, Week-end, etc.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ex: Pause pendant les vacances...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Début'),
                    subtitle: Text(_formatDate(_startDate)),
                    onTap: _selectStartDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_formatDate(_endDate)),
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pendant cette période, toutes les notifications seront désactivées.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
          onPressed: _createPause,
          child: const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _createPause() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un nom')),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être après la date de début')),
      );
      return;
    }

    final pause = NotificationPause(
      id: NotificationPause.generateId(),
      name: _nameController.text,
      startDate: _startDate,
      endDate: _endDate,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(pause);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
