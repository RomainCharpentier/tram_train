import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/train.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/journey_stop.dart';
import '../../infrastructure/gateways/mocks/data/mock_data.dart';
import '../../infrastructure/dependency_injection.dart';
import '../utils/train_status_colors.dart';
import '../widgets/trip_status_card.dart';

class TripProgressPage extends StatefulWidget {
  final domain.Trip trip;
  final Train? currentTrain;

  const TripProgressPage({
    super.key,
    required this.trip,
    this.currentTrain,
  });

  @override
  State<TripProgressPage> createState() => _TripProgressPageState();
}

class _TripProgressPageState extends State<TripProgressPage> {
  List<JourneyStop> _journeyStops = [];
  bool _isLoadingStops = false;

  @override
  void initState() {
    super.initState();
    _loadJourneyStops();
  }

  Future<void> _loadJourneyStops() async {
    if (widget.currentTrain == null) return;

    setState(() {
      _isLoadingStops = true;
    });

    try {
      final stops = _generateJourneyStops(widget.trip, widget.currentTrain!);

      final now = _now();
      final updatedStops = <JourneyStop>[];

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        bool isPassed = false;
        bool isCurrent = false;
        bool isUpcoming = false;

        if (i == 0 && stop.departureTime != null) {
          if (stop.departureTime!.isBefore(now.subtract(const Duration(minutes: 2)))) {
            isPassed = true;
          } else if (stop.departureTime!.isBefore(now.add(const Duration(minutes: 2)))) {
            isCurrent = true;
          } else {
            isUpcoming = true;
          }
        } else if (i > 0 && i < stops.length - 1) {
          if (stop.arrivalTime != null && stop.departureTime != null) {
            if (stop.departureTime!.isBefore(now.subtract(const Duration(minutes: 2)))) {
              isPassed = true;
            } else if (stop.arrivalTime!.isBefore(now) && stop.departureTime!.isAfter(now)) {
              isCurrent = true;
            } else if (stop.arrivalTime!.isBefore(now.subtract(const Duration(minutes: 2)))) {
              isPassed = true;
            } else {
              isUpcoming = true;
            }
          }
        } else if (i == stops.length - 1 && stop.arrivalTime != null) {
          if (stop.arrivalTime!.isBefore(now.subtract(const Duration(minutes: 2)))) {
            isPassed = true;
          } else if (stop.arrivalTime!.isBefore(now.add(const Duration(minutes: 5)))) {
            isCurrent = true;
          } else {
            isUpcoming = true;
          }
        }

        updatedStops.add(stop.copyWith(
          isPassed: isPassed,
          isCurrent: isCurrent,
          isUpcoming: isUpcoming,
        ));
      }

      setState(() {
        _journeyStops = updatedStops;
        _isLoadingStops = false;
      });
    } on Exception {
      setState(() {
        _isLoadingStops = false;
      });
    }
  }

  List<JourneyStop> _generateJourneyStops(domain.Trip trip, Train train) {
    final stops = <JourneyStop>[];

    stops.add(JourneyStop(
      station: trip.departureStation,
      departureTime: train.departureTime,
      baseDepartureTime: train.baseDepartureTime ?? train.departureTime,
    ));

    final intermediateStations = MockData.getIntermediateStationsForTrip(trip);

    if (train.arrivalTime != null && intermediateStations.isNotEmpty) {
      final totalDuration = train.arrivalTime!.difference(train.departureTime);

      for (int i = 0; i < intermediateStations.length; i++) {
        final progress = (i + 1) / (intermediateStations.length + 1);
        final stopTime = train.departureTime.add(
          Duration(
            seconds: (totalDuration.inSeconds * progress).round(),
          ),
        );

        stops.add(JourneyStop(
          station: intermediateStations[i],
          arrivalTime: stopTime,
          departureTime: stopTime.add(const Duration(minutes: 2)),
          baseArrivalTime: stopTime,
          baseDepartureTime: stopTime.add(const Duration(minutes: 2)),
        ));
      }
    }

    stops.add(JourneyStop(
      station: trip.arrivalStation,
      arrivalTime: train.arrivalTime,
      baseArrivalTime: train.baseArrivalTime ?? train.arrivalTime,
    ));

    return stops;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trajet ${widget.trip.description}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.currentTrain == null) {
      return _buildNoTrainInfo();
    }

    final train = widget.currentTrain!;
    final now = _now();
    final isInProgress = _isTrainInProgress(train, now);
    final progress = _calculateProgress(train, now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(train, isInProgress),
          const SizedBox(height: 16),
          _buildJourneyPlan(train, isInProgress, progress),
          const SizedBox(height: 16),
          _buildScheduleDetails(train),
        ],
      ),
    );
  }

  Widget _buildNoTrainInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: context.theme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune information disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Le prochain train pour ce trajet n'a pas encore été trouvé.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.muted),
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.trip.daysName} à ${widget.trip.timeFormatted}',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Train train, bool isInProgress) {
    return TripStatusCard(
      trip: widget.trip,
      train: train,
    );
  }

  Widget _buildJourneyPlan(Train train, bool isInProgress, double progress) {
    if (_isLoadingStops) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_journeyStops.isNotEmpty) {
      return _buildFullJourneyPlan(train, isInProgress, progress);
    }

    return _buildSimpleJourneyPlan(train, isInProgress, progress);
  }

  Widget _buildFullJourneyPlan(Train train, bool isInProgress, double progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parcours du train',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._journeyStops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final isLast = index == _journeyStops.length - 1;

              return Column(
                children: [
                  _buildStopRow(stop, train),
                  if (!isLast) _buildStopConnection(stop, index, progress),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStopRow(JourneyStop stop, Train train) {
    final presentation = TrainStatusColors.buildPresentation(train);
    Color dotColor;
    IconData? dotIcon;
    final isPassed = stop.isPassed;
    final isCurrent = stop.isCurrent;

    if (isCurrent) {
      dotColor = presentation.primaryColor;
      dotIcon = Icons.train;
    } else if (isPassed) {
      dotColor = TrainStatusColors.onTimeColor;
      dotIcon = Icons.check_circle;
    } else {
      dotColor = context.theme.outline;
      dotIcon = null;
    }

    final stationOpacity = isPassed ? 0.5 : 1.0;
    final textColor = isPassed
        ? context.theme.textSecondary.withValues(alpha: stationOpacity)
        : (isCurrent ? presentation.primaryColor : context.theme.textPrimary);

    return Opacity(
      opacity: stationOpacity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isPassed ? Colors.grey.withValues(alpha: 0.1) : dotColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPassed ? Colors.grey : dotColor,
                width: 2,
              ),
            ),
            child: dotIcon != null
                ? Icon(dotIcon, color: isPassed ? Colors.grey : dotColor, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stop.station.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: presentation.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          presentation.state == TrainJourneyState.inProgress
                              ? 'En cours'
                              : 'À venir',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: presentation.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (stop.departureTime != null) ...[
                  Text(
                    'Départ: ${_formatTime(stop.departureTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.textSecondary.withValues(alpha: stationOpacity),
                    ),
                  ),
                ] else if (stop.arrivalTime != null) ...[
                  Text(
                    'Arrivée: ${_formatTime(stop.arrivalTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.textSecondary.withValues(alpha: stationOpacity),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopConnection(JourneyStop stop, int index, double overallProgress) {
    final previousStopProgress = index / _journeyStops.length;
    final currentStopProgress = (index + 1) / _journeyStops.length;

    final isSectionPassed = overallProgress >= currentStopProgress;
    final isSectionCurrent =
        overallProgress >= previousStopProgress && overallProgress < currentStopProgress;

    double coloredHeight = 0;
    double greyHeight = 40;
    if (isSectionCurrent) {
      final sectionProgress =
          (overallProgress - previousStopProgress) / (currentStopProgress - previousStopProgress);
      coloredHeight = 40 * sectionProgress;
      greyHeight = 40 - coloredHeight;
    } else if (isSectionPassed) {
      coloredHeight = 40;
      greyHeight = 0;
    }

    final journeyColor = widget.currentTrain != null
        ? TrainStatusColors.getJourneyStateColor(widget.currentTrain!)
        : TrainStatusColors.unknownColor;

    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            if (greyHeight > 0) ...[
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3,
                  height: greyHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
            if (coloredHeight > 0) ...[
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3,
                  height: coloredHeight,
                  decoration: BoxDecoration(
                    color: journeyColor,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: journeyColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleJourneyPlan(Train train, bool isInProgress, double progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStationDot(TrainStatusColors.onTimeColor, true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip.departureStation.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Départ: ${train.departureTimeFormatted}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7, top: 8, bottom: 8),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.theme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (isInProgress && progress > 0) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 4,
                        width: MediaQuery.of(context).size.width * 0.8 * (progress / 100),
                        decoration: BoxDecoration(
                          color: TrainStatusColors.getJourneyStateColor(train),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                  if (isInProgress && progress > 0 && progress < 100) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(
                          MediaQuery.of(context).size.width * 0.8 * (progress / 100) - 8,
                          0,
                        ),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: TrainStatusColors.getJourneyStateColor(train),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.train,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                _buildStationDot(
                  train.status == TrainStatus.cancelled
                      ? TrainStatusColors.cancelledColor
                      : TrainStatusColors.onTimeColor,
                  false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip.arrivalStation.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (train.arrivalTimeFormatted != null) ...[
                        Text(
                          'Arrivée prévue: ${train.arrivalTimeFormatted}',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.theme.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Arrivée: Non disponible',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.theme.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isInProgress && progress > 0 && progress < 100) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TrainStatusColors.getJourneyStateColor(train).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progress.toStringAsFixed(0)}% du trajet effectué',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TrainStatusColors.getJourneyStateColor(train),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStationDot(Color color, bool isDeparture) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildScheduleDetails(Train train) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildScheduleRow(
              'Départ',
              train.departureTimeFormatted,
              _formatOptionalTime(TrainStatusColors.getScheduledDepartureTime(train)),
            ),
            if (train.arrivalTimeFormatted != null) ...[
              const SizedBox(height: 8),
              _buildScheduleRow(
                'Arrivée',
                train.arrivalTimeFormatted!,
                _formatOptionalTime(TrainStatusColors.getScheduledArrivalTime(train)),
              ),
            ],
            if (train.delayMinutes != null && train.delayMinutes! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: context.theme.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Retard: +${train.delayMinutes} minutes',
                    style: TextStyle(
                      color: context.theme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String label, String time, String? baseTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.theme.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (baseTime != null && baseTime != time) ...[
              const SizedBox(width: 8),
              Text(
                '($baseTime prévu)',
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.muted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String? _formatOptionalTime(DateTime? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime _now() {
    try {
      return DependencyInjection.instance.clockService.now();
    } catch (e) {
      const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
      return useMockData ? DateTime(2025, 1, 6, 7, 0) : DateTime.now();
    }
  }

  bool _isTrainInProgress(Train train, DateTime now) {
    if (train.departureTime.isAfter(now)) return false;
    if (train.arrivalTime != null && train.arrivalTime!.isBefore(now)) return false;
    return true;
  }

  double _calculateProgress(Train train, DateTime now) {
    if (!_isTrainInProgress(train, now)) return 0;

    if (train.arrivalTime == null) return 0;

    final totalDuration = train.arrivalTime!.difference(train.departureTime);
    if (totalDuration.inSeconds <= 0) return 0;

    final elapsed = now.difference(train.departureTime);
    if (elapsed.isNegative) return 0;

    final progress = (elapsed.inSeconds / totalDuration.inSeconds) * 100;
    return progress.clamp(0.0, 100.0);
  }
}
