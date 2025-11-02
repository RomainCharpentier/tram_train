import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../infrastructure/dependency_injection.dart';
import '../theme/theme_x.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  bool _isInitializing = false;
  String _statusMessage = '';
  int _countdownSeconds = 0;
  bool _isCountdownActive = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Initialisation...';
    });

    try {
      await DependencyInjection.instance.notificationService.initialize();

      setState(() {
        _statusMessage = '✅ Notifications initialisées avec succès';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _testSimpleNotification() async {
    try {
      setState(() {
        _statusMessage = 'Envoi de la notification...';
      });

      final service = DependencyInjection.instance.notificationService;
      await service.initialize();

      await service.notifyReminder(
        _createTestTrip(),
        10,
      );

      setState(() {
        _statusMessage =
            '✅ Notification envoyée ! Vérifiez la barre de notifications de Chrome (icône cadenas dans la barre d\'adresse).';
      });
    } catch (e) {
      setState(() {
        _statusMessage =
            '❌ Erreur: $e\n\nVérifiez que les permissions sont accordées dans les paramètres du site.';
      });
    }
  }

  Future<void> _testDelayNotification() async {
    try {
      final service = DependencyInjection.instance.notificationService;
      await service.initialize();

      await service.notifyDelay(_createTestTrip(), 15);

      setState(() {
        _statusMessage = '✅ Notification de retard envoyée !';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur: $e';
      });
    }
  }

  Future<void> _testCancellationNotification() async {
    try {
      final service = DependencyInjection.instance.notificationService;
      await service.initialize();

      await service.notifyCancellation(_createTestTrip());

      setState(() {
        _statusMessage = '✅ Notification d\'annulation envoyée !';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur: $e';
      });
    }
  }

  Future<void> _testNotificationWithTimer(int delaySeconds) async {
    if (_isCountdownActive) return;

    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = delaySeconds;
      _statusMessage =
          '⏱️ Notification programmée dans $delaySeconds secondes...';
    });

    final service = DependencyInjection.instance.notificationService;
    await service.initialize();

    for (int i = delaySeconds - 1; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isCountdownActive) break;
      setState(() {
        _countdownSeconds = i;
        if (i > 0) {
          _statusMessage =
              '⏱️ Notification dans $i seconde${i > 1 ? 's' : ''}...';
        }
      });
    }

    if (!mounted || !_isCountdownActive) return;

    await service.notifyReminder(_createTestTrip(), 5);
    if (mounted) {
      setState(() {
        _statusMessage = '✅ Notification envoyée !';
        _isCountdownActive = false;
        _countdownSeconds = 0;
      });
    }
  }

  domain.Trip _createTestTrip() {
    return domain.Trip(
      id: 'test_trip_${DateTime.now().millisecondsSinceEpoch}',
      departureStation: Station(
        id: 'test_dep',
        name: 'Gare de Test Départ',
        description: 'Station de test',
      ),
      arrivalStation: Station(
        id: 'test_arr',
        name: 'Gare de Test Arrivée',
        description: 'Station de test',
      ),
      days: [],
      time: domain.TimeOfDay(hour: 10, minute: 30),
      isActive: true,
      notificationsEnabled: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Notifications'),
        backgroundColor: context.theme.primary,
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
            Card(
              color: context.theme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.theme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isInitializing)
                      const CircularProgressIndicator()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusMessage.isEmpty
                                ? 'Prêt à tester'
                                : _statusMessage,
                            style: TextStyle(
                              color: _statusMessage.startsWith('✅')
                                  ? context.theme.success
                                  : _statusMessage.startsWith('❌')
                                      ? context.theme.error
                                      : _statusMessage.startsWith('⏱️')
                                          ? context.theme.warning
                                          : context.theme.onSurface,
                            ),
                          ),
                          if (_isCountdownActive && _countdownSeconds > 0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _countdownSeconds / 5,
                              backgroundColor: context.theme.outline,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.theme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_countdownSeconds',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: context.theme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isCountdownActive
                  ? null
                  : () => _testNotificationWithTimer(5),
              icon:
                  Icon(_isCountdownActive ? Icons.timer : Icons.timer_outlined),
              label: Text(_isCountdownActive
                  ? 'Notification dans $_countdownSeconds s...'
                  : 'Tester avec timer (5 secondes)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: context.theme.muted,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isCountdownActive ? null : _testSimpleNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('Tester notification de rappel (immédiate)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: context.theme.muted,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isCountdownActive ? null : _testDelayNotification,
              icon: const Icon(Icons.schedule),
              label: const Text('Tester notification de retard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: context.theme.muted,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _isCountdownActive ? null : _testCancellationNotification,
              icon: const Icon(Icons.cancel),
              label: const Text('Tester notification d\'annulation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: context.theme.muted,
              ),
            ),
            const Spacer(),
            Card(
              color: context.theme.bgCard,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: context.theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.theme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Assurez-vous d\'avoir accordé les permissions de notification\n'
                      '2. Cliquez sur un bouton de test\n'
                      '3. Une notification devrait apparaître dans quelques secondes\n'
                      '4. Si rien ne se passe, vérifiez les paramètres de notification de votre appareil',
                      style: TextStyle(
                        color: context.theme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
