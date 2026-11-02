import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/session_controller.dart';
import '../config/environment.dart';
import '../network/access_token_store.dart';
import '../network/api_client.dart';
import 'editorial_image_reference.dart';
import 'private_offline_access_policy.dart';

class PrivateLessonUnavailable implements Exception {
  const PrivateLessonUnavailable();
  @override
  String toString() => 'Revalida el contenido privado con conexión.';
}

abstract interface class PrivateLessonVault {
  Future<OfflineClockSample> clock();
  Future<void> seal(
    String owner,
    String context,
    String payload,
    OfflineClockSample anchor,
  );
  Future<({String payload, int remainingMs})?> read(
    String owner,
    String context,
  );
  Future<void> clearContext(String owner, String context);
  Future<void> clearAccount(String owner);
}

class AndroidPrivateLessonVault implements PrivateLessonVault {
  static const channel = MethodChannel('saberplus/private_offline_v1');
  @override
  Future<OfflineClockSample> clock() async {
    final data = await channel.invokeMapMethod<String, dynamic>('clock');
    if (data == null) throw const PrivateLessonUnavailable();
    return OfflineClockSample(
      bootId: data['bootId'] as String,
      elapsed: Duration(milliseconds: data['elapsedMs'] as int),
    );
  }

  Map<String, String> _ids(String owner, String context) => {
    'ownerId': owner,
    'contextId': context,
  };
  @override
  Future<void> seal(
    String owner,
    String context,
    String payload,
    OfflineClockSample anchor,
  ) => channel.invokeMethod('seal', {
    ..._ids(owner, context),
    'payload': payload,
    'anchorMs': anchor.elapsed.inMilliseconds,
    'bootId': anchor.bootId,
  });
  @override
  Future<({String payload, int remainingMs})?> read(
    String owner,
    String context,
  ) async {
    final result = await channel.invokeMapMethod<String, dynamic>(
      'read',
      _ids(owner, context),
    );
    return result == null
        ? null
        : (
            payload: result['payload'] as String,
            remainingMs: result['remainingMs'] as int,
          );
  }

  @override
  Future<void> clearContext(String owner, String context) =>
      channel.invokeMethod('clearContext', _ids(owner, context));
  @override
  Future<void> clearAccount(String owner) =>
      channel.invokeMethod('clearAccount', {'ownerId': owner});
}

class PrivateLessonCopy {
  const PrivateLessonCopy({
    required this.title,
    required this.content,
    required this.image,
    required this.remaining,
    required this.serverValidatedAt,
  });
  final String title;
  final String content;
  final Uint8List? image;
  final Duration remaining;
  final DateTime serverValidatedAt;
}

/// Separate from PDF downloads. Every async result is bound to account/token epoch.
class PrivateLessonCache extends ChangeNotifier {
  PrivateLessonCache(this.dio, this.tokens, this.vault);
  final Dio dio;
  final AccessTokenStore tokens;
  final PrivateLessonVault vault;
  final policy = PrivateOfflineAccessPolicy();
  String? _owner;
  var _generation = 0;
  var _blockedAccount = false;
  final _blockedContexts = <String>{};
  final _requests = <CancelToken>{};
  bool _closed = false;
  int networkRevision = 0;

  void setAccount(String? owner) {
    if (_owner == owner) return;
    final old = _owner;
    _owner = owner;
    _generation++;
    _cancelRequests();
    _blockedAccount = false;
    _blockedContexts.clear();
    policy.changeAccount(owner);
    if (old != null) {
      unawaited(vault.clearAccount(old).catchError((Object _) {}));
    }
    if (!_closed) notifyListeners();
  }

  void _current(String owner, int generation, int revision) {
    if (_closed ||
        _owner != owner ||
        _generation != generation ||
        tokens.revision != revision ||
        tokens.accessToken?.isNotEmpty != true) {
      throw const PrivateLessonUnavailable();
    }
  }

  Future<void> deny(String context, {bool account = false}) async {
    final owner = _owner;
    _generation++;
    _cancelRequests();
    if (account) {
      _blockedAccount = true;
      policy.confirmSuspension();
    } else {
      _blockedContexts.add(context);
      policy.confirmRevocation(context);
    }
    // Clear displayed plaintext BEFORE awaiting native cleanup.
    if (!_closed) notifyListeners();
    if (owner == null) return;
    try {
      if (account) {
        await vault.clearAccount(owner);
      } else {
        await vault.clearContext(owner, context);
      }
    } on Object {
      /* Access remains blocked; cleanup can be retried. */
    }
  }

