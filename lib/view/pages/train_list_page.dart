import 'package:flutter/material.dart';
import '../../domain/models/station.dart';
import '../../domain/services/train_list_controller.dart';
import '../widgets/train_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class TrainListPage extends StatefulWidget {
  final TrainListController controller;
  final Station station;

  const TrainListPage({
    super.key,
    required this.controller,
    required this.station,
  });

  @override
  State<TrainListPage> createState() => _TrainListPageState();
}

class _TrainListPageState extends State<TrainListPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    widget.controller.loadDepartures(widget.station);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trains - ${widget.station.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.controller.refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.controller.isLoading) {
      return const LoadingWidget();
    }

    if (widget.controller.error != null) {
      return custom.CustomErrorWidget(
        message: widget.controller.error!,
        onRetry: () => widget.controller.refresh(),
      );
    }

    if (widget.controller.trains.isEmpty) {
      return const Center(
        child: Text('Aucun train disponible'),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView.builder(
        itemCount: widget.controller.trains.length,
        itemBuilder: (context, index) {
          final train = widget.controller.trains[index];
          return TrainCard(train: train);
        },
      ),
    );
  }
}
