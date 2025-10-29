import 'package:flutter/material.dart';
import '../../domain/models/notification_pause.dart';
import '../../infrastructure/dependency_injection.dart';

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
      final pauses = await DependencyInjection.instance.notificationPauseService
          .getAllPauses();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pauses de notification'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePauseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPauses,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_pauses.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPausesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune pause configurée',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez des pauses pour désactiver temporairement les notifications',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreatePauseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Créer une pause'),
          ),
        ],
      ),
    );
  }

  Widget _buildPausesList() {
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
    final isActive = pause.isActive;
    final isCurrentPause = _isCurrentPause(pause);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentPause
              ? Colors.red
              : (isActive ? Colors.orange : Colors.grey),
          child: Icon(
            isCurrentPause
                ? Icons.pause
                : (isActive ? Icons.schedule : Icons.pause_circle),
            color: Colors.white,
          ),
        ),
        title: Text(
          pause.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pause.description ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(pause.startDate)} - ${_formatDate(pause.endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (isCurrentPause) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PAUSE ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePauseAction(value, pause),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Activer/Désactiver'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentPause(NotificationPause pause) {
    if (!pause.isActive) return false;

    final now = DateTime.now();
    return now.isAfter(pause.startDate) && now.isBefore(pause.endDate);
  }

  void _handlePauseAction(String action, NotificationPause pause) async {
    switch (action) {
      case 'toggle':
        await _togglePause(pause);
        break;
      case 'delete':
        await _deletePause(pause);
        break;
    }
  }

  Future<void> _togglePause(NotificationPause pause) async {
    try {
      final updatedPause = pause.copyWith(isActive: !pause.isActive);
      await DependencyInjection.instance.notificationPauseService
          .updatePause(updatedPause);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                updatedPause.isActive ? 'Pause activée' : 'Pause désactivée'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPauses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePause(NotificationPause pause) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la pause'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer la pause "${pause.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DependencyInjection.instance.notificationPauseService
            .deletePause(pause.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pause supprimée'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPauses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreatePauseDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePauseDialog(
        onPauseCreated: (pause) {
          _loadPauses();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreatePauseDialog extends StatefulWidget {
  final Function(NotificationPause)? onPauseCreated;

  const _CreatePauseDialog({this.onPauseCreated});

  @override
  State<_CreatePauseDialog> createState() => _CreatePauseDialogState();
}

class _CreatePauseDialogState extends State<_CreatePauseDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une pause'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la pause',
                hintText: 'Ex: Vacances d\'été',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Ex: Pause pendant les vacances',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date de début'),
              subtitle: Text(_startDate != null
                  ? _formatDate(_startDate!)
                  : 'Sélectionner'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectStartDate,
            ),
            ListTile(
              title: const Text('Date de fin'),
              subtitle: Text(
                  _endDate != null ? _formatDate(_endDate!) : 'Sélectionner'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pause active'),
              subtitle: const Text('La pause sera activée immédiatement'),
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
          onPressed: () => Navigator.pop(context),
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
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _createPause() async {
    if (_nameController.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final pause = NotificationPause(
        id: NotificationPause.generateId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        isActive: _isActive,
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.notificationPauseService
          .createPause(pause);

      if (mounted) {
        Navigator.pop(context);
        widget.onPauseCreated?.call(pause);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pause créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
