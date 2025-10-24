import 'package:flutter/material.dart';
import '../../dependency_injection.dart';
import 'train_list_page.dart';
import 'trip_management_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tram Train'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.train,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bienvenue sur Tram Train',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultez les horaires et gérez vos trajets',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButton(
              context,
              'Consulter les horaires',
              Icons.schedule,
              () => _navigateToTrainList(context),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Gérer mes trajets',
              Icons.route,
              () => _navigateToTripManagement(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  void _navigateToTrainList(BuildContext context) {
    final controller = DependencyInjection.instance.createTrainListController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainListPage(
          controller: controller,
          station: DependencyInjection.babiniereStation,
        ),
      ),
    );
  }

  void _navigateToTripManagement(BuildContext context) {
    final controller = DependencyInjection.instance.createTripController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripManagementPage(controller: controller),
      ),
    );
  }
}
