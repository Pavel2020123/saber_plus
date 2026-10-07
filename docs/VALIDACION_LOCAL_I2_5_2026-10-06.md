# Validación local I2-5 — 6 de octubre de 2026

**I2-5 continúa abierto.** Ya se ejecutó la regresión PostgreSQL competitiva
completa: 347/347 en 25 archivos, sin omisiones ni cancelaciones; ranking dirigido
12/12. Falta completar la comprobación física de los criterios integrados.
No se acredita producción ni se cierran B1/B2, P5/D3, despliegue o activación.

El informe completo y la evidencia sanitizada están en el repositorio hermano:
`SaberPlus-Backend/backend/docs/VALIDACION_LOCAL_I2_5_2026-10-06.md` y
`SaberPlus-Backend/backend/docs/validacion-local-2026-10-06/resultados.json`.
No son archivos de este repositorio. Contienen matriz por módulo, comandos,
exits, duraciones de todos los intentos, fallos, límites y limpieza.

## Repositorios y equipo

- Flutter `C:\Users\modaf\saber_plus`, main,
  HEAD `f55a8f82c209cc95bfcfdf3ed012a5e17529e897`.
- Backend/panel `C:\Users\modaf\SaberPlus-Backend`, main,
  HEAD `11b3647e66ed078cf8dd83fb7450a647b392218a`.
- Windows 11 Home 10.0.26200; 16.153.124 KiB RAM; libres al inicio 4.095.496 KiB;
  disco C libre inicial 777.817.726.976 bytes. Medida final en informe backend.
- Flutter 3.47.0 (4cf2416426), Dart 3.13.0; Node 24.14.1/npm 11.11.0 portables;
  Docker Linux 29.7.2 local; PostgreSQL 16 Docker y 16.15 portable.
- Android inicial 24117RN76L; dispositivo conectado al instalar: CPH2577,
  Android 15. Sin Apple/iOS.
- Cambio ajeno preexistente `analysis_options.yaml` preservado. No commits/push.
  No se modificaron manifests, lockfiles ni reglas de producto.

## Resultados de esta ejecución

| Comprobación | Estado | Resultado |
| --- | --- | --- |
| `flutter pub get --enforce-lockfile` | APROBADO | exit 0, 7,466 s |
| `flutter analyze --no-pub` | APROBADO | exit 0, 20,416 s; repetición sin incidencias |
| `flutter test --no-pub --reporter expanded`, base | APROBADO | exit 0, 694 pass/4 skip, 199,659 s |
| Mismo comando tras test nuevo | APROBADO | exit 0, 694 pass/9 skip, 129,594 s |
| Flutter auth + ranking HTTP real | APROBADO | exit 0, 6/6; tras corrección 5/5 |
| APK debug local separada | APROBADO | exit 0, 8.702,907 s totales; adb install Success |
| Backend build/Jest | APROBADO | 1.258/1.258, 111 suites |
| PostgreSQL competitivo | APROBADO | 347/347 completo y 12/12 dirigido |
| PostgreSQL otros nueve modos | APROBADO | 102 pruebas; mapa 7/7 en repetición |
| Panel check | APROBADO | 22 módulos |
| Panel npm test | FALLÓ | 78/88, 74/88 y 73/88; HTTP loopback/timeouts |
| Panel serial explícito | APROBADO | 88/88, sin omitir casos; causa de fallos predeterminados pendiente |
| Panel HTTP real y navegador | APROBADO | 2/2 repetidas; navegación local observada por capturas |
| Lint backend sin fix | FALLÓ | 567 errores/150 avisos |
| Audit backend | FALLÓ | 13 paquetes afectados; prod 1 critical proxy-addr |
| Certificados | APROBADO | 7 PDF generados; inspección de HTML área/nombre largo |
| Android manual completo | BLOQUEADO | Teléfono bloqueado; desbloqueo solicitado, sin atribuir pruebas humanas |
| Juegos/audio físicos | NO EJECUTADO | No se sustituyen con fixtures o tests unitarios |
| iOS | NO EJECUTADO | Requiere equipo Apple |

Las 4 omisiones anteriores corresponden a pruebas live opt-in de auth,
diagnóstico/estudio y staging. Las 5 nuevas requieren `LOCAL_RANKING_ENABLED`.
Las nuevas sí se ejecutaron separadamente contra API real. No se accedió a staging
ni a servicios reales para eliminar skips. Las pruebas globales son unit/widget,
no E2E físico. Configuración de análisis: exclusiones preexistentes preservadas.

