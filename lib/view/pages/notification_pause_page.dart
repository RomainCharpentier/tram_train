import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
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
      final pauses = await DependencyInjection.instance.notificationPauseService.getAllPauses();
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
    return _buildScaffold();
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
            Icon(Icons.error, size: 64, color: context.theme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: context.theme.error),
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
          Text(
            'Aucune pause configurée',
            style: TextStyle(fontSize: 18, color: context.theme.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Configurez des pauses pour désactiver temporairement les notifications',
            style: TextStyle(color: context.theme.muted),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentPause
              ? context.theme.error
              : (isActive ? context.theme.warning : context.theme.outline),
          child: Icon(
            isCurrentPause ? Icons.pause : (isActive ? Icons.schedule : Icons.pause_circle),
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
        ),
        title: Text(
          pause.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.theme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pause.description ?? '',
              style: TextStyle(color: context.theme.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: context.theme.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(pause.startDate)} - ${_formatDate(pause.endDate)}',
                  style: TextStyle(
                    color: context.theme.muted,
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
                  color: context.theme.error,
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
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Activer/Désactiver'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
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

  Future<void> _handlePauseAction(String action, NotificationPause pause) async {
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
      await DependencyInjection.instance.notificationPauseService.updatePause(updatedPause);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedPause.isActive ? 'Pause activée' : 'Pause désactivée'),
            backgroundColor: context.theme.success,
          ),
        );
        _loadPauses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.error.withOpacity(0.75)
                : context.theme.error,
          ),
        );
      }
    }
  }

  Future<void> _deletePause(NotificationPause pause) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        title: Text(
          'Supprimer la pause',
          style: TextStyle(color: context.theme.textPrimary),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la pause "${pause.name}" ?',
          style: TextStyle(color: context.theme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: context.theme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.theme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DependencyInjection.instance.notificationPauseService.deletePause(pause.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pause supprimée'),
              backgroundColor: context.theme.success,
            ),
          );
          _loadPauses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur: $e',
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? context.theme.error.withOpacity(0.75)
                  : context.theme.error,
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

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pauses de notification',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: context.theme.primary,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePauseDialog,
        backgroundColor: context.theme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        ),
      ),
    );
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
      backgroundColor: context.theme.card,
      title: Text(
        'Créer une pause',
        style: TextStyle(color: context.theme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: context.theme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nom de la pause',
                labelStyle: TextStyle(color: context.theme.textSecondary),
                hintText: "Ex: Vacances d'été",
                hintStyle: TextStyle(color: context.theme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: TextStyle(color: context.theme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: context.theme.textSecondary),
                hintText: 'Ex: Pause pendant les vacances',
                hintStyle: TextStyle(color: context.theme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Date de début',
                style: TextStyle(color: context.theme.textPrimary),
              ),
              subtitle: Text(
                _startDate != null ? _formatDate(_startDate!) : 'Sélectionner',
                style: TextStyle(color: context.theme.textSecondary),
              ),
              trailing: Icon(Icons.calendar_today, color: context.theme.textSecondary),
              onTap: _selectStartDate,
            ),
            ListTile(
              title: Text(
                'Date de fin',
                style: TextStyle(color: context.theme.textPrimary),
              ),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'Sélectionner',
                style: TextStyle(color: context.theme.textSecondary),
              ),
              trailing: Icon(Icons.calendar_today, color: context.theme.textSecondary),
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Pause active',
                style: TextStyle(color: context.theme.textPrimary),
              ),
              subtitle: Text(
                'La pause sera activée immédiatement',
                style: TextStyle(color: context.theme.textSecondary),
              ),
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
          child: Text('Annuler', style: TextStyle(color: context.theme.primary)),
        ),
        ElevatedButton(
          onPressed: _createPause,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primary,
            foregroundColor:
                Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
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
    if (_nameController.text.trim().isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez remplir tous les champs',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.theme.error.withOpacity(0.75)
              : context.theme.error,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La date de fin doit être après la date de début',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.theme.error.withOpacity(0.75)
              : context.theme.error,
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

      await DependencyInjection.instance.notificationPauseService.createPause(pause);

      if (mounted) {
        Navigator.pop(context);
        widget.onPauseCreated?.call(pause);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pause créée avec succès',
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.success.withOpacity(0.75)
                : context.theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.error.withOpacity(0.75)
                : context.theme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
