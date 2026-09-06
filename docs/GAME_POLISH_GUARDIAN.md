# 6F-P — Pulido de juegos, racha y desafío del guardián

Entrega adicional solicitada antes de retomar las etapas de contenido. No cambia
la numeración ni sustituye las tareas pendientes del roadmap.

## Qué cambió

- Duelo fantasma: personaje vectorial con flotación, expresiones y celebración;
  pista con dos carriles en la misma escala de puntos. El rival sigue siendo la
  evolución de un récord limpio anterior, no otro estudiante conectado. La
  primera partida sirve para crear ese récord.
- Trivia Rush: marcador de combo, escudo y respuestas más visible. Una respuesta
  confirmada habilita la pregunta siguiente sin esperar una animación decorativa.
  No se cambiaron las reglas de puntos ni se fabrican recompensas publicitarias.
- Memoria: giro en perspectiva, reverso diseñado, celebración breve al encontrar
  pareja y textos legibles en las cartas ya resueltas.
- Tira y afloja: textura de cuerda, banderín, líneas de movimiento y marcas de
  esfuerzo sobre los personajes existentes. En línea se distingue **enviando**
  de **confirmado** y se identifica al contrincante como **RIVAL**, no CPU.
- Racha: llama de varias capas con núcleo, contornos variables, brillo y chispas;
  encendido al entrar, transición de colores, hielo y ceniza. Se detiene al
  ocultarla, salir de la ruta, enviar la app al fondo o reducir movimiento.

El fondo general sigue blanco en modo claro. Las escenas tienen sus propios
acentos de color; el modo oscuro y las preferencias existentes se conservan.

### Racha: apariencia y reglas reales

| Días | Color |
| --- | --- |
| 1–9 | Naranja |
| 10–19 | Dorado |
| 20–29 | Rojo |
| 30–39 | Violeta |
| 40–49 | Azul |
| 50 o más | Cian / legendaria |

Los botones de adelantar días y simular hielo/apagado siguen restringidos al
modo demo. **El hielo es una previsualización**, no confirma un congelamiento
concedido por el servidor. El contrato actual devuelve `actual` y `activoHoy`:
no haber estudiado todavía hoy no significa perder o congelar una racha vigente.
La racha se apaga cuando el backend informa cero. La gracia real de un día y la
recuperación con anuncios necesitan su contrato backend y AdMob SSV; siguen
pendientes y no se simulan para cuentas reales.

## Nuevo juego: Desafío del guardián

Ruta: **Practicar > Juegos individuales > Desafío del guardián**.

- Selección de área, dificultad y subtema opcional, mostrando su tema padre.
- Se vence con **6 aciertos**; se pierde al cometer **3 errores**. Como máximo
  se usan 8 preguntas. No hay cronómetro de respuesta ni potenciadores.
- Personaje vectorial animado, seis runas de energía, escudo y efectos de impacto
  después de una respuesta confirmada.
- Preguntas con opciones, imágenes y contexto compartido; explicación tras cada
  respuesta y revisión final por tema/subtema.
- Los errores son pistas **de esa partida**, no un diagnóstico definitivo. No
  alteran XP, racha, clasificación ni progreso académico.
- Las cuentas demo usan ejemplos del repositorio demostrativo, que se repiten;
  sus filtros de dificultad/subtema no representan un banco completo. Los filtros
  se aplican realmente al usar la API. Nada demo se envía a Supabase.
- En cuentas reales el intento activo se recupera del servidor durante 24 horas.
  Volver atrás lo conserva; abandonar requiere confirmación. Solo se permite un
  intento activo por estudiante.

### Contrato y protección backend

Implementado en el repositorio **SaberPlus-Backend**, carpeta `backend/src/guardian`:

| Método | Ruta | Uso |
| --- | --- | --- |
| POST | `/guardian/intentos` | Iniciar o recuperar configuración coincidente |
| GET | `/guardian/intentos/activo` | Recuperar el intento activo o devolver vacío |
| GET | `/guardian/intentos/:id` | Sincronizar estado propio |
| POST | `/guardian/intentos/:id/respuestas` | Enviar pregunta, opción y UUID idempotente |
| POST | `/guardian/intentos/:id/abandonar` | Cerrar explícitamente |

Requiere sesión y correo verificado, y rol estudiante. El servidor selecciona
preguntas publicadas con jerarquía publicada y una sola respuesta correcta.
Se necesitan 8 válidas por selección. La selección inicial mezcla un conjunto
acotado de hasta 300 candidatas para limitar el coste de crear una partida.

