# Profesor P3-B — pantallas, práctica dirigida y seguimiento

Entrega local del 13 de septiembre de 2026. Completa la implementación local P3
iniciada en P3-A. **Sigue P4: sincronización de tiempo estudiado y evolución**;
después P5 (ensayo integrado real) y D3 (panel editorial real).

## Cómo usarlo

### Profesor

1. Entrar como profesor → Grupos → **Temas priorizados y cumplimiento**.
2. **Asignar tema o subtema** → área → seleccionar subtema y su tema.
3. Activar «Tema completo» si se quiere todo el tema, o dejar solo el subtema.
4. Elegir plazo (1, 3, 7, 14 o 30 días desde la confirmación) y confirmar.
5. Consultar el listado, abrir **Ver cumplimiento** o **Retirar prioridad**.
   Retirar solicita confirmación y no elimina respuestas anteriores.

El plan institucional vigente controla creación/catálogo/seguimiento. Un docente
con plan vencido conserva listado y retiro. La demo presenta explícitamente una
vista previa del plan sin anuncios: no cambia derechos de una cuenta real.

### Estudiante

1. Entrar → **Practicar → Prioridades de mi profesor**.
2. Consultar tema, grupo, estado, fecha y avance de cinco preguntas distintas.
3. Abrir **Practicar preguntas pendientes**, responder y enviar el intento.
4. Revisar explicaciones y **Volver a prioridades** para actualizar el avance.

El servidor selecciona únicamente preguntas publicadas del snapshot asignado,
excluyendo las ya practicadas dentro de la ventana. Si quedan menos disponibles,
entrega las que existen; si no quedan, explica que se consulte al profesor.
No sustituye preguntas archivadas por otras añadidas después al tema.

Una práctica cumplida no acredita dominio. No se marca una lección completada ni
se concede XP extra por la prioridad; se reutilizan calificación/XP/historial
normales. El resultado no muestra «Volver a la lección» ni propone reiniciar una
prioridad ya cumplida. Los pendientes adicionales se consultan desde el listado.

## Persistencia, reintentos y privacidad

- Repositorios remoto/demo separados; un fallo remoto nunca muestra datos demo.
- Modelos validan versión, política, página, grupo/prioridad, métricas, fechas y
  coherencia entre cumplimiento/estado. Lecturas cancelables ligadas a sesión.
- Cambiar de cuenta cancela peticiones de pantallas y borra selecciones privadas.
  Respuestas de carga/calificación no se asignan a otra cuenta.
- Una creación mantiene UUID v4 y cuerpo al reintentar tras resultado incierto.
  Fechas normalizadas a UTC/milisegundos para el contrato JavaScript. Mientras
  se confirma, no se cambia silenciosamente la selección ni el plazo.
- Si se abandona la pantalla con resultado incierto, consultar el listado antes
  de crear otra tarea. El UUID pendiente no persiste tras cerrar la app; la
  prohibición de duplicados activos del backend se conserva como segunda defensa.
- Las prioridades y sus intentos dirigidos no se guardan en disco ni se restauran
  offline: vuelven a comprobarse con el servidor. La demo vive solo en memoria,
  usa el pequeño banco de ejemplos existente y se reinicia al cambiar de cuenta.
- La API de inicio solo recibe el ID de prioridad y usa la sesión. No recibe
  preguntas libres, claves, porcentajes ni un ID de otro estudiante.
- El intento expira como máximo al vencer la prioridad (o a las dos horas).
  Retirar/salir del grupo impide iniciar otro intento y detiene el cómputo de esa
  prioridad. Una práctica ya entregada puede aún calificarse como estudio normal
  mientras su intento siga vigente; eso no reabre una prioridad retirada.
- Fechas visibles en la zona del dispositivo. Estados vacíos, errores y páginas
  siguientes son distintos; no hay datos privados anteriores detrás de un error.

## Verificación y límites

Se verifican modelos, endpoints/cancelación, UUID y precisión de fechas, rechazo
de datos incoherentes, reintentos con el mismo cuerpo, demo, navegación, retiro
confirmado, modo estudiante y texto al 200% en 320 px. La práctica tiene prueba
de carga/calificación sin acceso a borradores locales y regreso a prioridades.

Backend: 725 pruebas Jest en 71 suites; 13 pruebas PostgreSQL temporal incluyen
el recorrido real de crear intento → calificar → historial → cumplimiento,
permisos, preguntas pendientes y claves no expuestas. Compilación/lint aprobados.
Flutter: 461 pruebas aprobadas y 4 omitidas por requerir configuración de acceso
real (AUTH_E2E/staging). `flutter analyze` sin observaciones. Se ajustaron dos
pruebas de navegación para centrar las tarjetas antes del toque, tras añadir
la entrada de prioridades; memoria y contrarreloj conservan sus comprobaciones.

No se probaron cuentas reales ni teléfonos, no se desplegó Render y no se modificó
Supabase. P5/D3 siguen abiertas. La migración P3-A continúa pendiente en el
entorno real; P3-B no añade otra. No se necesita ningún audio ni recurso gráfico.

## Comandos de verificación

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter analyze
flutter test
```

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend"
npm run build
npx eslint src/institucion/teacher-priorities*.ts
npm test -- --runInBand --silent
node tool/test_editorial_postgres.mjs --teacher-priorities
```

El último comando usa una instancia desechable, no Supabase ni PostgreSQL habitual.
Se cerró y eliminó su directorio propio al finalizar la prueba.

## Commits y rutas

Backend — no añadir el esquema, app.module, probe_database ni Guardián:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/PROFESOR_P3_A.md backend/PROFESOR_P3_B.md backend/src/institucion/teacher-priorities.service.ts backend/src/institucion/teacher-priorities.controller.ts backend/src/institucion/teacher-priorities.controller.spec.ts backend/test/teacher-priorities-postgres.test.cjs
git diff --cached --stat
git commit -m "feat: iniciar practica dirigida de prioridades docentes P3-B"
```

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs lib test
git diff --cached --stat
git commit -m "feat: integrar prioridades del profesor y estudiante P3-B"
```

No se hicieron commits, push ni despliegues automáticamente.
