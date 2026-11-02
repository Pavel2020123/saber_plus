import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/media/private_lesson_cache.dart';
import 'package:saber_plus/core/media/private_offline_access_policy.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/features/study/presentation/private_lesson_page.dart';

class _Vault implements PrivateLessonVault {
  Duration elapsed = Duration.zero;
  String boot = 'one';
  final records = <String, ({String payload, OfflineClockSample anchor})>{};
  Completer<void>? sealGate;
  bool failWrite = false;
  @override
  Future<OfflineClockSample> clock() async =>
      OfflineClockSample(bootId: boot, elapsed: elapsed);
  @override
  Future<void> seal(
    String owner,
    String context,
    String payload,
    OfflineClockSample anchor,
  ) async {
    await sealGate?.future;
    if (failWrite) throw StateError('synthetic disk failure');
    records['$owner/$context'] = (payload: payload, anchor: anchor);
  }

  @override
  Future<({String payload, int remainingMs})?> read(
    String owner,
    String context,
  ) async {
    final record = records['$owner/$context'];
    if (record == null ||
        record.anchor.bootId != boot ||
        elapsed < record.anchor.elapsed ||
        elapsed - record.anchor.elapsed >= const Duration(hours: 72)) {
      return null;
    }
    return (
      payload: record.payload,
      remainingMs:
          (const Duration(hours: 72) - (elapsed - record.anchor.elapsed))
              .inMilliseconds,
    );
  }

  @override
  Future<void> clearAccount(String owner) async =>
      records.removeWhere((key, _) => key.startsWith('$owner/'));
  @override
  Future<void> clearContext(String owner, String context) async {
    records.remove('$owner/$context');
  }
}

class _Api implements HttpClientAdapter {
  int status = 201, calls = 0;
  bool offline = false, corrupt = false;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    await gate?.future;
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (status != 201) {
      return ResponseBody.fromString(
        '{}',
        status,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    final input = options.data is String
        ? jsonDecode(options.data as String) as Map
        : options.data as Map;
    final snapshot = {
      'title': 'Private lesson',
      'content': 'Private text only',
      'image': null,
    };
    final data = {
      'policyVersion': 1,
      'ownerId': 'a',
      'contextId': 'lesson',
      'requestNonce': input['requestNonce'],
      'validatedAt': '2026-11-01T00:00:00.000Z',
      'expiresAt': '2026-11-04T00:00:00.000Z',
      'contextDigest': corrupt
          ? 'bad'
          : sha256.convert(utf8.encode(jsonEncode(snapshot))).toString(),
      'snapshot': snapshot,
    };
    return ResponseBody.fromString(
      jsonEncode(data),
      201,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Vault vault;
  late _Api api;
  late Dio dio;
  late PrivateLessonCache cache;
  late AccessTokenStore tokens;
  bool providerOwnsCache = false;
  setUp(() {
    providerOwnsCache = false;
    vault = _Vault();
    api = _Api();
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:43187'))
      ..httpClientAdapter = api;
    tokens = AccessTokenStore()..set('synthetic');
    cache = PrivateLessonCache(dio, tokens, vault)..setAccount('a');
  });
  tearDown(() {
    if (!providerOwnsCache) cache.dispose();
    dio.close(force: true);
  });
  test('stores only validated exact package and reads within 72h', () async {
    expect((await cache.open('lesson')).content, 'Private text only');
    expect(vault.records, hasLength(1));
    api.offline = true;
    vault.elapsed = const Duration(hours: 71);
    expect((await cache.open('lesson')).remaining, const Duration(hours: 1));
    vault.elapsed = const Duration(hours: 72);
    await expectLater(
      cache.open('lesson'),
      throwsA(isA<PrivateLessonUnavailable>()),
    );
  });
  test('network failures never renew the validation deadline', () async {
    await cache.open('lesson');
    api.offline = true;
    vault.elapsed = const Duration(hours: 70);
    await cache.open('lesson');
    expect(vault.records['a/lesson']!.anchor.elapsed, Duration.zero);
  });
  test('failed encrypted write cannot publish or retain an old readable package', () async {
    await cache.open('lesson');
    vault.failWrite = true;
    await expectLater(cache.open('lesson'), throwsA(isA<PrivateLessonUnavailable>()));
    expect(await cache.read('lesson'), isNull);
    expect(vault.records, isEmpty);
  });
  for (final status in [401, 403, 404, 409, 410]) {
    test(
      'confirmed HTTP $status forbids offline fallback and removes package',
      () async {
        await cache.open('lesson');
        api.status = status;
        await expectLater(
          cache.open('lesson'),
          throwsA(isA<PrivateLessonUnavailable>()),
        );
        expect(await cache.read('lesson'), isNull);
        expect(vault.records, isEmpty);
      },
    );
  }
  test('503 can use a valid copy but never grants a new lease', () async {
    await cache.open('lesson');
    api.status = 503;
    vault.elapsed = const Duration(hours: 70);
    expect((await cache.open('lesson')).remaining, const Duration(hours: 2));
  });
  test('changing accounts clears old private cache without sharing', () async {
    await cache.open('lesson');
    cache.setAccount('b');
    await Future<void>.delayed(Duration.zero);
    expect(await cache.read('lesson'), isNull);
    expect(vault.records, isEmpty);
  });
  test(
    'a late write after logout is cleaned up and cannot revive data',
    () async {
      vault.sealGate = Completer<void>();
      final pending = cache.open('lesson');
      final assertion = expectLater(
        pending,
        throwsA(isA<PrivateLessonUnavailable>()),
      );
      for (var i = 0; i < 20 && api.calls == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      cache.setAccount(null);
      vault.sealGate!.complete();
      await assertion;
      expect(vault.records, isEmpty);
    },
  );
  test(
    'tampered package never becomes readable and reboot fails closed',
    () async {
      await cache.open('lesson');
      final record = vault.records['a/lesson']!;
      vault.records['a/lesson'] = (
        payload: record.payload.replaceAll('Private text only', 'altered'),
        anchor: record.anchor,
      );
      expect(await cache.read('lesson'), isNull);
      vault.records['a/lesson'] = record;
      vault.boot = 'two';
      expect(await cache.read('lesson'), isNull);
    },
  );
  test(
    'malformed online response is not downgraded to an old offline copy',
    () async {
      await cache.open('lesson');
      api.corrupt = true;
      await expectLater(
        cache.open('lesson'),
        throwsA(isA<PrivateLessonUnavailable>()),
      );
      expect(await cache.read('lesson'), isNull);
    },
  );
  testWidgets(
    'confirmed suspension removes plaintext without an automatic retry loop',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            privateLessonCacheProvider.overrideWith((ref) {
              providerOwnsCache = true;
              return cache;
            }),
          ],
          child: const MaterialApp(
            home: PrivateLessonPage(contextId: 'lesson'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private text only'), findsOneWidget);
      final calls = api.calls;
      await cache.deny('lesson', account: true);
      await tester.pumpAndSettle();
      expect(find.text('Private text only'), findsNothing);
      expect(api.calls, calls);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('expiry hides an already-open private reader', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privateLessonCacheProvider.overrideWith((ref) {
            providerOwnsCache = true;
            return cache;
          }),
        ],
        child: const MaterialApp(home: PrivateLessonPage(contextId: 'lesson')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private text only'), findsOneWidget);
    await tester.pump(const Duration(hours: 72));
    await tester.pump();
    expect(find.text('Private text only'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
