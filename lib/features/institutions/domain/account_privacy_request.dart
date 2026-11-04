class AccountPrivacyRequest {
  const AccountPrivacyRequest._(
    this.id,
    this.userId,
    this.state,
    this.createdAt,
  );
  final String id, userId, state;
  final DateTime createdAt;

  factory AccountPrivacyRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'], user = json['usuarioId'], state = json['estado'];
    final rawDate = json['creadoEn'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (id is! String ||
        id.isEmpty ||
        user is! String ||
        user.isEmpty ||
        !const ['PENDIENTE', 'RECHAZADA', 'EJECUTADA'].contains(state) ||
        date == null) {
      throw const FormatException('Invalid privacy request');
    }
    return AccountPrivacyRequest._(id, user, state as String, date);
  }

  String get label => switch (state) {
    'PENDIENTE' => 'Pendiente de revisión',
    'RECHAZADA' => 'No aprobada',
    _ => 'Supresión ejecutada',
  };
}

class AccountPrivacyPage {
  const AccountPrivacyPage(this.page, this.hasNext, this.items);
  final int page;
  final bool hasNext;
  final List<AccountPrivacyRequest> items;

  factory AccountPrivacyPage.fromJson(Map<String, dynamic> json) {
    final page = json['pagina'],
        next = json['tieneSiguiente'],
        items = json['items'];
    if (page is! int ||
        page < 1 ||
        next is! bool ||
        items is! List ||
        items.length > 20) {
      throw const FormatException('Invalid privacy request page');
    }
    return AccountPrivacyPage(
      page,
      next,
      List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid privacy row');
          }
          return AccountPrivacyRequest.fromJson(item);
        }),
      ),
    );
  }
}