  ({PrivateOfflineGrant grant, String title, String content, Uint8List? image})
  _parse(Map<String, dynamic> data, String owner, String context) {
    const keys = {
      'policyVersion',
      'ownerId',
      'contextId',
      'requestNonce',
      'validatedAt',
      'expiresAt',
      'contextDigest',
      'snapshot',
    };
    if (data.keys.toSet().difference(keys).isNotEmpty ||
        data['policyVersion'] != 1 ||
        data['ownerId'] != owner ||
        data['contextId'] != context) {
      throw const PrivateLessonUnavailable();
    }
    final grant = PrivateOfflineGrant(
      ownerId: owner,
      contextId: context,
      requestNonce: data['requestNonce'] as String,
      validatedAt: DateTime.parse(data['validatedAt'] as String),
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
    if (!grant.validatedAt.isUtc ||
        !grant.expiresAt.isUtc ||
        grant.expiresAt.difference(grant.validatedAt) !=
            PrivateOfflineAccessPolicy.window ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(grant.requestNonce)) {
      throw const PrivateLessonUnavailable();
    }
    final snapshot = Map<String, dynamic>.from(data['snapshot'] as Map);
    if (snapshot.keys.toSet().difference({
          'title',
          'content',
          'image',
        }).isNotEmpty ||
        sha256.convert(utf8.encode(jsonEncode(snapshot))).toString() !=
            data['contextDigest']) {
      throw const PrivateLessonUnavailable();
    }
    final title = snapshot['title'] as String,
        content = snapshot['content'] as String;
    if (utf8.encode(title).length > 2048 ||
        utf8.encode(content).length > 128 * 1024) {
      throw const PrivateLessonUnavailable();
    }
    Uint8List? image;
    if (snapshot['image'] != null) {
      final meta = Map<String, dynamic>.from(snapshot['image'] as Map);
      EditorialImageReference.parse('/recursos/editoriales/${meta['id']}');
      if (meta.keys.toSet().difference({
            'id',
            'sha256',
            'mime',
            'byteSize',
            'base64',
          }).isNotEmpty ||
          meta['mime'] != 'image/webp') {
        throw const PrivateLessonUnavailable();
      }
      image = base64Decode(meta['base64'] as String);
      if (image.length < 12 ||
          image.length > 2 * 1024 * 1024 ||
          image.length != meta['byteSize'] ||
          sha256.convert(image).toString() != meta['sha256'] ||
          ascii.decode(image.sublist(0, 4)) != 'RIFF' ||
          ascii.decode(image.sublist(8, 12)) != 'WEBP') {
        throw const PrivateLessonUnavailable();
      }
    }
    return (grant: grant, title: title, content: content, image: image);
  }

  Future<PrivateLessonCopy?> read(String context) async {
    final owner = _owner, epoch = _generation, revision = tokens.revision;
    if (owner == null ||
        _blockedAccount ||
        _blockedContexts.contains(context)) {
      return null;
    }
    try {
      final stored = await vault.read(owner, context);
      _current(owner, epoch, revision);
      if (stored == null ||
          stored.remainingMs <= 0 ||
          stored.remainingMs >
              PrivateOfflineAccessPolicy.window.inMilliseconds) {
        return null;
      }
      final parsed = _parse(
        Map<String, dynamic>.from(jsonDecode(stored.payload) as Map),
        owner,
        context,
      );
      return PrivateLessonCopy(
        title: parsed.title,
        content: parsed.content,
        image: parsed.image,
        remaining: Duration(milliseconds: stored.remainingMs),
        serverValidatedAt: parsed.grant.validatedAt,
      );
    } on Object {
      return null;
    }
  }

  Future<PrivateLessonCopy> open(String context) async {
    final owner = _owner, epoch = _generation, revision = tokens.revision;
    if (owner == null || tokens.accessToken?.isNotEmpty != true) {
      throw const PrivateLessonUnavailable();
    }
    final cancel = CancelToken();
    _requests.add(cancel);
    final deadline = Timer(
      const Duration(seconds: 30),
      () => cancel.cancel('Private validation timed out.'),
    );
    try {
      final start = await vault.clock();
      _current(owner, epoch, revision);
      final attempt = policy.beginValidation(context, start);
      final response = await dio.post<ResponseBody>(
        '/recursos/editoriales/lecciones/${Uri.encodeComponent(context)}/offline',
        data: {'requestNonce': attempt.requestNonce},
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
        ),
      );
      final body = response.data;
      if (response.statusCode != 201 ||
          body == null ||
          response.headers.value('content-type')?.split(';').first !=
              'application/json') {
        await body?.stream.listen(null).cancel();
        throw const PrivateLessonUnavailable();
      }
      final output = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        _current(owner, epoch, revision);
        if (output.length + chunk.length > 4 * 1024 * 1024) {
          throw const PrivateLessonUnavailable();
        }
        output.add(chunk);
      }
      final data = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(output.takeBytes())) as Map,
      );
      _current(owner, epoch, revision);
      final parsed = _parse(data, owner, context);
      final received = await vault.clock();
      _current(owner, epoch, revision);
      if (!policy.acceptValidation(attempt, parsed.grant, received)) {
        throw const PrivateLessonUnavailable();
      }
      await vault.seal(owner, context, jsonEncode(data), start);
      try {
        _current(owner, epoch, revision);
      } on Object {
        // Defend even a future vault whose write/clear operations are not FIFO.
        await vault.clearAccount(owner);
        rethrow;
      }
      _blockedAccount = false;
      _blockedContexts.remove(context);
      final result = await read(context);
      if (result == null) throw const PrivateLessonUnavailable();
      return result;
    } on DioException catch (error) {
      if (error.response?.data case final ResponseBody body) {
        await body.stream.listen(null).cancel();
      }
      _current(owner, epoch, revision);
      final status = error.response?.statusCode;
      if ([401, 403].contains(status)) {
        await deny(context, account: true);
      } else if ([404, 409, 410].contains(status)) {
        await deny(context);
      } else if (status == 503 ||
          [
            DioExceptionType.connectionError,
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          ].contains(error.type)) {
        final stored = await read(context);
        if (stored != null) return stored;
      }
      throw const PrivateLessonUnavailable();
    } on Object {
      if (_owner == owner && epoch == _generation) await deny(context);
      throw const PrivateLessonUnavailable();
    } finally {
      deadline.cancel();
      _requests.remove(cancel);
      cancel.cancel('Private validation finished.');
    }
  }

  void _cancelRequests() {
    for (final request in _requests.toList()) {
      request.cancel('Private account/permission changed.');
    }
  }

  void networkAvailable() {
    networkRevision++;
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _generation++;
    _cancelRequests();
    policy.logout();
    super.dispose();
  }
}

