import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/media/private_offline_access_policy.dart';

OfflineClockSample clock(Duration elapsed, {String boot = 'boot-1'}) =>
    OfflineClockSample(bootId: boot, elapsed: elapsed);

void main() {
  late PrivateOfflineAccessPolicy policy;
  final serverTime = DateTime.utc(2026, 11, 1);
  PrivateOfflineGrant grant(
    OfflineValidationAttempt attempt, {
    String owner = 'a',
    String context = 'lesson',
  }) => PrivateOfflineGrant(
    ownerId: owner,
    contextId: context,
    validatedAt: serverTime,
    expiresAt: serverTime.add(PrivateOfflineAccessPolicy.window),
    requestNonce: attempt.requestNonce,
  );
  void validate({String context = 'lesson', Duration delay = Duration.zero}) {
    final attempt = policy.beginValidation(context, clock(Duration.zero));
    expect(
      policy.acceptValidation(
        attempt,
        grant(attempt, context: context),
        clock(delay),
      ),
      isTrue,
    );
  }

  setUp(() {
    policy = PrivateOfflineAccessPolicy()..changeAccount('a');
  });

  test('no validation means no private access', () {
    expect(
      policy.access('a', 'lesson', clock(Duration.zero)),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test('allows before 72 hours, blocks exactly at expiry', () {
    validate();
    expect(
      policy.access(
        'a',
        'lesson',
        clock(const Duration(hours: 71, minutes: 59)),
      ),
      PrivateOfflineAccess.allowed,
    );
    expect(
      policy.access('a', 'lesson', clock(const Duration(hours: 72))),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test('slow backend response cannot extend the window', () {
    validate(delay: const Duration(hours: 1));
    expect(
      policy.remaining('a', 'lesson', clock(const Duration(hours: 1))),
      const Duration(hours: 71),
    );
  });
  test('new successful validation starts a new window', () {
    validate();
    final now = clock(const Duration(hours: 70));
    final attempt = policy.beginValidation('lesson', now);
    expect(policy.acceptValidation(attempt, grant(attempt), now), isTrue);
    expect(
      policy.access('a', 'lesson', clock(const Duration(hours: 100))),
      PrivateOfflineAccess.allowed,
    );
  });
  test('failure or reading the cache never renews validation', () {
    validate();
    policy.beginValidation('lesson', clock(const Duration(hours: 70)));
    policy.access('a', 'lesson', clock(const Duration(hours: 71)));
    expect(
      policy.access('a', 'lesson', clock(const Duration(hours: 72))),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test(
    'revocation blocks immediately and rejects a late successful response',
    () {
      validate();
      final attempt = policy.beginValidation(
        'lesson',
        clock(const Duration(hours: 1)),
      );
      policy.confirmRevocation('lesson');
      expect(
        policy.access('a', 'lesson', clock(const Duration(hours: 1))),
        PrivateOfflineAccess.revalidationRequired,
      );
      expect(
        policy.acceptValidation(
          attempt,
          grant(attempt),
          clock(const Duration(hours: 1)),
        ),
        isFalse,
      );
    },
  );
  test('suspension blocks all contexts before the window expires', () {
    validate();
    validate(context: 'another');
    policy.confirmSuspension();
    for (final context in ['lesson', 'another']) {
      expect(
        policy.access('a', context, clock(Duration.zero)),
        PrivateOfflineAccess.revalidationRequired,
      );
    }
  });
  test('logout and account switching discard leases and pending requests', () {
    validate();
    final attempt = policy.beginValidation('lesson', clock(Duration.zero));
    policy.logout();
    policy.changeAccount('b');
    policy.changeAccount('a');
    expect(
      policy.acceptValidation(attempt, grant(attempt), clock(Duration.zero)),
      isFalse,
    );
    expect(
      policy.access('a', 'lesson', clock(Duration.zero)),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test('another account cannot use a lease', () {
    validate();
    expect(
      policy.access('b', 'lesson', clock(Duration.zero)),
      PrivateOfflineAccess.revalidationRequired,
    );
    expect(
      policy.access('a', 'lesson', clock(Duration.zero)),
      PrivateOfflineAccess.allowed,
    );
  });
  test('device reboot and monotonic rollback require revalidation', () {
    validate();
    expect(
      policy.access('a', 'lesson', clock(Duration.zero, boot: 'boot-2')),
      PrivateOfflineAccess.revalidationRequired,
    );
    final attempt = policy.beginValidation(
      'lesson',
      clock(const Duration(hours: 2)),
    );
    expect(
      policy.acceptValidation(
        attempt,
        grant(attempt),
        clock(const Duration(hours: 2)),
      ),
      isTrue,
    );
    expect(
      policy.access('a', 'lesson', clock(const Duration(hours: 1))),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test('out of order backend replies cannot replace a newer grant', () {
    final old = policy.beginValidation('lesson', clock(Duration.zero));
    final newer = policy.beginValidation(
      'lesson',
      clock(const Duration(hours: 1)),
    );
    expect(
      policy.acceptValidation(
        newer,
        grant(newer),
        clock(const Duration(hours: 1)),
      ),
      isTrue,
    );
    expect(
      policy.acceptValidation(old, grant(old), clock(const Duration(hours: 2))),
      isFalse,
    );
    expect(
      policy.remaining('a', 'lesson', clock(const Duration(hours: 2))),
      const Duration(hours: 71),
    );
  });
  test(
    'rejects owner/context mismatch and a server window longer than 72 hours',
    () {
      for (var scenario = 0; scenario < 3; scenario++) {
        final attempt = policy.beginValidation('lesson', clock(Duration.zero));
        final bad = [
          grant(attempt, owner: 'b'),
          grant(attempt, context: 'other'),
          PrivateOfflineGrant(
            ownerId: 'a',
            contextId: 'lesson',
            validatedAt: serverTime,
            expiresAt: serverTime.add(const Duration(hours: 73)),
            requestNonce: attempt.requestNonce,
          ),
        ][scenario];
        expect(
          policy.acceptValidation(attempt, bad, clock(Duration.zero)),
          isFalse,
        );
      }
    },
  );
  test('new policy instance never trusts an unprotected restored record', () {
    validate();
    policy = PrivateOfflineAccessPolicy()..changeAccount('a');
    expect(
      policy.access('a', 'lesson', clock(Duration.zero)),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test('a previous grant cannot renew a different validation request', () {
    final first = policy.beginValidation('lesson', clock(Duration.zero));
    final oldGrant = grant(first);
    expect(
      policy.acceptValidation(first, oldGrant, clock(Duration.zero)),
      isTrue,
    );
    final next = policy.beginValidation(
      'lesson',
      clock(const Duration(hours: 70)),
    );
    expect(next.requestNonce, isNot(first.requestNonce));
    expect(
      policy.acceptValidation(next, oldGrant, clock(const Duration(hours: 70))),
      isFalse,
    );
    expect(
      policy.access('a', 'lesson', clock(const Duration(hours: 70))),
      PrivateOfflineAccess.revalidationRequired,
    );
  });
  test(
    'rollback after a later monotonic observation never extends a lease',
    () {
      validate();
      policy.access('a', 'lesson', clock(const Duration(hours: 70)));
      expect(
        policy.access('a', 'lesson', clock(const Duration(hours: 1))),
        PrivateOfflineAccess.revalidationRequired,
      );
    },
  );
}
