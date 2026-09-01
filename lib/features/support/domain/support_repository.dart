import 'support_configuration.dart';

abstract interface class SupportRepository {
  Future<SupportConfiguration> load();
}