final privateOfflineEnabledProvider = Provider<bool>(
  (ref) =>
      const bool.fromEnvironment('PRIVATE_OFFLINE_ENABLED') &&
      ref.watch(appConfigProvider).environment == AppEnvironment.dev &&
      !ref.watch(appConfigProvider).demoMode &&
      defaultTargetPlatform == TargetPlatform.android,
);
final privateLessonVaultProvider = Provider<PrivateLessonVault>(
  (ref) => AndroidPrivateLessonVault(),
);
final privateLessonCacheProvider = ChangeNotifierProvider<PrivateLessonCache>((
  ref,
) {
  final cache = PrivateLessonCache(
    ref.watch(dioProvider),
    ref.watch(accessTokenStoreProvider),
    ref.watch(privateLessonVaultProvider),
  );
  void account() {
    final user = ref.read(sessionControllerProvider).user;
    cache.setAccount(user == null || user.isDemo ? null : user.id);
  }

  account();
  ref.listen(
    sessionControllerProvider.select((s) => s.user),
    (_, _) => account(),
  );
  final interceptor = InterceptorsWrapper(
    onError: (error, handler) {
      final body = error.response?.data;
      final code = body is Map
          ? (body['code'] ?? body['codigo'])?.toString().toUpperCase()
          : null;
      if ([
        'ACCOUNT_SUSPENDED',
        'SESSION_REVOKED',
        'SESSION_REPLACED',
        'DEVICE_SESSION_CONFLICT',
        'SINGLE_DEVICE_SESSION',
      ].contains(code)) {
        unawaited(cache.deny('', account: true));
      }
      handler.next(error);
    },
  );
  cache.dio.interceptors.add(interceptor);
  AndroidPrivateLessonVault.channel.setMethodCallHandler((call) async {
    if (call.method == 'networkAvailable') cache.networkAvailable();
  });
  ref.onDispose(() {
    cache.dio.interceptors.remove(interceptor);
    AndroidPrivateLessonVault.channel.setMethodCallHandler(null);
  });
  return cache;
});
