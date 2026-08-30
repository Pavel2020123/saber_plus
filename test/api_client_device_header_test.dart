import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_client.dart';
import 'package:saber_plus/core/security/device_installation_store.dart';

void main() {
  test('envía la identidad de instalación en cada solicitud', () async {
    final deviceStore = DeviceInstallationStore(
      () async => 'device-installation-1234567890',
      (_) async {},
    );
    final container = ProviderContainer(
      overrides: [
        deviceInstallationStoreProvider.overrideWithValue(deviceStore),
      ],
    );
    addTearDown(container.dispose);
    final dio = container.read(publicDioProvider);
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;

    await dio.get<void>('/health');

    expect(
      adapter.request?.headers['X-Device-Id'],
      'device-installation-1234567890',
    );
    expect(adapter.request?.headers['X-SaberPlus-Client'], 'mobile');
    expect(adapter.request?.headers['X-Request-Id'], startsWith('mobile-'));
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '',
      204,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
