import '../../academic/domain/academic_models.dart';

enum FavoriteKind {
  lesson('STUDY_SUBTOPIC');

  const FavoriteKind(this.storageValue);

  final String storageValue;

  static FavoriteKind fromStorage(String value) =>
      FavoriteKind.values.firstWhere((kind) => kind.storageValue == value);
}

class FavoriteIdentity {
  const FavoriteIdentity({required this.kind, required this.itemId});

  final FavoriteKind kind;
  final String itemId;

  @override
  bool operator ==(Object other) =>
      other is FavoriteIdentity && other.kind == kind && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(kind, itemId);
}

class AcademicFavorite {
  const AcademicFavorite({
    required this.userId,
    required this.kind,
    required this.itemId,
    required this.area,
    required this.parentId,
    required this.title,
    required this.parentTitle,
    required this.savedAt,
  });

  final String userId;
  final FavoriteKind kind;
  final String itemId;
  final AcademicArea area;
  final String parentId;
  final String title;
  final String parentTitle;
  final DateTime savedAt;

  FavoriteIdentity get identity => FavoriteIdentity(kind: kind, itemId: itemId);

  String get route => '/student/study/${area.slug}/$parentId/$itemId';
}