## Qué prueban los casos nuevos

`test/competitive_ranking_local_api_test.dart` usa RemoteAuthRepository, Dio,
interceptor, API AppModule, bcrypt/JWT y PostgreSQL reales. Login con cuenta
verificada, TOP 50, propio 51/61, XP cero/sin balance, temporadas y juegos,
vacío, Memoria/Batallas no disponibles, roles 403, sesión inválida y nuevo login,
privacidad y endpoint legacy. Cinco casos, sin mocks de HTTP ni tokens fabricados.
El fixture usa 60 rivales sintéticos: no acredita partidas competitivas reales.
Tras corrección interna legítima por CompetitiveService.correct, confirma puesto
1 y XP 2.100 (antes 51 y 100), sin conceder XP desde Flutter.

Procedimiento: `backend/tool/LOCAL_RANKING_VALIDATION.md` en el repositorio hermano.
El archivo privado temporal con credenciales se usa solo en los tests opt-in;
no incorporarlo a APK, logs, informe ni Git. Todos los endpoints son loopback.

I2-4 consulta rankings. Admisión/presencia sigue pendiente de cableado/verificación
por cliente Flutter: Cima, Guardián, Rescate, Trivia Rush, Duelo fantasma y Tira y
afloja. No se activaron flags. Memoria/Batallas NO_DISPONIBLE es comportamiento
esperado. No se reimplementaron módulos cerrados.

## APK y observación física

Paquete de prueba `com.example.saber_plus.i2validation`, con APP_ENV=dev,
DEMO_MODE=false y API_BASE_URL/CONTENT_BASE_URL `http://127.0.0.1:43187`.
Se instaló junto a la app habitual, preservando sus datos. Gradle tuvo un suffix
temporal, restaurado byte a byte después de compilar; APK y build no van a Git.
No contiene defines de credenciales. USB reverse propio en puerto 43187.

Al abrirla se obtuvo captura negra con lockscreen activo en dumpsys, no evidencia
de error de render. Texto grande, pantalla pequeña, teclado, desplazamiento,
navegación general/competitivo, filtros rápidos, gesto, reintento, red,
segundo plano y audio no deben darse por aprobados sin la comprobación física.
La aceptación del usuario de ayudar no es un resultado manual.

Al cerrar se retiraron el reverse USB y la app de prueba (uninstall Success),
preservando la instalación habitual. La API y sus bases/credenciales temporales
se eliminaron; no queda listener en 43187. APK conservada en
`build/app/outputs/flutter-apk/app-debug.apk`, ignorada por Git, para reinstalarla
al retomar con teléfono desbloqueado y un entorno local nuevo.
Disco C al cierre: 757.649.297.408 bytes libres; RAM libre 3.998.820 KiB.
Los logs, capturas y herramientas portables quedan fuera de los repositorios;
ubicación y recursos retenidos detallados en el informe backend. No hubo prune.
`git diff --check` correcto en ambos repositorios, sin incluir artefactos ni
secretos en las listas de entrega. No se hizo git add, commit ni push.

La cadena TLS local necesitó raíces del sistema para Node y copia privada de
cacerts para Java. No se deshabilitó TLS ni se modificó el almacén global.
Gradle instaló CMake 3.22.1 en el SDK existente; queda documentado. Un intento
se detuvo por presión de RAM; el reintento limitado a 1 GiB/un worker compiló.

## Entrega para revisión

Archivos precisos para añadir en este repositorio:

```text
test/competitive_ranking_local_api_test.dart
docs/VALIDACION_LOCAL_I2_5_2026-10-06.md
docs/ETAPAS_PENDIENTES.md
docs/PROMPT_RELEVO.md
docs/RELEVO_EQUIPO.md
```

No añadir `analysis_options.yaml` como parte de esta entrega: es cambio ajeno
preexistente. No añadir APK, build, capturas temporales, credenciales ni logs.
Commit sugerido: `test: validar ranking con API local y registrar estado I2-5`.
La lista backend y su commit sugerido están en el informe correspondiente.

Antes de push: revisar ambos diffs, confirmar main y remotos actuales, comprobar
que no hay secretos/artefactos, aceptar pendientes y autorizar explícitamente
commit/push. No se hizo ninguno. Siguiente paso: completar comprobación física,
resolver/documentar fallos de validación y evaluar todos los criterios de I2-5.
