import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../domain/tug_online_models.dart';

sealed class TugRealtimeEvent {
  const TugRealtimeEvent();
}

class TugRealtimeConnected extends TugRealtimeEvent {
  const TugRealtimeConnected({this.partidaId, this.version});

  final String? partidaId;
  final int? version;
}

class TugRealtimeDisconnected extends TugRealtimeEvent {
  const TugRealtimeDisconnected();
}

class TugRealtimeUpdated extends TugRealtimeEvent {
  const TugRealtimeUpdated(this.partidaId);

  final String partidaId;
}

class TugRealtimePresence extends TugRealtimeEvent {
  const TugRealtimePresence({required this.userId, required this.connected});

  final String userId;
  final bool connected;
}

class TugRealtimeState extends TugRealtimeEvent {
  const TugRealtimeState(this.snapshot);

  final TugOnlineSnapshot snapshot;
}

class TugRealtimeFailure extends TugRealtimeEvent {
  const TugRealtimeFailure({required this.code, required this.message});

  final String code;
  final String message;
}

abstract interface class TugRealtimeClient {
  Stream<TugRealtimeEvent> get events;

  void connect();

  Future<void> matchmake(AcademicArea? area);

  Future<void> synchronize(String matchId, {int? sinceVersion});

  Future<void> ready(String matchId);

  Future<void> answer({
    required String matchId,
    required int round,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  });

  Future<void> abandon(String matchId);

  void dispose();
}

class SocketTugRealtimeClient implements TugRealtimeClient {
  SocketTugRealtimeClient(
    this._dio, {
    required String apiBaseUrl,
    required String accessToken,
  }) : _accessToken = accessToken,
       _socket = io.io(
         '$apiBaseUrl/tira-afloja',
         io.OptionBuilder()
             .setTransports(['websocket'])
             .disableAutoConnect()
             .enableForceNew()
             .setAuth({'token': accessToken})
             .enableReconnection()
             .setReconnectionAttempts(20)
             .setReconnectionDelay(700)
             .setReconnectionDelayMax(5000)
             .build(),
       ) {
    _bindEvents();
  }

  final String _accessToken;
  final Dio _dio;
  final io.Socket _socket;
  final _controller = StreamController<TugRealtimeEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<TugRealtimeEvent> get events => _controller.stream;

  @override
  void connect() {
    if (_disposed) return;
    if (_accessToken.isEmpty) {
      _add(
        const TugRealtimeFailure(
          code: 'NO_SESSION',
          message: 'Inicia sesión con una cuenta real para jugar en línea.',
        ),
      );
      return;
    }
    _socket.connect();
  }

  @override
  Future<void> matchmake(AcademicArea? area) {
    final data = {if (area case final selected?) 'area': selected.backendValue};
    return _send(
      'tira:emparejar',
      data,
      () => _dio.post<Object>('/tira-afloja/emparejamiento', data: data),
    );
  }

  @override
  Future<void> synchronize(String matchId, {int? sinceVersion}) {
    final data = {'partidaId': matchId, 'desdeVersion': ?sinceVersion};
    return _send(
      'tira:sincronizar',
      data,
      () => _dio.get<Object>(
        '/tira-afloja/$matchId',
        queryParameters: {'desdeVersion': ?sinceVersion},
      ),
    );
  }

  @override
  Future<void> ready(String matchId) {
    final data = {'partidaId': matchId};
    return _send(
      'tira:listo',
      data,
      () => _dio.post<Object>('/tira-afloja/$matchId/listo'),
    );
  }

  @override
  Future<void> answer({
    required String matchId,
    required int round,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) {
    final data = {
      'partidaId': matchId,
      'ronda': round,
      'preguntaId': questionId,
      'respuestaId': answerId,
      'idempotencyKey': idempotencyKey,
    };
    return _send(
      'tira:responder',
      data,
      () => _dio.post<Object>(
        '/tira-afloja/$matchId/respuestas',
        data: {
          'ronda': round,
          'preguntaId': questionId,
          'respuestaId': answerId,
          'idempotencyKey': idempotencyKey,
        },
      ),
    );
  }

  @override
  Future<void> abandon(String matchId) {
    final data = {'partidaId': matchId};
    return _send(
      'tira:abandonar',
      data,
      () => _dio.post<Object>('/tira-afloja/$matchId/abandonar'),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _socket.dispose();
    unawaited(_controller.close());
  }

  void _bindEvents() {
    _socket.onDisconnect((_) => _add(const TugRealtimeDisconnected()));
    _socket.onConnectError((error) {
      _add(
        TugRealtimeFailure(
          code: 'CONNECTION_ERROR',
          message: 'No pudimos conectar con la partida en línea.',
        ),
      );
    });
    _socket.on('tira:conectado', (data) {
      final json = _map(data);
      _add(
        TugRealtimeConnected(
          partidaId: json['partidaId'] as String?,
          version: json['version'] as int?,
        ),
      );
    });
    _socket.on('tira:estado', (data) {
      try {
        _add(TugRealtimeState(TugOnlineSnapshot.fromJson(_map(data))));
      } on Object {
        _add(
          const TugRealtimeFailure(
            code: 'INVALID_STATE',
            message: 'El servidor envió un estado de partida inválido.',
          ),
        );
      }
    });
    _socket.on('tira:actualizada', (data) {
      final json = _map(data);
      final matchId = json['partidaId'];
      if (matchId is String) _add(TugRealtimeUpdated(matchId));
    });
    _socket.on('tira:presencia', (data) {
      final json = _map(data);
      final userId = json['usuarioId'];
      final connected = json['conectado'];
      if (userId is String && connected is bool) {
        _add(TugRealtimePresence(userId: userId, connected: connected));
      }
    });
    _socket.on('tira:error', (data) {
      final json = _map(data);
      _add(
        TugRealtimeFailure(
          code: json['codigo'] as String? ?? 'REALTIME_ERROR',
          message:
              json['mensaje'] as String? ??
              'No fue posible completar la acción.',
        ),
      );
    });
  }

  Future<void> _emit(String event, Map<String, dynamic> data) async {
    final completer = Completer<void>();
    _socket.emitWithAck(
      event,
      data,
      ack: (Object? response) {
        if (completer.isCompleted) return;
        final json = response is Map
            ? Map<String, dynamic>.from(response)
            : null;
        if (json?['ok'] == true || event == 'tira:latido') {
          completer.complete();
        } else {
          completer.completeError(
            const ApiError(
              code: 'invalid_realtime_ack',
              message: 'El servidor no confirmó la acción.',
            ),
          );
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw const ApiError(
        code: 'realtime_timeout',
        message: 'El servidor tardó demasiado en responder.',
      ),
    );
  }

  Future<void> _send(
    String event,
    Map<String, dynamic> data,
    Future<Response<Object>> Function() fallback,
  ) async {
    if (_socket.connected) return _emit(event, data);
    try {
      final response = await fallback();
      _add(TugRealtimeState(TugOnlineSnapshot.fromJson(_map(response.data))));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  void _add(TugRealtimeEvent event) {
    if (!_disposed) _controller.add(event);
  }
}

String createTugIdempotencyKey([Random? source]) {
  final random = source ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
