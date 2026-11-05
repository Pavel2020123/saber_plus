import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/data/private_institution_evidence_repository.dart';

const request = 'd9ac5e51-de18-46ce-b596-b62a97d1ac91';
const id = 'e902e956-dbb5-4c91-ae4f-425ee6bc7db8';
const operation = '3bfc090f-9aa3-45ad-9f20-23dad1b41475';
Map<String, dynamic> receipt([Map<String, dynamic> extra = const {}]) => {
  'id': id,
  'operacionId': operation,
  'estado': 'ACTIVO',
  'revision': 2,
  'mime': 'application/pdf',
  'bytes': 3,
  'disponible': true,
  'limpiezaPendiente': false,
  'contenido': institutionEvidencePath(request, id),
  'venceEn': null,
  ...extra,
};
Map<String, dynamic> listing([List<Object?>? rows]) => {
  'revision': 2,
  'puedeAdjuntar': true,
  'adjuntos': rows ?? [receipt()],
};
void main() {
  Dio client(void Function(RequestOptions, RequestInterceptorHandler) handler) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: handler));
    addTearDown(() => dio.close(force: true));
    return dio;
  }

  void reply(
    RequestOptions options,
    RequestInterceptorHandler handler,
    Object data,
  ) => handler.resolve(Response<Object>(requestOptions: options, data: data));
  RemotePrivateInstitutionEvidenceRepository repository(
    Dio dio, [
    bool Function()? current,
  ]) {
    final repo = RemotePrivateInstitutionEvidenceRepository(
      dio,
      request,
      isCurrent: current ?? () => true,
    );
    addTearDown(repo.dispose);
    return repo;
  }

  test(
    'metadata is canonical, typed, immutable and does not authorize from device time',
    () {
      final file = InstitutionEvidenceFile.fromJson(
        receipt({'venceEn': '2020-01-01T00:00:00.000Z'}),
        request,
      );
      expect(file.available, isTrue); // Only the server grants current access.
      expect(file.expiresAt!.isUtc, isTrue);
      final list = InstitutionEvidenceList.fromJson(listing(), request);
      expect(list.files.single.id, id);
      expect(() => list.files.clear(), throwsUnsupportedError);
    },
  );
  for (final extra in [
    {'id': '../escape'},
    {'operacionId': 'bad'},
    {'revision': 0},
    {'revision': 1.0},
    {'bytes': institutionEvidenceLimit + 1},
    {'mime': 'text/html'},
    {'estado': 'OTHER'},
    {'contenido': 'https://example.invalid/document.pdf'},
    {'disponible': false},
    {'limpiezaPendiente': true},
    {'venceEn': '2026-02-31T00:00:00.000Z'},
  ]) {
    test('rejects malformed private receipt ${extra.keys.join(',')}', () {
      expect(
        () => InstitutionEvidenceFile.fromJson(receipt(extra), request),
        throwsFormatException,
      );
    });
  }
  test('lists reject duplicate, unavailable, stale or missing files', () {
    for (final value in [
      listing([receipt(), receipt()]),
      listing([
        receipt({'revision': 3}),
      ]),
      listing([null]),
      listing([
        receipt({'estado': 'RETIRADO', 'disponible': false, 'contenido': null}),
      ]),
    ]) {
      expect(
        () => InstitutionEvidenceList.fromJson(value, request),
        throwsFormatException,
      );
    }
    expect(
      () => InstitutionEvidenceList.fromJson(listing([]), 'bad'),
      throwsArgumentError,
    );
  });
  test('draft checks size before copying and retry bytes are immutable', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final draft = InstitutionEvidenceDraft(source);
    source[0] = 9;
    expect(draft.bytes, [1, 2, 3]);
    expect(() => draft.bytes[0] = 4, throwsUnsupportedError);
    expect(() => InstitutionEvidenceDraft(Uint8List(0)), throwsArgumentError);
    expect(
      () => InstitutionEvidenceDraft(Uint8List(institutionEvidenceLimit + 1)),
      throwsArgumentError,
    );
  });
  test(
    'load and upload use the exact verification route, bounded multipart and no owner/name fields',
    () async {
      var count = 0;
      final repo = repository(
        client((options, handler) {
          expect(options.path, institutionEvidencePath(request));
          expect(options.cancelToken, isNotNull);
          count++;
          if (options.method == 'GET') {
            reply(options, handler, listing());
          } else {
            expect(options.method, 'POST');
            final body = options.data as FormData;
            expect(Map.fromEntries(body.fields), {
              'operacionId': operation,
              'revision': '1',
            });
            expect(body.files.single.key, 'archivo');
            expect(body.files.single.value.filename, 'documento');
            reply(options, handler, receipt());
          }
        }),
      );
      expect((await repo.load()).files.single.id, id);
      expect(
        (await repo.upload(
          operation,
          1,
          InstitutionEvidenceDraft(Uint8List.fromList([1, 2, 3])),
        )).id,
        id,
      );
      expect(count, 2);
    },
  );
  test(
    'operation receipt does not become a new upload and 404 stays unconfirmed',
    () async {
      final repo = repository(
        client((options, handler) {
          expect(
            options.path,
            '${institutionEvidencePath(request)}/operaciones/$operation',
          );
          expect(options.method, 'GET');
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Object>(
                requestOptions: options,
                statusCode: 404,
                data: {'message': 'Not found'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        }),
      );
      await expectLater(repo.operation(operation), throwsA(isA<ApiError>()));
    },
  );
  test(
    'wrong operation acknowledgement or active deletion receipt is rejected',
    () async {
      final repo = repository(
        client(
          (options, handler) =>
              reply(options, handler, receipt({'operacionId': id})),
        ),
      );
      await expectLater(repo.operation(operation), throwsFormatException);
      await expectLater(repo.remove(id, 2), throwsFormatException);
    },
  );
  test(
    'deletion binds exact file and expected revision and confirms retirement',
    () async {
      final repo = repository(
        client((options, handler) {
          expect(options.path, institutionEvidencePath(request, id));
          expect(options.method, 'DELETE');
          expect(options.data, {'revision': 2});
          reply(
            options,
            handler,
            receipt({
              'estado': 'RETIRADO',
              'disponible': false,
              'contenido': null,
              'limpiezaPendiente': true,
            }),
          );
        }),
      );
      expect((await repo.remove(id, 2)).cleanupPending, isTrue);
    },
  );
  test(
    'private bytes are streamed and checked against immutable metadata',
    () async {
      final repo = repository(
        client((options, handler) {
          expect(options.path, institutionEvidencePath(request, id));
          expect(options.responseType, ResponseType.stream);
          expect(options.headers['Accept'], 'application/pdf,image/webp');
          reply(
            options,
            handler,
            ResponseBody.fromBytes(
              [1, 2, 3],
              200,
              headers: {
                'content-type': ['application/pdf'],
                'content-length': ['3'],
              },
            ),
          );
        }),
      );
      expect(
        await repo.content(
          InstitutionEvidenceFile.fromJson(receipt(), request),
        ),
        [1, 2, 3],
      );
    },
  );
  for (final scenario in ['mime', 'declared', 'streamed', 'short']) {
    test('rejects private download $scenario mismatch', () async {
      final repo = repository(
        client(
          (options, handler) => reply(
            options,
            handler,
            ResponseBody.fromBytes(
              scenario == 'streamed'
                  ? [1, 2, 3, 4]
                  : scenario == 'short'
                  ? [1]
                  : [1, 2, 3],
              200,
              headers: {
                'content-type': [
                  scenario == 'mime' ? 'text/html' : 'application/pdf',
                ],
                if (scenario == 'declared') 'content-length': ['999999999999'],
              },
            ),
          ),
        ),
      );
      await expectLater(
        repo.content(InstitutionEvidenceFile.fromJson(receipt(), request)),
        throwsFormatException,
      );
    });
  }
  test(
    'account switch before or after response cannot expose another owner data',
    () async {
      var current = false, calls = 0;
      final done = Completer<void>();
      final repo = repository(
        client((options, handler) async {
          calls++;
          await done.future;
          reply(options, handler, listing());
        }),
        () => current,
      );
      await expectLater(repo.load(), throwsA(isA<ApiError>()));
      expect(calls, 0);
      current = true;
      final pending = repo.load();
      await Future<void>.delayed(Duration.zero);
      current = false;
      done.complete();
      await expectLater(pending, throwsA(isA<ApiError>()));
      expect(calls, 1);
    },
  );
  test(
    'identity change during streaming cancels before exposing the next chunk',
    () async {
      var current = true, cancelled = false;
      final source = StreamController<Uint8List>(
        onCancel: () {
          cancelled = true;
        },
      );
      addTearDown(source.close);
      final repo = repository(
        client(
          (options, handler) => reply(
            options,
            handler,
            ResponseBody(
              source.stream,
              200,
              headers: {
                'content-type': ['application/pdf'],
              },
            ),
          ),
        ),
        () => current,
      );
      final pending = repo.content(
        InstitutionEvidenceFile.fromJson(receipt(), request),
      );
      await Future<void>.delayed(Duration.zero);
      source.add(Uint8List.fromList([1]));
      await Future<void>.delayed(Duration.zero);
      current = false;
      source.add(Uint8List.fromList([2, 3]));
      await expectLater(pending, throwsA(isA<ApiError>()));
      expect(cancelled, isTrue);
    },
  );
  test(
    'dispose blocks this repository without closing shared authenticated Dio',
    () async {
      final dio = client(
        (options, handler) => reply(options, handler, listing()),
      );
      final repo = repository(dio);
      repo.dispose();
      await expectLater(repo.load(), throwsA(isA<ApiError>()));
      expect((await dio.get<Object?>('/unrelated')).data, isNotNull);
    },
  );
}
