import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/session.dart';

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState.unauthenticated();

  void enterDemo({AppRole role = AppRole.student}) {
    state = SessionState.authenticated(
      UserSession(
        id: 'demo-${role.name}',
        firstName: role == AppRole.teacher ? 'Profe Andrea' : 'Santiago',
        role: role,
      ),
    );
  }

  Future<void> signOut() async {
    state = const SessionState.unauthenticated();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
