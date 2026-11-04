# LIC-4 — Cuenta institucional, retorno y privacidad

3/nov/2026. Implementación local en `feat/lic4-institution-lifecycle`, sin push,
merge, release, instalación Android ni despliegue nuevo. Estado integral y
contrato: `SaberPlus-Backend/backend/docs/LIC_4_ESTADO_ACTUAL.md` en el repositorio
backend. Este documento cubre la parte Flutter; no sustituye esa auditoría.

**Validación física posterior aprobada:** [acta Android LIC](LIC_ANDROID_VALIDACION.md),
con recorrido real, diez capturas y contraste SQL. Las limitaciones nativas
inferiores corresponden al checkpoint local anterior, no a este ensayo posterior.

## Recorrido

- Aviso institucional de Inicio/Práctica/docente → Consultar retorno a modalidad
  personal. Se consulta `GET /instituciones/:id/licencia/mi-salida`, sin decidir
  permisos por reloj local. El servidor confirma si es personal y elegible.
- Confirmar salida → `POST .../volver-personal`, con operación UUID estable,
  usuario y asignación/revisión exactas del backend. Conserva cuenta/historial y
  reanuda una vez el saldo personal guardado. No crea suscripción ni cobra.
- Cuenta gestionada: explica que no puede convertirse en personal por esta vía.
  Propietario debe transferir responsabilidad antes de salir. Durante cobertura
  activa el titular no tiene salida propia; propietario/ADMIN gestionan la baja.
- Más (estudiante) / icono Privacidad (docente) → Privacidad de mi cuenta. Envía
  una solicitud propia, no una supresión. Revisión/ejecución solo ADMIN en portal.
- Lista con referencia y estado, consulta paginada. Solicitudes de otros usuarios
  que el backend autorice a un propietario no se muestran como solicitudes propias.

## Seguridad y errores

Se reutilizan Dio, interceptor, token y revalidación de perfil existentes. Sin
nuevas dependencias. Widgets vinculados a identidad/institución; una sesión que
cambia desmonta el estado anterior. No se envían comandos desde demo.

Confirmaciones antes de enviar, sin reintentos automáticos. Si el resultado es
incierto se bloquea repetir y se pide consultar estado/perfil; el servidor aplica
idempotencia y revisión de asignación. Un receipt de otro usuario, permiso mal
formado o página inconsistente no se interpreta como éxito. Motivo conservado
ante error; aviso antes de descartar un motivo sin enviar. La respuesta exitosa
se conserva visible aunque falle el refresco posterior. Solicitar no borra ni
desactiva la cuenta; el texto distingue baja, retorno y supresión irreversible.

No se transfieren identidades/progreso. No cambia el contrato C5 de 72 horas ni
se intenta revocar un PDF exportado. Rutas backend y sesiones autorizan el acceso;
la interfaz no reemplaza esos controles.

## Verificación

- `flutter test`: 1215 aprobadas, 16 omitidas, sin fallos; log local
  `.tmp/lic4-flutter-full-regression.log`.
- 25 dirigidas actuales: `personal_return_eligibility_test.dart`,
  `personal_return_page_test.dart`, `account_privacy_page_test.dart`,
  `remote_account_lifecycle_repository_test.dart`, `account_lifecycle_layout_test.dart`.
  Log `.tmp/lic4-flutter-focused-final.log`.
- `flutter analyze`: sin incidencias, `.tmp/lic4-flutter-analysis-final.log`.
- Claro/oscuro, teléfono 375 px y horizontal, texto 250 %, reduced-motion y
  acceso desplazable a los controles. Guías UI/UX Pro Max: tokens de tema,
  SafeArea, contenido acotado, etiquetas y mensajes explícitos.
- `account_lifecycle_previews.dart`: previews con callbacks locales sin escrituras.
  DTD conectado; hot reload intentado sin app activa. No se presenta como prueba
  en teléfono ni como previewer visual ejecutado.

Cierre local integral confirmado: backend 155 suites/2084 pruebas y corrida final
SQL/HTTP/Edge aprobados, incluyendo carrera, rollback y preservación de terceros.
El documento de estado backend conserva la matriz y los límites. No requiere celular para
las pruebas de widgets; una prueba Android nativa sería evidencia adicional,
no una ejecución que se haya realizado aquí.
