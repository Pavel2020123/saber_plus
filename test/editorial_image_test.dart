import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/core/media/editorial_image_reference.dart';
import 'package:saber_plus/core/media/remote_editorial_image_repository.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/api_client.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';

const path = '/recursos/editoriales/a6ec3648-24ee-47d0-91f8-e59b2b68b9ab';
final webp = base64Decode(
  'UklGRlgAAABXRUJQVlA4IEwAAADwBACdASp4ADwAPm02mUmkIyKhIQgAgA2JaQB2APwAABPPNPcaiVea2vp06dOnRwAA/us2///1aHy0Plofuff//mCV+QbrkAAAAAAA',
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body({
  List<int>? bytes,
  int status = 200,
  String type = 'image/webp',
  String? length,
}) => ResponseBody.fromBytes(
  bytes ?? webp,
  status,
  headers: {
    Headers.contentTypeHeader: [type],
    if (length != null) Headers.contentLengthHeader: [length],
  },
);

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'a', firstName: 'Ensayo', role: AppRole.student),
  );
  void change(String? id, {bool demo = false}) {
    state = id == null
        ? const SessionState.unauthenticated()
        : SessionState.authenticated(
            UserSession(
              id: id,
              firstName: 'Ensayo',
              role: AppRole.student,
              isDemo: demo,
            ),
          );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late AccessTokenStore tokens;
  late RemoteEditorialImageRepository repository;
  setUp(() {
    tokens = AccessTokenStore()..set('synthetic-test-token');
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'));
    dio.interceptors.add(AuthInterceptor(tokens));
    repository = RemoteEditorialImageRepository(dio, tokens);
  });
  tearDown(() => dio.close(force: true));

  test('acepta referencia UUID4 exacta y normaliza mayúsculas', () {
    expect(EditorialImageReference.parse(path).path, path);
    expect(EditorialImageReference.parse(path.toUpperCase()).path, path);
  });
  for (final invalid in [
    'https://evil.invalid$path',
    '//$path',
    '$path?token=x',
    '$path#fragment',
    '$path/../otro',
    path.replaceFirst('-47d0-', '-17d0-'),
    path.replaceFirst('/recursos/', '/admin/'),
    ' $path',
  ]) {
    test('rechaza referencia ambigua: $invalid', () {
      expect(
        () => EditorialImageReference.parse(invalid),
        throwsFormatException,
      );
    });
  }

  test('envía Bearer solo a API y exige WEBP, sin redirecciones', () async {
    final adapter = _Adapter((o) async => body(length: '${webp.length}'));
    dio.httpClientAdapter = adapter;
    expect(
      await repository.load(
        EditorialImageReference.parse(path),
        cancelToken: CancelToken(),
      ),
      webp,
    );
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://api.example.invalid$path');
    expect(request.followRedirects, isFalse);
    expect(request.headers['Authorization'], 'Bearer synthetic-test-token');
    expect(request.headers['Accept'], 'image/webp');
    expect(request.queryParameters, isEmpty);
  });

  test('sin sesión no llega al transporte', () async {
    tokens.clear();
    final adapter = _Adapter((_) async => body());
    dio.httpClientAdapter = adapter;
    await expectLater(
      repository.load(
        EditorialImageReference.parse(path),
        cancelToken: CancelToken(),
      ),
      throwsStateError,
    );
    expect(adapter.requests, isEmpty);
  });
  for (final invalid in [
    body(type: 'text/html'),
    body(bytes: [1, 2, 3]),
    body(bytes: Uint8List(30)),
    body(length: '0'),
    body(length: 'not-a-number'),
    body(length: '${RemoteEditorialImageRepository.maxBytes + 1}'),
    body(length: '${webp.length + 1}'),
  ]) {
    test(
      'rechaza bytes, MIME o tamaño no válidos ${invalid.headers}',
      () async {
        dio.httpClientAdapter = _Adapter((_) async => invalid);
        await expectLater(
          repository.load(
            EditorialImageReference.parse(path),
            cancelToken: CancelToken(),
          ),
          throwsFormatException,
        );
      },
    );
  }
  for (final status in [302, 401, 403, 404, 503]) {
    test('no oculta error HTTP $status', () async {
      dio.httpClientAdapter = _Adapter((_) async => body(status: status));
      await expectLater(
        repository.load(
          EditorialImageReference.parse(path),
          cancelToken: CancelToken(),
        ),
        throwsA(isA<DioException>()),
      );
    });
  }
  test('corta stream que supera 2 MiB sin Content-Length', () async {
    var cancelled = false;
    final stream = StreamController<Uint8List>(
      onCancel: () {
        cancelled = true;
      },
    );
    dio.httpClientAdapter = _Adapter((_) async {
      scheduleMicrotask(() {
        stream.add(Uint8List(RemoteEditorialImageRepository.maxBytes));
        stream.add(Uint8List(1));
      });
      return ResponseBody(
        stream.stream,
        200,
        headers: {
          Headers.contentTypeHeader: ['image/webp'],
        },
      );
    });
    await expectLater(
      repository.load(
        EditorialImageReference.parse(path),
        cancelToken: CancelToken(),
      ),
      throwsFormatException,
    );
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
    await stream.close();
  });
  test('descarta respuesta de una cuenta anterior', () async {
    dio.httpClientAdapter = _Adapter((_) async {
      tokens.set('another-synthetic-token');
      return body();
    });
    await expectLater(
      repository.load(
        EditorialImageReference.parse(path),
        cancelToken: CancelToken(),
      ),
      throwsA(anyOf(isA<StateError>(), isA<DioException>())),
    );
  });
  test('descarta stream al cerrar sesión en mitad de la descarga', () async {
    final stream = StreamController<Uint8List>();
    dio.httpClientAdapter = _Adapter((_) async {
      scheduleMicrotask(() {
        tokens.clear();
        stream.add(webp);
        unawaited(stream.close());
      });
      return ResponseBody(
        stream.stream,
        200,
        headers: {
          Headers.contentTypeHeader: ['image/webp'],
        },
      );
    });
    await expectLater(
      repository.load(
        EditorialImageReference.parse(path),
        cancelToken: CancelToken(),
      ),
      throwsA(anyOf(isA<StateError>(), isA<DioException>())),
    );
  });

  Future<ProviderContainer> showImage(
    WidgetTester tester,
    _Adapter adapter, {
    bool demo = false,
  }) async {
    dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(_Session.new),
        accessTokenStoreProvider.overrideWithValue(tokens),
        dioProvider.overrideWithValue(dio),
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: AppEnvironment.prod,
            apiBaseUrl: 'https://api.example.invalid',
            demoMode: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (demo) {
      (container.read(sessionControllerProvider.notifier) as _Session).change(
        'demo',
        demo: true,
      );
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: AcademicImage(
              value: path,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  Future<void> finishDecode(WidgetTester tester) async {
    // Engine codec work completes outside FakeAsync; pump queued Dio/provider
    // microtasks before allowing the real engine completion to reach the UI.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('imagen privada conserva proporción y no entra en ImageCache', (
    tester,
  ) async {
    final cached = PaintingBinding.instance.imageCache.currentSize;
    final adapter = _Adapter((_) async => body());
    await showImage(tester, adapter);
    await finishDecode(tester);
    final state = ProviderScope.containerOf(
      tester.element(find.byType(AcademicImage)),
    ).read(editorialImageProvider(path));
    expect(state.hasError, isFalse, reason: '${state.error}');
    final raw = tester.widget<RawImage>(find.byType(RawImage));
    expect(raw.image!.width, 120);
    expect(raw.image!.height, 60);
    expect(raw.fit, BoxFit.contain);
    final clip = tester.widget<ClipRRect>(
      find.ancestor(
        of: find.byType(RawImage),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, BorderRadius.circular(16));
    expect(find.byType(Image), findsNothing);
    expect(PaintingBinding.instance.imageCache.currentSize, cached);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('error visible permite reintento explícito', (tester) async {
    var fail = true;
    final adapter = _Adapter((_) async => fail ? body(status: 503) : body());
    await showImage(tester, adapter);
    await tester.pumpAndSettle();
    expect(find.text('Reintentar imagen'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.textContaining('Imagen del contenido: no se pudo cargar.'),
        matching: find.byType(ClipRRect),
      ),
      findsNothing,
    );
    fail = false;
    await tester.tap(find.text('Reintentar imagen'));
    await finishDecode(tester);
    expect(find.byType(RawImage), findsOneWidget);
    expect(adapter.requests, hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('aviso sin recorte cabe en 320 px con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorialImageProvider(path).overrideWith((ref) async {
            throw StateError('Sin conexión de ensayo');
          }),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AcademicImage(
                  value: path,
                  label: 'Imagen de la lección',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = find.textContaining(
      'Imagen de la lección: no se pudo cargar.',
    );
    expect(text, findsOneWidget);
    expect(
      find.ancestor(of: text, matching: find.byType(ClipRRect)),
      findsNothing,
    );
    expect(tester.getRect(text).left, greaterThanOrEqualTo(20));
    expect(tester.getRect(text).right, lessThanOrEqualTo(300));
    expect(find.text('Reintentar imagen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('logout retira imagen privada y no conserva datos anteriores', (
    tester,
  ) async {
    final adapter = _Adapter((_) async => body());
    final container = await showImage(tester, adapter);
    await finishDecode(tester);
    expect(find.byType(RawImage), findsOneWidget);
    tokens.clear();
    (container.read(sessionControllerProvider.notifier) as _Session).change(
      null,
    );
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsNothing);
    expect(find.text('Reintentar imagen'), findsOneWidget);
    expect(adapter.requests, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('demo no descarga recurso privado', (tester) async {
    final adapter = _Adapter((_) async => body());
    await showImage(tester, adapter, demo: true);
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsNothing);
    expect(adapter.requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
