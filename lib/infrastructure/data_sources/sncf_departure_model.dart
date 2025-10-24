class SncfDepartureModel {
  final String id;
  final String direction;
  final String departureDateTime;
  final String baseDepartureDateTime;
  final String? dataFreshness;
  final List<String> additionalInformations;

  const SncfDepartureModel({
    required this.id,
    required this.direction,
    required this.departureDateTime,
    required this.baseDepartureDateTime,
    this.dataFreshness,
    this.additionalInformations = const [],
  });

  factory SncfDepartureModel.fromJson(Map<String, dynamic> json) {
    final stopDateTime = json['stop_date_time'] as Map<String, dynamic>;
    final displayInfo = json['display_informations'] as Map<String, dynamic>;
    
    return SncfDepartureModel(
      id: json['id'] as String? ?? '',
      direction: displayInfo['direction'] as String? ?? '',
      departureDateTime: stopDateTime['departure_date_time'] as String? ?? '',
      baseDepartureDateTime: stopDateTime['base_departure_date_time'] as String? ?? '',
      dataFreshness: stopDateTime['data_freshness'] as String?,
      additionalInformations: (stopDateTime['additional_informations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}
