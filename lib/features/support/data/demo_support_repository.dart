import '../domain/support_configuration.dart';
import '../domain/support_repository.dart';

class DemoSupportRepository implements SupportRepository {
  @override
  Future<SupportConfiguration> load() async => const SupportConfiguration(
    isActive: true,
    whatsappNumber: '573001234567',
    message: 'Hola, necesito ayuda con SaberPlus.',
    whatsappUrl:
        'https://wa.me/573001234567?text=Hola%2C%20necesito%20ayuda%20con%20SaberPlus.',
  );
}
