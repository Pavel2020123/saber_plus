import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/data/private_document_access.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';

const operation = '3bfc090f-9aa3-45ad-9f20-23dad1b41475';
const request = 'd9ac5e51-de18-46ce-b596-b62a97d1ac91';
const id = 'e902e956-dbb5-4c91-ae4f-425ee6bc7db8';
const channel = MethodChannel('saberplus/private_documents_v1');
InstitutionEvidenceFile metadata() => InstitutionEvidenceFile.fromJson({
  'id': id,
  'operacionId': operation,
  'estado': 'ACTIVO',
  'revision': 2,
  'mime': 'application/pdf',
  'bytes': 5,
  'disponible': true,
  'limpiezaPendiente': false,
  'contenido': institutionEvidencePath(request, id),
  'venceEn': null,
}, request);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  PrivateDocumentAccess access({
    bool enabled = true,
    TargetPlatform platform = TargetPlatform.android,
    bool Function()? current,
  }) => PrivateDocumentAccess(
    enabled: enabled,
    platform: platform,
    isCurrent: current ?? () => true,
    operationId: () => operation,
  );

  test('disabled or unsupported platform cannot open the OS picker', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return null;
    });
    for (final value in [
      access(enabled: false),
      access(platform: TargetPlatform.iOS),
      access(platform: TargetPlatform.windows),
    ]) {
      await expectLater(value.pick(), throwsA(isA<ApiError>()));
      value.dispose();
    }
    expect(calls, 0);
  });
  test(
    'selecting obtains bounded immutable bytes, never paths or filenames',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pick');
        expect(call.arguments, {'operationId': operation});
        return Uint8List.fromList([1, 2, 3]);
      });
      final value = access();
      addTearDown(value.dispose);
      final selected = await value.pick();
      expect(selected!.bytes, [1, 2, 3]);
      expect(() => selected.bytes[0] = 9, throwsUnsupportedError);
    },
  );
  test(
    'OS cancellation returns absence rather than a successful selection',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      final value = access();
      addTearDown(value.dispose);
      expect(await value.pick(), isNull);
    },
  );
  test(
    'private photo requests image-only native selection and keeps bounded immutable bytes',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pickImage');
        expect(call.arguments, {'operationId': operation});
        return Uint8List.fromList([1, 2, 3]);
      });
      final value = access();
      addTearDown(value.dispose);
      final bytes = await value.pickImage();
      expect(bytes, [1, 2, 3]);
      expect(() => bytes![0] = 9, throwsUnsupportedError);
    },
  );
  test(
    'invalid or oversized native selections cannot become a draft',
    () async {
      for (final result in [
        <String, dynamic>{'path': '/private/source.pdf'},
        Uint8List(0),
        Uint8List(institutionEvidenceLimit + 1),
      ]) {
        messenger.setMockMethodCallHandler(channel, (call) async => result);
        final value = access();
        await expectLater(
          value.pick(),
          throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        );
        value.dispose();
      }
    },
  );
  test('account replacement discards a late native selection', () async {
    var current = true;
    final result = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (call) => result.future);
    final value = access(current: () => current);
    addTearDown(value.dispose);
    final pending = value.pick();
    await Future<void>.delayed(Duration.zero);
    current = false;
    result.complete(Uint8List.fromList([1, 2, 3]));
    await expectLater(
      pending,
      throwsA(isA<ApiError>().having((e) => e.code, 'code', 'session_changed')),
    );
  });
  test('only one native operation can be pending per owner facade', () async {
    var calls = 0;
    final result = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (call) {
      calls++;
      return result.future;
    });
    final value = access();
    addTearDown(value.dispose);
    final pending = value.pick();
    await Future<void>.delayed(Duration.zero);
    await expectLater(value.pick(), throwsA(isA<ApiError>()));
    expect(calls, 1);
    result.complete(null);
    await pending;
  });
  test(
    'disposing cancels only its own token and rejects the late result',
    () async {
      final result = Completer<Object?>(), cancelled = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) {
        if (call.method == 'pick') return result.future;
        expect(call.method, 'cancel');
        expect(call.arguments, {'operationId': operation});
        cancelled.complete();
        result.complete(null);
        return Future.value(true);
      });
      final value = access();
      final pending = value.pick();
      await Future<void>.delayed(Duration.zero);
      value.dispose();
      await expectLater(pending, throwsA(isA<ApiError>()));
      await cancelled.future;
    },
  );
  test(
    'export requires consent and sends only fixed MIME, token and bounded bytes',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        expect(call.method, 'export');
        final fields = call.arguments as Map;
        expect(fields.keys.toSet(), {'operationId', 'mime', 'bytes'});
        expect(fields['operationId'], operation);
        expect(fields['mime'], 'application/pdf');
        expect(fields['bytes'], '%PDF-'.codeUnits);
        return true;
      });
      final value = access();
      addTearDown(value.dispose);
      final bytes = Uint8List.fromList('%PDF-'.codeUnits);
      expect(
        await value.exportFile(metadata(), bytes, confirmed: false),
        isFalse,
      );
      expect(calls, 0);
      expect(
        await value.exportFile(metadata(), bytes, confirmed: true),
        isTrue,
      );
      expect(calls, 1);
    },
  );
  test(
    'cancelled save is not a successful export and ambiguous write remains unconfirmed',
    () async {
      final value = access();
      addTearDown(value.dispose);
      final bytes = Uint8List.fromList('%PDF-'.codeUnits);
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      expect(
        await value.exportFile(metadata(), bytes, confirmed: true),
        isFalse,
      );
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(
          code: 'DOCUMENT_EXPORT_UNCONFIRMED',
          message: 'sensitive provider URI',
        ),
      );
      await expectLater(
        value.exportFile(metadata(), bytes, confirmed: true),
        throwsA(
          isA<ApiError>().having(
            (e) => e.message,
            'safe message',
            allOf(contains('parcial'), isNot(contains('sensitive'))),
          ),
        ),
      );
    },
  );
  test('bad export size is rejected before opening a destination', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return true;
    });
    final value = access();
    addTearDown(value.dispose);
    await expectLater(
      value.exportFile(metadata(), Uint8List(6), confirmed: true),
      throwsArgumentError,
    );
    expect(calls, 0);
  });
}
