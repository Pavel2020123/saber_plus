import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/security/device_installation_store.dart';
import 'package:saber_plus/core/security/session_security.dart';

void main() {
  test('crea una identidad aleatoria y estable por instalación', () async {
    String? persisted;
    var writes = 0;
    final store = DeviceInstallationStore(() async => persisted, (value) async {
      persisted = value;
      writes += 1;
    }, generate: () => 'device-installation-1234567890');

    final first = await store.getOrCreate();
    final second = await store.getOrCreate();

    expect(first, 'device-installation-1234567890');
    expect(second, first);
    expect(persisted, first);
    expect(writes, 1);
  });

  test('reconoce el bloqueo de una sesión reemplazada', () {
    final event = parseSessionSecurityEvent({
      'codigo': 'SESION_OTRO_DISPOSITIVO',
      'mensaje': 'Reemplazada',
    });

    expect(event?.code, 'SESION_OTRO_DISPOSITIVO');
    expect(event?.message, contains('otro dispositivo'));
    expect(parseSessionSecurityEvent({'codigo': 'TOKEN_EXPIRADO'}), isNull);
  });

  test('comparte la misma identidad entre solicitudes simultáneas', () async {
    final releaseRead = Completer<void>();
    var generated = 0;
    var writes = 0;
    final store = DeviceInstallationStore(
      () async {
        await releaseRead.future;
        return null;
      },
      (_) async {
        writes += 1;
      },
      generate: () {
        generated += 1;
        return 'same-device-installation-123456';
      },
    );

    final first = store.getOrCreate();
    final second = store.getOrCreate();
    releaseRead.complete();

    expect(await first, await second);
    expect(generated, 1);
    expect(writes, 1);
  });

  test('el identificador generado no expone información del equipo', () {
    final first = generateDeviceInstallationId();
    final second = generateDeviceInstallationId();

    expect(first, hasLength(32));
    expect(first, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(second, isNot(first));
  });
}
