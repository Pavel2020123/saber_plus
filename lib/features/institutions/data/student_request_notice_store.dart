import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/student_institution_request.dart';

abstract interface class StudentRequestNoticeStore {
  Future<bool> wasRead(String userId, StudentInstitutionRequest request);
  Future<void> markRead(String userId, StudentInstitutionRequest request);
}

/// Preferencia visual local, no autorización ni cambio del historial remoto.
/// Solo guarda UUID/revisión bajo una clave por cuenta; nunca texto ni credenciales.
class LocalStudentRequestNoticeStore implements StudentRequestNoticeStore {
  LocalStudentRequestNoticeStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  String _key(String userId) => 'saberplus.institution-request.read.v1.$userId';
  String _version(StudentInstitutionRequest request) =>
      '${request.id}:${request.revision}';
  @override
  Future<bool> wasRead(
    String userId,
    StudentInstitutionRequest request,
  ) async => await _preferences.getString(_key(userId)) == _version(request);
  @override
  Future<void> markRead(String userId, StudentInstitutionRequest request) =>
      _preferences.setString(_key(userId), _version(request));
}

final studentRequestNoticeStoreProvider = Provider<StudentRequestNoticeStore>(
  (ref) => LocalStudentRequestNoticeStore(),
);
