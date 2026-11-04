# LIC-3 — Identidad y acceso institucional en Flutter

3/nov/2026. Implementación y verificación locales completadas; evidencia consolidada en el
repositorio backend, `backend/docs/LIC_3_PORTAL_Y_APP.md`. No implica despliegue ni
publicación Android. Mantener LIC-0/1/2 como contrato, sin billing o LIC-4.

## Contrato y experiencia

- `UserSession.institutionalUsername` no sustituye correo real ni lo marca verificado.
- `/auth/perfil.accesoInstitucional`: versión, institución, origen, estado, asignación,
  permisos, inicio/fin y validación del servidor. Es fotografía de presentación,
  nunca autorización offline. Estados desconocidos/incoherentes se rechazan.
- Inicio estudiante/docente y Practicar presentan estado y última validación.
  Actualizar y reanudar app consultan backend; la lectura más reciente prevalece.
  Fallar no amplía caché ni invalida respuestas educativas guardadas.
- Vencimiento permite historial autorizado, no actividades nuevas. Diagnósticos y
  simulacros iniciados con cobertura activa respetan plazo original y tope de 24h
  posterior al vencimiento. Suspensión o retirada no conceden esa gracia.
- El router permanece estable al cambiar licencia, sin redirección que destruya
  un intento. Backend sigue autorizando inicio y entrega; no habilitar por reloj local.
- Login/recuperación/cambio obligatorio explican alias sin buzón y temporal de primer
  uso. Reportes sin correo solo se ofrecen con alias, origen gestionado y acceso
  activo en la fotografía; el servidor revalida antes de escribir.

## Comprobaciones locales

Regresión Flutter completa: 1201 aprobadas, 16 omitidas según entorno, sin variables
de pruebas live. Log `.tmp/lic3-flutter-full-regression.log`. No afirmar que se
ejecutaron esas pruebas live ni Android físico.

Pruebas específicas: parseo/roundtrip de estados y alias, perfil tardío tras logout,
revalidaciones fuera de orden, router estable, tarjeta claro/oscuro a 375px y escala
2.5, rechazo institucional de entrega conservando borrador, diagnóstico y reanudación.
No sumar recuentos de baterías solapadas.

Análisis global final sin incidencias en `.tmp/lic3-final-app-analysis.log`.
Después del último ajuste de texto, 11 pruebas de tarjeta aprobadas en
`.tmp/lic3-final-card-tests.log`. Hot reload intentado: DTD conectado sin app activa. Previews puras anotadas
en `institutional_access_card.dart`; previewer offline no arrancó por ausencia de
`webview_flutter_web` en caché. No se alteraron dependencias para forzarlo.

No borrar borradores ni historial por actualizar licencia. El cierre de sesión o
cambio de cuenta conserva sus fronteras de privacidad existentes; no mezclar con
transferencia de progreso, compras ni supresión de cuentas.
