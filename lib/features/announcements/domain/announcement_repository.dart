import 'announcement_models.dart';

abstract interface class AnnouncementRepository {
  Future<AnnouncementBoard> load();

  Future<DateTime> markRead(String id);

  Future<void> markAllRead();
}
