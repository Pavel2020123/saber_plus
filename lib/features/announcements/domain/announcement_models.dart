enum AnnouncementType {
  information('Información'),
  important('Importante'),
  event('Evento');

  const AnnouncementType(this.label);

  final String label;

  factory AnnouncementType.fromBackend(String? value) => switch (value) {
    'IMPORTANTE' => AnnouncementType.important,
    'EVENTO' => AnnouncementType.event,
    _ => AnnouncementType.information,
  };
}

enum AnnouncementOrigin {
  saberPlus('SaberPlus'),
  institution('Tu institución');

  const AnnouncementOrigin(this.label);

  final String label;

  factory AnnouncementOrigin.fromBackend(String? value) =>
      value == 'INSTITUCION'
      ? AnnouncementOrigin.institution
      : AnnouncementOrigin.saberPlus;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.origin,
    required this.startsAt,
    required this.isFeatured,
    required this.isRead,
    this.endsAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final AnnouncementOrigin origin;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isFeatured;
  final bool isRead;
  final DateTime? readAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    title: json['titulo'] as String,
    content: json['contenido'] as String,
    type: AnnouncementType.fromBackend(json['tipo'] as String?),
    origin: AnnouncementOrigin.fromBackend(json['origen'] as String?),
    startsAt: DateTime.parse(json['fechaInicio'] as String).toLocal(),
    endsAt: _date(json['fechaFin']),
    isFeatured: json['destacado'] as bool? ?? false,
    isRead: json['leido'] as bool? ?? false,
    readAt: _date(json['fechaLectura']),
  );

  Announcement copyWith({bool? isRead, DateTime? readAt}) => Announcement(
    id: id,
    title: title,
    content: content,
    type: type,
    origin: origin,
    startsAt: startsAt,
    endsAt: endsAt,
    isFeatured: isFeatured,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
  );
}

class AnnouncementBoard {
  const AnnouncementBoard({required this.items, required this.pendingCount});

  final List<Announcement> items;
  final int pendingCount;

  factory AnnouncementBoard.fromJson(Map<String, dynamic> json) {
    final values = json['anuncios'];
    final items = values is List
        ? values
              .whereType<Map>()
              .map(
                (item) =>
                    Announcement.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : <Announcement>[];
    return AnnouncementBoard(
      items: items,
      pendingCount:
          json['pendientes'] as int? ??
          items.where((item) => !item.isRead).length,
    );
  }

  AnnouncementBoard markRead(String id, DateTime readAt) {
    final next = items
        .map(
          (item) => item.id == id && !item.isRead
              ? item.copyWith(isRead: true, readAt: readAt)
              : item,
        )
        .toList(growable: false);
    return AnnouncementBoard(
      items: next,
      pendingCount: next.where((item) => !item.isRead).length,
    );
  }

  AnnouncementBoard markAllRead(DateTime readAt) => AnnouncementBoard(
    items: items
        .map(
          (item) =>
              item.isRead ? item : item.copyWith(isRead: true, readAt: readAt),
        )
        .toList(growable: false),
    pendingCount: 0,
  );
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
