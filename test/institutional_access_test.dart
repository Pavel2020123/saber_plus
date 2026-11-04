import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/institutional_access.dart';
import 'package:saber_plus/features/auth/domain/session.dart';

void main() {
  Map<String, dynamic> fixture(String state) => {
    'version': 1,
    'institucionId': 'school',
    'estadoLicencia': state,
    'origenCuenta': 'GESTIONADA',
    'asignacionActiva': true,
    'permitePractica': state == 'ACTIVA',
    'permiteHistorial': true,
    'inicio': '2026-11-01T05:00:00.000Z',
    'fin': '2027-05-01T05:00:00.000Z',
    'validadoEn': '2026-11-03T12:00:00.000Z',
  };
  for (final state in [
    'SIN_LICENCIA',
    'PROGRAMADA',
    'ACTIVA',
    'VENCIDA',
    'SUSPENDIDA',
  ]) {
    test(
      'estado $state conserva contrato y no usa reloj local para habilitar',
      () {
        final json = fixture(state);
        final access = InstitutionalAccess.fromJson(json);
        expect(access.canStartPractice, state == 'ACTIVA');
        expect(access.historyAllowed, isTrue);
        expect(access.managedAccount, isTrue);
        expect(jsonDecode(jsonEncode(access.toJson())), json);
      },
    );
  }
  test('activa sin asignación muestra sin cupo y no habilita práctica', () {
    final access = InstitutionalAccess.fromJson({
      ...fixture('ACTIVA'),
      'asignacionActiva': false,
      'permitePractica': false,
    });
    expect(access.canStartPractice, isFalse);
    expect(access.statusLabel, 'Sin cupo asignado');
  });
  test(
    'estado desconocido, permisos incoherentes y fecha sin zona se rechazan',
    () {
      for (final json in [
        fixture('OTRA'),
        {...fixture('VENCIDA'), 'permitePractica': true},
        {...fixture('ACTIVA'), 'validadoEn': '2026-11-03T12:00:00'},
        {...fixture('ACTIVA'), 'asignacionActiva': 'true'},
      ]) {
        expect(() => InstitutionalAccess.fromJson(json), throwsFormatException);
      }
    },
  );
  test(
    'alias sin correo no simula verificación y copyWith conserva acceso',
    () {
      final user = UserSession.fromBackendJson({
        'id': 'student',
        'nombre': 'Ana',
        'rol': 'ESTUDIANTE',
        'correo': null,
        'correoVerificado': false,
        'identificadorInstitucional': 'ana@colegio.example',
        'accesoInstitucional': fixture('ACTIVA'),
      });
      expect(user.email, isNull);
      expect(user.emailVerified, isFalse);
      expect(user.institutionalUsername, 'ana@colegio.example');
      expect(
        user.copyWith(xpTotal: 10).institutionalAccess,
        same(user.institutionalAccess),
      );
    },
  );
  test('perfil personal legado sin snapshot sigue compatible', () {
    final user = UserSession.fromBackendJson({
      'id': 'personal',
      'nombre': 'Ana',
      'rol': 'ESTUDIANTE',
      'correo': 'ana@example.invalid',
    });
    expect(user.institutionalAccess, isNull);
    expect(user.institutionalUsername, isNull);
  });
}
