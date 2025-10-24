class Station {
  final String id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;

  const Station({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Station(id: $id, name: $name)';
}
