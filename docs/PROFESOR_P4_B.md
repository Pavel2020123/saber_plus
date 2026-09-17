# Profesor P4-B — sincronización y evolución en Flutter

Entrega local del 14 de septiembre de 2026. Implementa el cliente del contrato
P4-A; **sigue P4-C: aprobación institucional, y después P5**, antes de D3. No se desplegó
en Render ni se modificó Supabase. No se añadieron paquetes ni audios.

## Qué puede hacer cada usuario

- Estudiante: abrir **Más → Tiempo estudiado**, consultar el informe de 7/30/90
  días, actualizarlo, revisar su cola y solicitar sincronización de Pomodoros.
- Profesor: abrir la ficha de un estudiante autorizado y **Ver tiempo y
  evolución**. La API conserva sus controles de rol, grupo y plan de P2/P4-A.
- Consultar por separado evaluaciones confirmadas y Pomodoro declarado. No se
  suman: un bloque puede funcionar mientras se responden preguntas.
- Abrir cada día para ver respuestas, aciertos, errores, tiempos disponibles y
  cantidad de Pomodoros. Días y horas usan Colombia.
- Distinguir ausencia de registros, porcentaje no disponible y muestra parcial.
  No se interpreta un día sin datos como inactividad ni estos tiempos como
  atención verificada, dominio de un tema o derecho a XP.

El resumen semanal/mensual local cuenta actividades Pomodoro, pero sus minutos
de evaluaciones ya no incluyen Pomodoro. Perfil y Más tampoco presentan la suma
de ambas fuentes como un total único. El resumen local no sustituye el remoto.

## Persistencia, reintentos y sesión

- Drift/SQLite pasa de versión 8 a 9 mediante una tabla nueva de cola. Conserva
  el historial anterior; la actualización es local, no una migración Supabase.
- Registrar un nuevo Pomodoro completo de 1500 segundos guarda historial y cola
  en la misma transacción. Clave por usuario/evento; ID y fecha UTC con
  milisegundos permanecen estables, incluso tras timeout o reiniciar la app.
- Solo se encolan nuevos bloques reales de 25 minutos. No se importa el historial
  antiguo ni se suben tiempos de prácticas/diagnósticos: estos ya llegan mediante
  sus resultados al servidor. La demo conserva sus datos aislados en memoria.
- Se envía un evento por solicitud para aislar conflictos, hasta 50 pendientes
  por ciclo. Solo se confirma si la respuesta válida reconoce exactamente ese
  evento, duración y fecha. Un recibo confirmado evita volver a encolarlo.
- La sincronización se solicita al entrar con una cuenta real de estudiante y
  se revisa cada minuto mientras la app esté en primer plano. También existe el
  botón manual. No es un servicio de ejecución permanente en segundo plano.
- No hay ciclos simultáneos del mismo worker. Los envíos capturan usuario y
  revisión del token; cambios de cuenta o sesión impiden confirmar datos bajo
  otra identidad. La cola y los informes se aíslan por usuario.
- Errores de red, sesión, función no desplegada o límite de solicitudes conservan
  pendientes. Fechas futuras, formato inválido, conflicto o respuesta no
  verificable requieren revisión. No se cambian IDs/fechas para forzar envíos.
- Un bloque nunca enviado con más de 90 días queda local. Si ya hubo un intento
  incierto, se permite consultar nuevamente al servidor con el mismo cuerpo,
  pues podría haberlo reconocido antes de vencer esa ventana.
- **Reintentar mismo bloque** conserva la solicitud. **Dejar solo local** pide
  confirmación y lo retira de futuros envíos, conservando su recibo e historial.
  Si ya llegó al servidor, esta acción no lo elimina allí.
- La pantalla muestra los primeros 100 pendientes/conflictos y, opcionalmente,
  los 20 registros locales más recientes. No son listados paginados completos.

## Contrato y estados de pantalla

- `GET /tiempo-estudio/me?dias=7|30|90` para el estudiante.
- `POST /tiempo-estudio/me/pomodoros` para confirmar bloques propios.
- `GET /instituciones/me/estudiantes/:id/evolucion?dias=7|30|90` para el profesor.
- Ruta Flutter docente: `/teacher/students/:studentId/evolution`.
- Validación de política/versionado, límites, fechas, filas diarias, totales y
  coherencia de aciertos/errores/porcentajes. Un contrato incoherente muestra un
  error, no métricas inventadas.
- La demo muestra un informe de ejemplo explícito; no representa datos reales
  ni se sustituye automáticamente por ella una respuesta remota fallida.
- Una recarga o pérdida de autorización oculta el informe previo. Los errores
  ofrecen reintento; las respuestas parciales no muestran porcentajes completos.
- Pantalla docente comprobada con ancho de 320 píxeles y texto al 200% mediante
  prueba de widgets. Esto no sustituye una revisión manual en teléfonos.

## Verificación local

Resultado final: **497 pruebas Flutter aprobadas y 4 pruebas remotas omitidas**
por requerir configuración/cuentas de ensayo. `flutter analyze`: sin errores ni
avisos. Generación Drift y `git diff --check` completados correctamente.
Las pruebas específicas cubren migración v8→v9 y reapertura, escritura atómica,
IDs inmutables, confirmaciones, conflictos, error de red, sesión, reconexión,
aislamiento, demo, modelos, rutas, accesibilidad y confirmación de conservación
local. No se ejecutó backend en este turno ni se afirma verificación en la nube.

Comprobaciones reproducibles desde la raíz Flutter:

```powershell
flutter analyze
flutter test --reporter expanded
```

## Lo que falta antes de D3

1. Completar/revisar commits del backend (nota del esquema abajo) y resolver por
   separado los cambios previos de Guardián antes de validar un checkout limpio.
2. Confirmar URL de Render, destino de ensayo, respaldo y permisos; revisar
   migraciones P3-A/P4-A y desplegar los cambios pendientes con autorización.
3. Ejecutar P5 con profesor/estudiante reales autorizados: grupos, prioridades,
   práctica, cumplimiento/evidencia, tiempo, roles/aislamiento, sesión y red.
4. Registrar evidencia Android/iOS y corregir fallos. Después retomar D3 con URL
   exacta, cuenta ADMIN disponible, comprobación visual editorial y destino/origen
   confirmados. No pedir contraseñas por chat.

El inventario completo de los 13 bloques restantes se conserva en
[ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md); no desaparecen con esta entrega.

## Commits y rutas

Flutter, revisando antes que no haya cambios ajenos nuevos:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs lib test
git diff --cached --stat
git commit -m "feat: sincronizar Pomodoro y mostrar evolucion docente P4-B"
```

No se modificó el backend para P4-B. Sin embargo, en la revisión actual del
esquema quedó sin commit el modelo de P4-A, aunque su relación ya está guardada.
Completar ese pendiente por separado:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add -p backend/prisma/schema.prisma
```

En el diff observado hay **dos bloques: `y`, Enter; después `n`, Enter**:

1. `model PomodoroRegistrado`: **y**, incluirlo.
2. `model IntentoGuardian`: **n**, conservarlo separado.

No es `y,n,n` en este estado. Si cambian los bloques, decidir por el nombre del
modelo, no repetir letras a ciegas. No preparar otras migraciones ni usar `git add .`.

```powershell
git diff --cached --stat
git diff --cached -- backend/prisma/schema.prisma
git commit -m "fix: completar modelo PomodoroRegistrado de P4-A"
```

Este commit no resuelve por sí solo el pendiente de Guardián ya referenciado en
HEAD. Revisarlo antes de desplegar. No se hicieron commits, push ni operaciones
sobre bases reales automáticamente.
