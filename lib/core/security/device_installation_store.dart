import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef DeviceIdReader = Future<String?> Function();
typedef DeviceIdWriter = Future<void> Function(String value);

class DeviceInstallationStore {
  DeviceInstallationStore(
    this._read,
    this._write, {
    String Function()? generate,
  }) : _generate = generate ?? generateDeviceInstallationId;

  static const storageKey = 'saberplus_device_installation_id';

  final DeviceIdReader _read;
  final DeviceIdWriter _write;
  final String Function() _generate;
  String? _cached;
  Future<String>? _inFlight;

  Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) return cached;
    final pending = _inFlight;
    if (pending != null) return pending;
    final operation = _loadOrCreate();
    _inFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_inFlight, operation)) _inFlight = null;
    }
  }

  Future<String> _loadOrCreate() async {
    try {
      final stored = await _read();
      if (_isValid(stored)) return _cached = stored!;
    } on MissingPluginException {
      return _cached = _generate();
    }

    final generated = _generate();
    _cached = generated;
    try {
      await _write(generated);
    } on MissingPluginException {
      // Las pruebas sin plugins conservan el identificador solo en memoria.
    }
    return generated;
  }

  bool _isValid(String? value) =>
      value != null && value.length >= 24 && value.length <= 64;
}

String generateDeviceInstallationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

final deviceInstallationStoreProvider = Provider<DeviceInstallationStore>((
  ref,
) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  return DeviceInstallationStore(
    () => storage.read(key: DeviceInstallationStore.storageKey),
    (value) =>
        storage.write(key: DeviceInstallationStore.storageKey, value: value),
  );
});
