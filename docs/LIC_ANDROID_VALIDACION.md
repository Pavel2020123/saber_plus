# LIC — Validación física Android

3/nov/2026. Solicitada por el propietario para cerrar la validación de LIC-0/1/2/3/4.
Validación local física aprobada. No acredita publicación comercial ni aceptación humana de toda la app.

## Entorno y seguridad

- Android físico autorizado por ADB, modelo 24117RN76L (tanzanite).
- Variante objetivo `com.example.saber_plus.i2validation`, SaberPlus Pruebas.
  Verificar paquete con AAPT antes de instalar; no borrar datos de la app normal.
- API propia local en 43187 mediante reverse USB. Docker/PostgreSQL desechables,
  marker/nonce/label verificados antes de preparar datos; sin servicios remotos.
- `tool/lic_android_fixture.mjs` en backend prepara cuentas y contratos sintéticos:
  gestionada con temporal real, propietario, personal con saldo conservado/licencia
  vencida y personal con licencia suspendida. Credenciales en archivo temporal
  privado, no en código ni capturas; no reutilizarlo fuera del runner.
- Prioridad con cinco preguntas sintéticas publicadas, creada por la API real.

## Recorrido automatizado

`integration_test/lic_android_test.dart` usa la app, providers, router y cliente
autenticado reales, sin sustitución de servicios ni respuestas HTTP simuladas.
`test_driver/lic_android_driver.dart` guarda únicamente capturas posteriores a
autenticación en `docs/evidence/lic-android-20261103`.

1. Login institucional con temporal y cambio obligatorio de contraseña.
2. Sesión renovada, cobertura activa y cuenta gestionada sin conversión personal.
3. Prioridad visible para el estudiante gestionado.
4. Solicitud de supresión propia: pendiente de revisión, sin borrar cuenta.
5. Logout y cambio de identidad; licencia suspendida sin práctica nueva.
6. Licencia vencida y retorno personal confirmado; perfil conserva identidad.
7. Entrada docente, grupos cargados y prioridades del grupo visibles.
8. Contraste SQL del cambio de clave, consumo de temporal, saldo exacto una vez,
   historial conservado y solicitud pendiente sin supresión.

El test no ejecuta supresión irreversible desde móvil ni opera cuentas reales.
Las pruebas SQL/HTTP/navegador de ADMIN y concurrencia están en el cierre local
LIC-4. La validación física complementa, no reemplaza, esas evidencias.

## Estado

Recorrido completo aprobado en el dispositivo: `LIC_ANDROID_REAL_API_COMPLETE`
y `All tests passed` en `.tmp/lic-android-device-final.log`. Un escenario
end-to-end, aproximadamente 63 segundos; no se cuentan los hooks de teardown
como escenarios de negocio adicionales. El wrapper PowerShell devolvió 1 por
salida nativa en stderr: no se usa ese código como prueba de aprobación, sino
el resultado explícito de la suite y el contraste SQL posterior.

`node tool/lic_android_fixture.mjs <directorio-propio> verify` terminó con salida
0 y `lic-android-sql-verified`: cambio de clave persistido, temporal consumida,
saldo reanudado exactamente una vez, diagnóstico conservado y solicitud pendiente
sin suprimir la cuenta. Log backend `.tmp/lic-android-sql-verification.log`.
Análisis de test y driver sin incidencias. No se cambió lógica productiva para
forzar el resultado.

Diez capturas reales guardadas e inspeccionadas en
[evidence/lic-android-20261103](evidence/lic-android-20261103/): activa,
gestionada sin conversión, prioridad del estudiante, privacidad pendiente,
suspensión, vencimiento, retorno personal y vistas docente/grupos/prioridades.
La captura de retorno muestra la ausencia de vínculo tras actualizar perfil;
la continuidad de identidad y saldo se acredita además con assertions y SQL.

Se cierra la validación local de los recorridos LIC acordados. No se ejecutó
supresión irreversible desde el celular ni migración remota. Android grande/
oscuro y manipulación del reloj no se repitieron físicamente en este guion:
sus pruebas previas siguen identificadas aparte, sin inventar cobertura.
No hay commit/push/merge por esta ejecución.

## Incidencias del ensayo (no aprobaciones)

- El primer `flutter drive` no aplicó el selector mediante variable de entorno:
  instaló el APK de test con el ID normal. Se detuvo y no se desinstaló ni se
  ejecutó `pm clear`. Se restauró después la entrada normal `lib/main.dart`:
  compilación, AAPT ID `com.example.saber_plus`/etiqueta SaberPlus,
  `adb install -r` con `Success` y lanzamiento de MainActivity comprobados.
  No se desinstaló la aplicación ni se borraron sus datos para restaurarla.
  Se cambió a `-P saberplusValidationApk=true` explícito y AAPT confirmó después
  el ID `.i2validation` y etiqueta SaberPlus Pruebas antes de instalar.
- Ese intento alcanzó login, cambio de temporal y cobertura activa. Falló al
  convertir dos veces la superficie para la segunda captura. Se corrigió el
  capturador para convertir una sola vez, sin cambiar lógica de la aplicación.
- Se generó otro fixture, conservando el manifiesto previo: no se reutilizan
  temporales consumidas. Los archivos de configuración y logs locales no se
  publican; el entorno DEBUG heredado se vacía en los comandos posteriores para
  evitar que Gradle imprima parámetros de compilación con credenciales sintéticas.
