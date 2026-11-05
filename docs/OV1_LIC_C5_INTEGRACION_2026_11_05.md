# Integración local OV-1 con LIC/C5 — 5 de noviembre de 2026

## Composición y límites

Frontend: rama `feat/ov1-lic-c5-integracion`, worktree aislado
`saberplus-ov1-c5-integracion-front-20261105`, base C5 `9d7145c`.
Se combinó `48a44cc` (entrega del compañero, PR11) mediante merge local
sin commit. Único conflicto: registro de la imagen de inicio en pubspec;
se conservó `assets/images/Sabi_Inicio_Refuerzo.png`. Se mantienen las
rutas, contratos de sesión, archivos privados, LIC y documentos nativos C5.

Se incorporaron las correcciones de consulta restringida ya validadas en
`fix/ov1-android-validation`: solo el código de rechazo LIC exacto permite
cargar historial sin cuestionario. No habilita inicio/repetición/borradores;
errores de red/autenticación no se convierten en permiso de consulta.
Las pruebas de consulta usan además el modelo institucional LIC real con
licencia vencida, cuenta gestionada y práctica deshabilitada.

Backend: `fix/ov1-lic-integration`, base C5 `9cafcff`. Incluye módulo OV-1,
migración original intacta, clasificación CONSULTA para historial/lectura/
borrado y supresión revisada de respuestas/snapshots. Ver acta
`backend/docs/OV1_LIC_CONCILIACION_2026_11_04.md` en ese repositorio.

## Verificación final

Regresión completa del frontend combinado:1.388 aprobadas,0 fallos,
29 omitidas (capturas/ensayos opt-in);11:54. Incluye sesión LIC real vencida,
historial conservado y prohibición de reanudar borradores OV-1.
Análisis completo de lib/test:sin incidencias. Jest completo del backend:
164 suites y2.187 pruebas aprobadas,0 fallos;706,1s.

Primera regresión SQL privada:49 aprobadas/1 fallo,0 omitidas; los dos casos
OV-1 aprobados. Falló la recepción del PDF descargado en un ensayo Chromium
existente. No se atribuye automáticamente a carga ni se oculta ese fallo;
repetición completa sin cambiar el test:50/50 aprobadas,0 fallos/omitidas,
44,4s,89 migraciones propias en PostgreSQL16. Incluye descarga explícita
de PDF con bytes exactos, logout, escritorio y390px. El fallo inicial no
se reprodujo; no fue necesario modificar lógica ni relajar aserciones.
Los recursos SQL temporales propios se retiraron automáticamente.

Android anterior aprobó el módulo aislado contra backend C5+OV-1, no este
frontend integrado. No contar esa ejecución como una nueva prueba física.
Sin commit/push, producción, migraciones remotas ni cambios en bases reales.
Los cuadernillos y cambios del directorio original permanecen intactos.

## Entrega

Revisión final de lint: el módulo recibido traía419 diagnósticos en conjunto
(413 errores y6 advertencias), principalmente formato y mocks HTTP sin tipos.
Se corrigió mecánicamente solo producción: formato/aserciones redundantes y
callback inmediato expresado con Promise.resolve, sin cambiar reglas ni DTO.
Lint de producción OV-1 y política/supresión LIC dirigido:aprobado.
Tras ese ajuste:64/64 Jest dirigidas aprobadas. No sumar al total anterior.
Nest build posterior aprobado. Nueva repetición SQL/HTTP/Chromium posterior
al ajuste:50/50,0 fallos/omitidas,41,2s;recursos propios retirados. Análisis
dirigido final del modelo de sesión en tests y pantalla Flutter:sin incidencias.
Los diagnósticos de los tests heredados no se limpiaron en este alcance;
no declarar ESLint global limpio ni ocultar esa deuda técnica. Los tests sí
compilan y sus aserciones pasan; no se relajaron ni se añadieron suppressions.

Integración local de código y regresión automatizada conjunta aprobadas.
No requiere celular para estos resultados. Una aceptación física del frontend
combinado sería una evidencia posterior separada; no invalida la prueba
funcional Android anterior ni implica que ya se haya realizado otra.
El propietario autorizó ahora la confirmación Git y publicación de las ramas
de integración. Se conserva el merge con sus dos padres, sin publicar en main.
No usar las notas históricas de auditoría como bloqueos aún sin implementar.
