import 'station.dart';

/// Modèle représentant une gare favorite
class FavoriteStation {
  final String id;
  final Station station;
  final String? nickname;
  final int sortOrder;
  final DateTime createdAt;

  const FavoriteStation({
    required this.id,
    required this.station,
    this.nickname,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Génère un ID unique pour une gare favorite
  static String generateId() {
    return 'favorite_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Retourne le nom d'affichage (surnom ou nom de la gare)
  String get displayName {
    return nickname ?? station.name;
  }

  /// Crée une copie de la gare favorite avec des valeurs modifiées
  FavoriteStation copyWith({
    String? id,
    Station? station,
    String? nickname,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return FavoriteStation(
      id: id ?? this.id,
      station: station ?? this.station,
      nickname: nickname ?? this.nickname,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteStation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FavoriteStation(id: $id, station: ${station.name}, nickname: $nickname, sortOrder: $sortOrder)';
  }
}
