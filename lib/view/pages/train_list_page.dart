import 'package:flutter/material.dart';
import '../../domain/models/station.dart';
import '../../domain/models/train.dart';
import '../../dependency_injection.dart';
import '../widgets/train_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class TrainListPage extends StatefulWidget {
  final Station station;

  const TrainListPage({
    super.key,
    required this.station,
  });

  @override
  State<TrainListPage> createState() => _TrainListPageState();
}

class _TrainListPageState extends State<TrainListPage> {
  List<Train> _trains = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrains();
  }

  Future<void> _loadTrains() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trains = await DependencyInjection.instance.trainService.getDepartures(widget.station);
      setState(() {
        _trains = trains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trains: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trains - ${widget.station.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrains,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return custom.CustomErrorWidget(
        message: _error!,
        onRetry: _loadTrains,
      );
    }

    if (_trains.isEmpty) {
      return const Center(
        child: Text('Aucun train disponible'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrains,
      child: ListView.builder(
        itemCount: _trains.length,
        itemBuilder: (context, index) {
          final train = _trains[index];
          return TrainCard(train: train);
        },
      ),
    );
  }
}
