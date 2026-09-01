enum RankingScope {
  global('GLOBAL', 'Global'),
  institution('INSTITUCION', 'Mi institución');

  const RankingScope(this.backendValue, this.label);

  final String backendValue;
  final String label;

  static RankingScope fromBackend(Object? value) => values.firstWhere(
    (scope) => scope.backendValue == value,
    orElse: () => throw const FormatException('Alcance de ranking inválido.'),
  );
}

enum RankingPeriod {
  week('SEMANA', 'Semana'),
  month('MES', 'Mes'),
  total('TOTAL', 'Histórico');

  const RankingPeriod(this.backendValue, this.label);

  final String backendValue;
  final String label;

  static RankingPeriod fromBackend(Object? value) => values.firstWhere(
    (period) => period.backendValue == value,
    orElse: () => throw const FormatException('Período de ranking inválido.'),
  );
}

class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.alias,
    required this.xp,
    required this.isCurrentUser,
  });

  final int position;
  final String alias;
  final int xp;
  final bool isCurrentUser;

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    const allowedKeys = {'posicion', 'alias', 'xp', 'esUsuarioActual'};
    if (json.keys.any((key) => !allowedKeys.contains(key))) {
      throw const FormatException(
        'El ranking contiene datos personales no permitidos.',
      );
    }
    final position = (json['posicion'] as num?)?.toInt() ?? 0;
    final alias = (json['alias'] as String? ?? '').trim();
    final xp = (json['xp'] as num?)?.toInt() ?? -1;
    if (position <= 0 || alias.isEmpty || xp < 0) {
      throw const FormatException('Entrada de ranking incompleta.');
    }
    return RankingEntry(
      position: position,
      alias: alias,
      xp: xp,
      isCurrentUser: json['esUsuarioActual'] == true,
    );
  }
}

class RankingBoard {
  const RankingBoard({
    required this.scope,
    required this.period,
    required this.scopeName,
    required this.institutionAvailable,
    required this.totalParticipants,
    required this.updatedAt,
    required this.entries,
    required this.identitiesProtected,
    this.myPosition,
  });

  final RankingScope scope;
  final RankingPeriod period;
  final String scopeName;
  final bool institutionAvailable;
  final int totalParticipants;
  final DateTime updatedAt;
  final List<RankingEntry> entries;
  final RankingEntry? myPosition;
  final bool identitiesProtected;

  factory RankingBoard.fromJson(Map<String, dynamic> json) {
    final privacy = _map(json['privacidad']);
    if (privacy['identidadesProtegidas'] != true) {
      throw const FormatException(
        'SaberPlus rechazó un ranking sin protección de identidad.',
      );
    }
    final updatedAt = DateTime.tryParse(json['actualizadoEn'] as String? ?? '');
    if (updatedAt == null) {
      throw const FormatException('Fecha de ranking inválida.');
    }
    final entries = _list(json['ranking'])
        .map((entry) => RankingEntry.fromJson(_map(entry)))
        .toList(growable: false);
    final rawMine = json['miPosicion'];
    final mine = rawMine == null ? null : RankingEntry.fromJson(_map(rawMine));
    return RankingBoard(
      scope: RankingScope.fromBackend(json['alcance']),
      period: RankingPeriod.fromBackend(json['periodo']),
      scopeName: json['nombreAlcance'] as String? ?? 'SaberPlus',
      institutionAvailable: json['institucionDisponible'] == true,
      totalParticipants: ((json['totalParticipantes'] as num?)?.toInt() ?? 0)
          .clamp(0, 100000000),
      updatedAt: updatedAt.toLocal(),
      entries: List.unmodifiable(entries),
      myPosition: mine,
      identitiesProtected: true,
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Object?> _list(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];
