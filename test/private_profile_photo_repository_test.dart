import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/profile/domain/private_profile_photo.dart';
import 'package:saber_plus/features/profile/data/remote_private_profile_photo_repository.dart';

const id = '2df4f385-fec2-4cb1-89af-91f67a476b52';
const operation = '3df4f385-fec2-4cb1-89af-91f67a476b52';
Map<String, dynamic> photo({String? fileId = id, int revision = 1}) => {
  'revision': revision,
  'archivoId': fileId,
  'contenido': fileId == null ? null : '/cuenta/archivos/foto/$fileId',
};
Map<String, dynamic> receipt() => {
  'id': id,
  'operacionId': operation,
  'estado': 'ACTIVO',
  'foto': photo(),
  'limpiezaPendiente': false,
};

void main() {
  test('validates private self path and empty profile', () {
    expect(PrivateProfilePhoto.fromJson(photo()).fileId, id);
    expect(
      PrivateProfilePhoto.fromJson(photo(fileId: null, revision: 0)).fileId,
      isNull,
    );
  });
  for (final value in [
    {...photo(), 'contenido': 'https://example.invalid/photo'},
    {...photo(), 'contenido': '/cuenta/archivos/foto/$id?token=secret'},
    {...photo(), 'revision': -1},
    {...photo(), 'revision': 1.0},
    {...photo(), 'archivoId': '../outside'},
    {...photo(fileId: null), 'contenido': '/cuenta/archivos/foto/$id'},
    <String, dynamic>{'revision': 0},
  ]) {
    test(
      'rejects invalid or externally addressed private profile ${value.keys.join(',')}',
      () {
        expect(
          () => PrivateProfilePhoto.fromJson(value),
          throwsFormatException,
        );
      },
    );
  }
  test('rejects inconsistent active receipts and unknown states', () {
    expect(
      () => PrivatePhotoReceipt.fromJson({...receipt(), 'estado': 'OTHER'}),
      throwsFormatException,
    );
    expect(
      () => PrivatePhotoReceipt.fromJson({
        ...receipt(),
        'limpiezaPendiente': true,
      }),
      throwsFormatException,
    );
    expect(
      () => PrivatePhotoReceipt.fromJson({
        ...receipt(),
        'foto': photo(fileId: null),
      }),
      throwsFormatException,
    );
  });

  Dio client(void Function(RequestOptions, RequestInterceptorHandler) handler) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: handler));
    addTearDown(() => dio.close(force: true));
    return dio;
  }

  void resolve(
    RequestOptions options,
    RequestInterceptorHandler handler,
    Object data, {
    Headers? headers,
  }) {
    handler.resolve(
      Response<Object>(requestOptions: options, data: data, headers: headers),
    );
  }

  test(
    'uploads one bounded file with only operation and expected revision',
    () async {
      final dio = client((options, handler) {
        expect(options.method, 'POST');
        expect(options.path, '/cuenta/archivos/foto');
        final data = options.data as FormData;
        expect(Map.fromEntries(data.fields), {
          'operacionId': operation,
          'revision': '0',
        });
        expect(data.files.single.key, 'archivo');
        expect(data.files.single.value.filename, 'foto');
        expect(options.cancelToken, isNotNull);
        resolve(options, handler, receipt());
      });
      final repository = RemotePrivateProfilePhotoRepository(dio);
      addTearDown(repository.dispose);
      expect(
        (await repository.upload(
          operation,
          0,
          Uint8List.fromList([1, 2, 3]),
        )).id,
        id,
      );
    },
  );

  test('rejects wrong operation acknowledgement', () async {
    final dio = client(
      (options, handler) =>
          resolve(options, handler, {...receipt(), 'operacionId': id}),
    );
    final repository = RemotePrivateProfilePhotoRepository(dio);
    addTearDown(repository.dispose);
    await expectLater(repository.operation(operation), throwsFormatException);
  });

  test(
    'reads bounded private bytes through authenticated Dio, not an external URL',
    () async {
      final dio = client((options, handler) {
        expect(options.path, '/cuenta/archivos/foto/$id');
        expect(options.responseType, ResponseType.stream);
        resolve(
          options,
          handler,
          ResponseBody.fromBytes(
            [1, 2, 3],
            200,
            headers: {
              'content-type': ['image/webp'],
              'content-length': ['3'],
            },
          ),
          headers: Headers.fromMap({
            'content-type': ['image/webp'],
            'content-length': ['3'],
          }),
        );
      });
      final repository = RemotePrivateProfilePhotoRepository(dio);
      addTearDown(repository.dispose);
      expect(await repository.content(PrivateProfilePhoto.fromJson(photo())), [
        1,
        2,
        3,
      ]);
    },
  );

  test(
    'rejects streamed excess without trusting an absent content length',
    () async {
      final dio = client(
        (options, handler) => resolve(
          options,
          handler,
          ResponseBody.fromBytes(
            Uint8List(200 * 1024 + 1),
            200,
            headers: {
              'content-type': ['image/webp'],
            },
          ),
          headers: Headers.fromMap({
            'content-type': ['image/webp'],
          }),
        ),
      );
      final repository = RemotePrivateProfilePhotoRepository(dio);
      addTearDown(repository.dispose);
      await expectLater(
        repository.content(PrivateProfilePhoto.fromJson(photo())),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects an HTML response and cannot claim successful removal with a photo',
    () async {
      final dio = client((options, handler) {
        if (options.method == 'DELETE') {
          resolve(options, handler, {
            'foto': photo(),
            'limpiezaPendiente': false,
          });
        } else {
          resolve(
            options,
            handler,
            ResponseBody.fromBytes(
              [1],
              200,
              headers: {
                'content-type': ['text/html'],
              },
            ),
            headers: Headers.fromMap({
              'content-type': ['text/html'],
            }),
          );
        }
      });
      final repository = RemotePrivateProfilePhotoRepository(dio);
      addTearDown(repository.dispose);
      await expectLater(
        repository.content(PrivateProfilePhoto.fromJson(photo())),
        throwsFormatException,
      );
      await expectLater(repository.remove(1), throwsFormatException);
    },
  );

  test('bad upload input makes no network request', () async {
    var requests = 0;
    final dio = client((options, handler) {
      requests++;
      handler.reject(DioException(requestOptions: options));
    });
    final repository = RemotePrivateProfilePhotoRepository(dio);
    addTearDown(repository.dispose);
    await expectLater(
      repository.upload(operation, 0, Uint8List(0)),
      throwsArgumentError,
    );
    await expectLater(
      repository.upload(operation, 0, Uint8List(5 * 1024 * 1024 + 1)),
      throwsArgumentError,
    );
    await expectLater(repository.operation('../other'), throwsArgumentError);
    expect(requests, 0);
  });
}