Una instantánea privada conserva el contenido de cada intento aunque luego se
edite el banco. La API revela solo la pregunta actual y las soluciones de las
preguntas ya respondidas. No acepta puntos, vidas, tiempos ni resultados enviados
por el teléfono. Se serializan operaciones por usuario con bloqueo transaccional,
se añade índice único parcial para un solo intento activo y se protegen los
reintentos con clave idempotente. Flutter conserva esa misma clave si pierde la
confirmación de red. El borrado de cuenta elimina sus intentos en cascada.

La tabla `IntentoGuardian` tiene RLS sin acceso para los roles públicos de
Supabase. No se agregan credenciales a Flutter.

## Activarlo en la nube (pendiente de operación)

Esta entrega **no ejecuta migraciones contra Supabase ni redespliega Render**.
El juego demo se puede probar ahora. Para cuentas reales hace falta publicar el
nuevo módulo, aplicar las migraciones pendientes y tener preguntas autorizadas.

Trabajar en la copia principal, no en la copia antigua bajo `Desktop/SaberPLus`:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend"
.\tool\supabase_database.ps1 -Action status
```

Revisar primero el ambiente de `.env.staging.local`, el respaldo y **todas** las
migraciones pendientes; el comando de despliegue no aplica solo la del guardián.
Cuando se decida aplicar los cambios a desarrollo:

```powershell
.\tool\supabase_database.ps1 -Action deploy -ConfirmDeploy
```

Después publicar el commit del backend y desplegarlo manualmente en Render.
La migración nueva es `20260905180000_guardian_challenge`. El comprobador
`probe_database.mjs --verify-schema` compara ahora las migraciones locales por
nombre, en lugar de asumir permanentemente 39.

## Audio y verificación manual

No se necesitan descargas nuevas. El guardián reutiliza `trivia_correct.mp3`,
`trivia_wrong.mp3`, `match_victory.mp3` y `match_defeat.mp3`, respetando el ajuste
de sonido. La llama no añade audio repetitivo.

Para revisar en un teléfono: probar una victoria y una derrota demo, salir y
volver, texto grande, modo oscuro, reducción de movimiento y la vista previa de
racha. Tras desplegar el backend, probar recuperación después de cerrar la app y
cortar la red justo al responder. Verificar dos clientes reales para Tira y
afloja. Las pruebas locales con clientes inyectados no sustituyen esos ensayos.

Antes de publicar también quedan la revisión de dependencias vulnerables
reportadas por `npm audit`, pruebas de rendimiento en Android y verificación de
compilación iOS en macOS; esta entrega no actualiza dependencias del backend.

## Commits separados

### Verificación de esta entrega

- Backend: compilación y validación de Prisma correctas (validación con URL de
  ejemplo, sin conectar a la base). Batería general: 217 pruebas aprobadas; tras
  añadir tres pruebas HTTP se verificaron las 23 del módulo guardián, todas
  aprobadas. La migración no se ejecutó contra PostgreSQL en esta entrega.
- Flutter: ejecución general con 327 aprobadas y tres pruebas de API real
  omitidas por falta de credenciales de ensayo. El único fallo era la espera
  infinita de la prueba de navegación del fantasma; se ajustó para animación
  continua y desplazamiento, y su reejecución pasó. Después, las 18 pruebas
  conjuntas de guardián y visuales de fantasma/Trivia también pasaron, incluyendo
  las capturas de revisión.
- Análisis focalizado de todos los cambios: sin problemas. El análisis general
  conserva siete advertencias `unawaited_return_in_try_block` en repositorios de
  instituciones no modificados por esta entrega.
- Imágenes de llama clara/oscura, memoria/tira y afloja, fantasma y guardián
  renderizadas e inspeccionadas. Falta validación manual en teléfono.

### Cómo confirmar los cambios

Revisar `git diff` antes de confirmar. No agregar `.env.staging.local` ni otros
secretos. La actualización existente de `pubspec.lock` y `analysis_options.yaml`
no forma parte del código nuevo de juegos; revisarla por separado.

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/GAME_POLISH_GUARDIAN.md lib/app/router.dart lib/core/widgets/animated_streak_flame.dart lib/features/games lib/features/gamification/presentation lib/features/practice/presentation/practice_hub_page.dart test
git commit -m "feat: mejorar juegos y racha y agregar desafio guardian"
```

Backend:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/prisma/schema.prisma backend/prisma/migrations/20260905180000_guardian_challenge backend/src/guardian backend/src/app.module.ts backend/tool/probe_database.mjs
git commit -m "feat: agregar desafio guardian autoritativo"
```

Después retomamos la validación Flutter–staging y **7F-C2-B** (catálogo
administrable por área, tema y subtema), seguida del panel privado **7F-C3**.
