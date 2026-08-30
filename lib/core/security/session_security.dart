import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionSecurityEvent {
  const SessionSecurityEvent({required this.code, required this.message});

  final String code;
  final String message;
}

class SessionSecurityController extends Notifier<SessionSecurityEvent?> {
  @override
  SessionSecurityEvent? build() => null;

  void report(SessionSecurityEvent event) => state = event;

  void clear() => state = null;
}

final sessionSecurityProvider =
    NotifierProvider<SessionSecurityController, SessionSecurityEvent?>(
      SessionSecurityController.new,
    );

class SessionSecurityInterceptor extends Interceptor {
  SessionSecurityInterceptor(this._onConflict);

  final void Function(SessionSecurityEvent event) _onConflict;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final event = parseSessionSecurityEvent(err.response?.data);
    if (event != null) _onConflict(event);
    handler.next(err);
  }
}

SessionSecurityEvent? parseSessionSecurityEvent(Object? body) {
  const conflictCodes = {
    'SESSION_REPLACED',
    'DEVICE_SESSION_CONFLICT',
    'SINGLE_DEVICE_SESSION',
    'SESION_REEMPLAZADA',
    'SESION_OTRO_DISPOSITIVO',
  };
  final json = body is Map ? Map<String, dynamic>.from(body) : const {};
  final rawCode = json['code'] ?? json['codigo'];
  final code = rawCode?.toString().trim().toUpperCase();
  if (code == null || !conflictCodes.contains(code)) return null;
  return SessionSecurityEvent(
    code: code,
    message:
        'Tu sesión se abrió en otro dispositivo. Por seguridad, vuelve a iniciar sesión aquí.',
  );
}
