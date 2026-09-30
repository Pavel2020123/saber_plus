# PR-I1 — Auditoría de los ocho juegos y fórmulas propuestas

Fecha: 30 de septiembre de 2026. Estado: **auditoría aceptada, calibración revisada y estructuras congeladas documentalmente; coeficientes POR APROBAR; PR-I1 no cerrado**.
Autoridad de producto: [plan maestro recibido](PLAN_MAESTRO_COMPETITIVO.md), conservado íntegro.
Las cifras de las rondas anteriores se conservan como historial de propuestas y calibración, no como importes aprobados ni `xpRulesVersion` publicado.
No se implementa XP competitivo, ranking, premios ni migraciones en esta entrega.

**Criterio vigente — tercera ronda:** la sección 11 congela las decisiones estructurales confirmadas por el propietario y prevalece sobre propuestas y alternativas anteriores. Las secciones 4 y 10 conservan los cálculos históricos, incluidos los que motivaron rechazos; no son fórmulas para implementar. `floor(S/10)`, el bono de preguntas no utilizadas de Cima, el pago por rondas favorables de Tira y la eficiencia de Memoria que ignora pistas quedan descartados como solución definitiva. **Coeficientes exactos, penalización nominal, tiempos de reconexión e importe de victoria por abandono siguen POR APROBAR.** `xpRulesVersion` no se congela todavía; la congelación es solo estructural y documental.

## 1. Línea base y alcance

| Repositorio | Rama de trabajo / consulta | HEAD auditado |
|---|---|---|
| Flutter `saber_plus` | `docs/pr-i1-auditoria-formulas`, creada desde `main` | `8a1a497f83ed47d089ee5e78cb8c28b7e95e3ba8` |
| `SaberPlus-Backend` | `main`, solo lectura de código y pruebas locales | `fb27225d96376c3867418d9f5a1a53030d2256c0` |

Flutter tenía modificaciones previas en `pubspec.yaml` y `pubspec.lock`; no forman parte de esta entrega. Backend estaba limpio. No se hicieron commits, merge, despliegue, conexión a Supabase ni cambios de producción. Los hallazgos describen código local, no la versión desplegada.

Se revisaron motores, servicios, controladores, esquema Prisma, clientes Flutter y pruebas existentes. Las referencias B de abajo son rutas relativas a `SaberPlus-Backend/backend`; las F son relativas a `saber_plus`. Los números de línea corresponden al HEAD auditado.

## 2. Matriz de funcionamiento y evidencia

| Juego / ID estable propuesto | Cómo termina / victoria y derrota | Qué sabe y verifica el backend | Datos para XP / autoridad actual |
|---|---|---|---|
| Trivia Rush / `trivia_rush` | Tiempo de 60/90/120 s agotado (`EXPIRADO`), banco agotado (`FINALIZADO`) o `ABANDONADO`. No tiene victoria contra rival. | Propietario, pregunta actual, opción, acierto, combo, puntaje, recepción, vencimiento, concesión y consumo de ayuda. | `IntentoTriviaRush`, preguntas, respuestas finales y potenciadores. 100 puntos por acierto con multiplicador 1/2/3/4 desde combos 1/3/6/10. Motor autoritativo, falta contrato competitivo. [B1] |
| Duelo fantasma / `ghost_duel` | Mismo cierre de Trivia; compara contra récord propio por configuración. Primer intento crea referencia. Récord por puntaje, luego aciertos y mejor combo. | Reconstruye el mejor intento limpio y checkpoints desde respuestas servidor. **No sabe si el intento se abrió como Trivia o Duelo ni qué fantasma se enfrentó al inicio.** | Misma tabla de Trivia; `ghostMode` existe en pantalla, no en DTO de creación. Resultado de preguntas verificable; identidad del juego y victoria concreta aún no verificables. [B1, F1] |
| Salto a la cima / `summit` | Victoria al escalón 5; `AGOTADO` tras 12 respuestas sin llegar. Error baja uno, piso cero. También abandono/caducidad 24 h. | Reproduce respuestas confirmadas contra snapshot privado; obtiene escalón final, máximo, aciertos, errores y cierre. | `IntentoCima`, JSON de preguntas/respuestas y versión. Motor autoritativo. No hay tiempo individual de cada respuesta en el JSON actual; no proponer bono de velocidad. [B2] |
| Tira y afloja / `tug_of_war` | Meta ±4; si se agotan preguntas, signo de cuerda decide ganador o empate. Abandono explícito con rival concede victoria al otro; sin rival cancela. | Ambos participantes, listo, ronda, respuestas, llegada, movimiento y resultado. Rondas de 10 s; diferencia ≤200 ms empata rapidez; único acierto mueve 2, ambos correctos y uno más rápido mueve 1. | `PartidaTiraAfloja`, respuestas y eventos versionados. Hasta 20 preguntas, mínimo 4. Motor autoritativo; falta abandono persistente por ausencia y ledger. [B3] |
| Guardián / `guardian` | 6 aciertos ganan; 3 errores pierden; banco de 8 preguntas. Error consume escudo, acierto reduce energía del guardián. Abandono/caducidad 24 h. | Reproduce respuestas verificadas contra snapshot; calcula aciertos, errores, escudo restante y energía. | `IntentoGuardian`, JSON privado, versión y cierre. Motor autoritativo. Escudos son vidas propias del juego, no fraude ni un potenciador comercial. [B4] |
| Memoria / `memory_match` | Termina al encontrar todas las parejas; niveles 6/8/10. No hay rival ni derrota competitiva implementados. | **Nada de la partida**: tablero, `pairId`, movimientos, tiempo, pistas y resultado viven en Flutter. | Flashcards locales, barajado y evaluación local; sin tabla/controlador/servicio de Memoria en backend revisado. No puede acreditar XP competitivo actualmente. [F2] |
| Batallas / `battles` | Ambos finalizan preguntas o pierden vidas en supervivencia. Supervivencia compara vidas, después aciertos y menor tiempo; los otros modos comparan aciertos y tiempo. Igualdad completa empata. | Participación, respuestas secuenciales, aciertos, vidas, tiempos de recepción y liquidación única. | `Batalla`, participantes/respuestas/estadísticas. Modos `CARRERA_FANTASMA` y `DUELO_RELAMPAGO` piden 8 preguntas; `SUPERVIVENCIA`, 10, pero actualmente admite **solo 1** si falta banco. Ese modo Carrera fantasma no es el juego Duelo fantasma. [B5] |
| Rescate de estrellas / `star_rescue` | Acierto da estrella, error no la quita; 6 estrellas ganan; 10 preguntas sin meta da `AGOTADO`; cada 3 estrellas completa constelación. Abandono/caducidad 24 h. | Reproduce respuestas contra snapshot, rechaza respuestas posteriores a victoria y calcula estrellas/constelaciones. | `IntentoRescateEstrellas`, JSON privado, versión y cierre. Motor autoritativo; no hay datos de velocidad necesarios para una fórmula temporal. [B6] |

Hay seis motores de servidor para siete experiencias, pues Duelo comparte Trivia; Memoria es local. **Ninguno tiene todavía el ledger competitivo común requerido.** No confundir autoridad para calificar preguntas con tener lista la economía competitiva.

## 3. Matriz de ayudas, abandono, antifraude y cambios

| Juego | Ayudas reales | Abandono / reconexión actual | Protección existente y cambios necesarios antes de habilitar XP |
|---|---|---|---|
| Trivia Rush | Tiempo +10 s, 50/50, escudo de combo, saltar, segunda oportunidad. Concesión servidor de un uso; Flutter real no fabrica concesiones. | Abandono explícito; cierre al consultar/responder tras vencimiento. No persiste presencia para distinguir desconexión de fin normal del reloj. | Propietario, UUID, comprobación de payload repetido, lock de respuestas, tiempo servidor y soluciones ocultas. Añadir snapshot de preguntas (hoy consulta banco mutable), presencia/cierre durable y hacer abandono bajo el mismo lock que respuestas/vencimiento: hoy hace lectura/update separados. Ayudas válidas conservan XP. |
| Duelo fantasma | UI deshabilita potenciadores; récord actual filtra `asistido=false`. | Hereda Trivia; cierre visual/consulta posterior no fijan rival inicial. | Añadir modo inmutable al crear, referencia servidor al fantasma previo y reglas de comparación congeladas. Impedir doble pago Trivia/Duelo del mismo origen. Bloquear ayuda no permitida en backend, no confiar en ocultar el botón. La exclusión del récord limpio no es una regla global contra ayudas legítimas. |
| Salto a la cima | No hay comodines implementados. | Recuperación de intento, reintento con UUID persistido en cliente; vence a 24 h de forma perezosa al consultar. | Snapshot, bloqueo por usuario, roles, propiedad, secuencia e idempotencia. Añadir inicio competitivo explícito, cierre programado recuperable y registro de motivos. No necesita simular tiempos ni conceder XP a partidas demo. |
| Tira y afloja | No hay potenciadores en contrato online. | Socket.IO permite recuperar conexión hasta 120 s, pero `handleDisconnect` **solo emite presencia**. Expiración de búsqueda 2 min y partida 30 min; no equivalen a derrota por desconexión. | JWT WS, límites de mensajes, propiedad, ronda/tiempo servidor, UUID y locks; eventos de resolución. Añadir snapshot, presencia persistida, conciliación HTTP/WS y cierre por ausencia; diferenciar `PREPARANDO` de partida `ACTIVA` para penalizar solo esta última. No dar victoria si ambos desaparecen sin evidencia del rival presente. |
| Guardián | Sus 3 escudos son mecánica de vidas. | Abandono explícito, recuperación y vencimiento perezoso a 24 h. | Snapshot, propiedad, rol y respuestas idempotentes bajo lock. Añadir cierre durable y metadatos competitivos. Validar rol dentro de la transacción de liquidación: validación actual del servicio es previa al lock. |
| Memoria | Pista muestra una pareja; marca asistida y temporizador local la oculta. | Solo temporizador/UI local; cerrar app no deja una partida servidor. | No existe evidencia autoritativa. Crear sesión online, barajado privado, IDs opacos de fichas (sin `pairId` público), giro secuencial servidor, movimientos/parejas/pistas persistidos y replay idempotente. No enviar todo el tablero oculto al iniciar. Conservar modo local como práctica sin XP. Una pista oficialmente permitida no invalida el resultado. |
| Batallas | No hay contrato de comodines. | Asíncrona de 24 h. `expirarPendientes` cambia estado a `EXPIRADA`; no asigna abandono/ganador al que completó. Cancelar invitación no es abandonar una activa. | Verifica estudiante, membresía de partida, orden y opciones; índices únicos y toma condicional de liquidación. Falta UUID de respuestas/replay, lock consistente de ciclo completo, snapshot y cierre durable con motivo. Su XP actual suma `Usuario.xpTotal` y `xpBatallas`; limita a 5 partidas premiadas y 2 repeticiones en ventana de 24 h. **No reutilizar esa elegibilidad para XP competitivo** ni copiar sus totales históricos. Exigir banco completo 8/10 para nueva modalidad competitiva. |
| Rescate de estrellas | No hay comodines implementados. | Recuperación remota y UUID persistido; abandono explícito y vencimiento perezoso de 24 h. | Snapshot, bloqueo por usuario, propiedad, versión, secuencia e idempotencia; replay rechaza después de victoria. Añadir cierre durable y datos competitivos. |

Los límites de mensajes protegen infraestructura; no son límites diarios de partidas. Repetir rival o jugar mucho no demuestra fraude. Señales de automatización/colusión deben guardar evidencia y permitir revisión/corrección; no sustituir los topes antiguos por otro tope encubierto. Los snapshots evitan que editar el banco cambie la evaluación de una partida en curso.

## 4. Historial de la primera propuesta numérica — no vigente como fórmula definitiva

Esta sección conserva la propuesta que se calibró en la sección 10. Las estructuras vigentes están en la sección 11: los números siguientes no están aprobados y las estructuras descartadas no deben recuperarse de esta tabla. En particular, los importes de victoria por abandono de 20/40 y su equiparación con victoria normal son antecedentes, no decisiones actuales.

### Criterio de diseño

No existe telemetría de producción auditada para calibrar esfuerzo/XP por minuto. Estas fórmulas usan únicamente mecánicas observadas arriba, no afirman un equilibrio ya probado. Los coeficientes son decisiones de diseño propuestas después de la auditoría. Se usa una unidad inicial de 10 XP (ya existe un bono perfecto de 10 en Batallas); ello facilita explicar pasos/objetivos, **no acredita equivalencia de esfuerzo entre juegos**. La suma institucional exige revisar esta diferencia antes de congelar reglas.

Variables siempre calculadas en servidor: `C` aciertos finales únicos; `S` puntaje; `V` vale 1 si victoria validada, 0 en otro caso; `T` vale 1 en empate válido, 0 en otro caso. `V` y `T` son excluyentes. Todos los XP son enteros. No se premian respuestas omitidas, duplicadas o intermedias de segunda oportunidad. Una derrota normal no resta XP. No hay bono global por iniciar, ni límite diario, ni multiplicador por dificultad de preguntas hasta contar con calibración fiable.

| Juego | Acción → evidencia → XP propuesto | Restricciones / ejemplo |
|---|---|---|
| Trivia Rush | Acertar y encadenar → suma de `puntosOtorgados` finales → `floor(S / 10)`. | Mantiene el combo propio del juego: acierto vale 10/20/30/40 XP según multiplicador. Cinco aciertos consecutivos producen 800 puntos → **80 XP**. Error/salto da 0; segunda oportunidad paga solo respuesta final. Ayudas permitidas siguen válidas; tiempo extra puede generar más oportunidades. Cierre normal, no abandono. |
| Duelo fantasma | Aciertos y superar referencia propia → respuestas finales + fantasma fijado al inicio → `10*C + 10*V + 5*T`. | Con 5 aciertos: gana **60**, empata **55**, pierde **50**. Primer fantasma: `V=T=0`, **50**; no inventar rival. Comparar tupla (puntaje, aciertos, mejor combo); igualdad completa empata. El fantasma debe ser el mejor elegible de misma configuración seleccionado por servidor, nunca uno débil elegido por cliente. |
| Salto a la cima | Alcanzar altura y meta eficientemente → replay → `10*H + V*(10 + 5*U)`, con `H` máximo escalón y `U=12-N` preguntas no usadas al ganar. | Subir/bajar repetidamente no vuelve a pagar alturas ya alcanzadas. Victoria en 5 respuestas: `50+10+35` = **95**; victoria en 11: **65**. Agotado con máximo 4: **40**. No bono por aciertos redundantes. |
| Tira y afloja | Aciertos, rondas ganadas y resultado → respuestas/eventos de ronda → `5*C + 10*R + 20*V + 10*T`, `R` rondas cuyo movimiento favorece al jugador. | Movimiento de 2 sigue siendo una ronda ganada, no dos. 2 aciertos y 2 rondas ganadas alcanzando meta: **50**. Derrota con 3 aciertos y 1 ronda: **25**. Empate sin aciertos: **0**, evitando premiar inactividad; bono de empate requiere `C>0`. Victoria por abandono validado: mismo bono 20 más rendimiento realmente registrado, sin inventar rondas/aciertos. |
| Guardián | Dañar guardián y conservar escudos al vencer → replay → `10*C + V*10*E`, `E` escudos restantes. | 6 aciertos sin error: **90**; 6 aciertos/2 errores: **70**. Derrota con 4 aciertos/3 errores: **40**. Escudos restantes solo bonifican victoria, no abandonar temprano. |
| Memoria | Completar tablero y eficiencia de movimientos → futuro registro de giros servidor → `10*P + floor(10*P*P/M)` al completar, `P` parejas asignadas, `M` movimientos válidos (dos giros). | `M>=P`, `P` debe ser exactamente 6/8/10; sin tablero completo no hay recompensa. 6 parejas en 6 movimientos: **120**; en 12: **90**. Pista oficial no anula XP ni cambia artificialmente movimientos; debe registrarse. Sin bono de tiempo local. **Actualmente paga 0 competitivo: falta motor.** |
| Batallas | Resultado y perfección → cierre de ambos participantes → base de victoria **40**, empate **25**, derrota **15**, más **10** si perfecta. | Reutiliza cantidades existentes como propuesta, separando ledger del XP general. Perfección exige acertar las 8/10 preguntas exigidas. Empate/derrota con cero aciertos: **0** (propuesta contra recompensa de inactividad); victoria validada por abandono: **40** + bono perfecto solo si realmente completó y acertó todo. Sin topes por día/rival. |
| Rescate de estrellas | Rescatar y completar constelaciones → replay → `10*S_e + 10*K + 10*V`, con `S_e` estrellas y `K=floor(S_e/3)`. | 6 estrellas / 2 constelaciones / victoria: **90**. Agotado con 5 estrellas: **60**; con 2: **20**. Un error no quita estrellas ni XP. No paga más por prolongar la ronda. |

Decisión vigente: quien abandona no conserva recompensa positiva parcial de esa partida. Se registra evento de abandono/penalización, con piso del balance competitivo en cero. No se suma premio parcial y después una multa. Esta estructura está confirmada; el importe nominal sigue **POR APROBAR**. La victoria del rival por abandono se liquida como tipo separado y no hereda la fórmula ni el importe de una victoria normal.

### Importes históricos propuestos por juego — POR APROBAR

`delta = -min(balanceDisponibleDelJuegoYTemporada, penalizacionNominal)`. Guardar importe nominal y efectivo aunque el efectivo sea cero. El piso evita deuda por abandono; no borra la evidencia. Las correcciones de fraude no usan automáticamente este recorte: deben reconstruir la proyección y resolver dependencias para no dejar XP inválido.

| Juego | Penalización nominal propuesta | Motivo del importe |
|---|---:|---|
| Trivia Rush | 10 | Un acierto sin combo. |
| Duelo fantasma | 10 | Bono propuesto por victoria. |
| Salto a la cima | 10 | Una altura nueva. |
| Tira y afloja | 20 | Bono propuesto de victoria del rival. |
| Guardián | 10 | Un acierto o un escudo de bono. |
| Memoria | 10 | Base propuesta de una pareja. |
| Batallas | 15 | Base histórica/propuesta de derrota con participación. |
| Rescate de estrellas | 10 | Una estrella. |

No penalizar búsqueda sin rival, invitación rechazada, práctica offline, error del servidor ni sesión aún no iniciada competitivamente. Una derrota por rendimiento no usa esta tabla. No atribuir abandono por un fallo de la aplicación observado solo en cliente.

## 5. Reconexión propuesta y resolución de ausencias

Los plazos siguientes siguen siendo propuestas, no tiempos aprobados. En todos los casos prevalece la decisión confirmada de la sección 11: victoria por abandono solo con evidencia servidor de partida competitiva activa, participación válida, presencia suficiente y abandono definitivo del rival. Si ambos están ausentes sin evidencia suficiente de un jugador presente, no hay ganador ni recompensa positiva; cada abandono se procesa según evidencia individual.

| Juego | Política propuesta, aún no implementada |
|---|---|
| Trivia / Duelo | Latido autenticado cada 5 s; hasta 15 s desde último contacto confirmado. Reloj continúa. Si vuelve dentro del margen, recupera estado. Si el reloj termina durante el margen, mantener cierre pendiente hasta retorno o plazo: retorno dentro del margen valida fin normal; ausencia definitiva produce abandono. Banco agotado antes de desconectar ya es cierre normal. |
| Tira y afloja | Latido cada 5 s y gracia de 30 s desde último contacto (tres rondas actuales). Reloj no se pausa. Un resultado que se produciría mientras está pendiente la gracia se guarda provisionalmente; se concilia al volver o vencer plazo. Victoria por abandono condicionada a las cuatro evidencias indicadas arriba. Ambos ausentes sin presencia suficiente acreditada: sin ganador/recompensa positiva; procesar cada abandono según su evidencia, no sancionar automáticamente a ambos. Recuperación Socket.IO de 120 s no aprueba ni altera por sí sola el plazo competitivo propuesto. |
| Cima / Guardián / Rescate | Son sesiones sin cronómetro de respuesta. Mantener la ventana existente de 24 h desde creación para reconectar; no introducir una sanción a los 15 s. Si nunca vuelve y queda activa al vencimiento: abandono competitivo, no victoria. El resultado ya finalizado por servidor permanece finalizado aunque falle la entrega al teléfono. |
| Memoria online nueva | Proponer 60 s de gracia, con latido cada 5 s; recuperar tablero servidor. No se premia velocidad, por lo que no hay ventaja de XP por pausa. El plazo total de sesión debe configurarse y aprobarse junto al motor, propuesta inicial 24 h para no dejar sesiones huérfanas. |
| Batallas | Propuesta de conservar vencimiento asíncrono de 24 h sin exigir conexión permanente. Haber completado preguntas no sustituye la validación servidor de participación, presencia suficiente y abandono definitivo del rival en una partida competitiva activa. Ambos ausentes sin evidencia suficiente de un jugador presente: sin ganador ni premio; procesar abandonos según evidencia individual. Invitación nunca aceptada expira sin XP ni sanción. |

La elección de 15/30/60 s es una propuesta técnica ajustada al ritmo, no una garantía de red probada en dispositivos. Requiere ensayo de latencia antes de activación. La recepción servidor fija el plazo y orden; cierre normal anterior a ausencia gana precedencia. Fallos conocidos del servicio producen cierre técnico sin sanción, auditado. Un worker durable debe recuperar plazos tras reinicio, serializar retorno/abandono/respuesta y procesar cada cierre una sola vez. Sesión expirada requiere autenticarse para recuperar; no aceptar latidos fabricados ni atribuir un socket desconectado a pérdida definitiva si existe otra conexión válida.

## 6. Contrato común propuesto para completar PR-I1 después de revisión

No crear endpoint que acepte XP, ganador, institución o año decididos por Flutter. El inicio solicita modo/configuración y el backend fija `gameId`, `competitive`, `gameRulesVersion`, futuro `xpRulesVersion`, propietario, origen y fechas. El cierre/verificador interno obtiene evidencia persistida; el cliente solo envía respuestas o referencia al intento. Separar versiones de motor existentes de la nueva versión de fórmula.

Ledger propuesto: usuario, juego, temporada, tipo (`RESULTADO`, `ABANDONO`, `CORRECCION`), delta entero, balance anterior/posterior, fuente tipada e ID, clave de liquidación única por fuente/participante, versión de fórmula, evidencia/revisión, fecha efectiva servidor, fecha de registro, institución histórica, motivo y evento corregido. Usuario/partida no se borran en cascada sin política de retención que preserve auditoría. Nunca UPDATE silencioso de importes históricos: correcciones mediante eventos vinculados y autorización administrativa con motivo.

La clave única de premio **no debe incluir `rulesVersion`** como vía para pagar otra vez al cambiar fórmula. Trivia/Duelo deben compartir exclusión de pago por intento/participante aunque tengan distinto `gameId`. Cada respuesta necesita su propia clave y validación de payload; no basta la idempotencia del premio final. Transacción única: validar rol/evidencia/cierre, tomar lock del balance, crear evento y actualizar proyección. Reintento devuelve evento existente; un worker/outbox recupera cierres no liquidados.

Balance como proyección: único `(usuarioId, gameId, temporada)`, XP y `alcanzadoEn`. XP total competitivo es suma de los ocho, nunca `Usuario.xpTotal`. **Decisión confirmada:** cualquier delta competitivo efectivo distinto de cero que cambie el balance actualiza `alcanzadoEn`, incluyendo resultado, penalización o corrección; delta cero no lo modifica. Volver a un total tras pérdida lo alcanza de nuevo al cambiar el balance, sin rescatar una fecha anterior por coincidir el importe. Guardar suficiente ledger para reproducirlo. Desempate futuro: XP descendente, fecha ascendente, ID estable. No implementar ranking en esta entrega.

Temporada anual `America/Bogota`: 2026 comprende `[2026-01-01T05:00:00Z, 2027-01-01T05:00:00Z)`. **Decisión confirmada:** la fecha servidor del resultado terminal determina año, aunque se registre después; una partida que cruza de año pertenece íntegramente al año de su resultado terminal. Worker tardío usa fecha terminal real, no hora de ejecución; corrección conserva la temporada del evento original. Se documentan sus efectos en la sección 11; esta confirmación no autoriza implementar. La activación inicia una temporada parcial; no convertir `xpBatallas`, `xpTotal` ni intentos no distinguibles en XP retroactivo. Cualquier recuperación histórica exige evidencia y revisión explícitas.

Institución: el esquema tiene `Usuario.institucionId` mutable y `MiembroInstitucion` único por usuario sin `leftAt`; no basta para reconstruir pertenencia. **Decisión confirmada:** atribuir XP institucional a la membresía válida en la fecha servidor del resultado terminal. Registrar esa pertenencia en el evento bajo coordinación transaccional con cambios de institución; una liquidación posterior consulta historial, nunca `Usuario.institucionId` actual como sustituto. El XP ya devengado en A nunca se transfiere al pasar a B; corrección del evento conserva A. Usuario sin institución registra null y compite igual. Se atribuye el premio completo al cierre, sin repartir acciones intermedias; la sección 11 explica su efecto. No se implementa historial ni atribución en esta entrega.

Privacidad: contrato público futuro por lista de campos permitidos (alias, avatar público autorizado, juego, temporada, XP, posición provisional); sin correo, respuestas, diagnóstico, progreso académico, IDs internos de rival ni nombre oculto. La identidad real solo se expone en administración institucional autorizada. Falta modelar alias/visibilidad para PR-I4; no usar correo/nombre como alias provisional. Profesores/administradores nunca reciben balance competitivo; verificar rol vigente al liquidar y definir tratamiento de cambio de rol sin destruir historial.

Conservar XP general actual de Batallas y otras actividades sin alterarlo en PR-I1. Nueva elegibilidad competitiva no llama `esXpElegible` legado; pruebas deben demostrar que la sexta partida y tercera repetición válidas sí pagan competitivo. No duplicar el abono general al integrar el verificador. Los 90 assets son catálogo, no propiedad; cierre anual, bandas TOP 50, revocaciones e historial pertenecen a PR-I3 tras PR-I2 aprobado. Escudo y Taller no se reactivan; instituciones no es un noveno juego.

## 7. Evidencia de código reproducible

| Ref. | Archivos y puntos de revisión |
|---|---|
| B1 | `src/trivia-rush/trivia-rush.rules.ts:1` (score); `trivia-rush.service.ts:210` (fantasma), `:300` (respuesta), `:527` (finalizar), `:542` (abandono); `trivia-rush.controller.ts:35` (creación sin modo). |
| B2 | `src/summit/summit.rules.ts:1`; `summit.service.ts:44` (lock/rol), `:161` (snapshot), `:209` (respuesta), `:294` (caducidad). |
| B3 | `src/tira-afloja/tira-afloja.rules.ts:1`; `tira-afloja.service.ts:27` (plazos), `:348` (respuesta), `:431` (abandono), `:482` (vencimiento), `:565` (ronda); `tira-afloja.gateway.ts`, funciones `handleDisconnect` y `latido`. |
| B4 | `src/guardian/guardian.rules.ts:1`; `guardian.service.ts:37` (rol/lock), `:170` (respuesta), `:244` (caducidad). |
| B5 | `src/batallas/batallas.service.ts:22` (límites/modos), `:294` (respuesta sin UUID), `:692` (banco), `:716` (liquidación), `:811` (elegibilidad), `:894` (ganador), `:1118` (expiración). |
| B6 | `src/star-rescue/star-rescue.rules.ts:1`; `star-rescue.service.ts:44` (lock), `:210` (respuesta), `:295` (caducidad). |
| B7 | `prisma/schema.prisma`: `Usuario`, `MiembroInstitucion`, modelos de Batallas/Tira/Trivia e `IntentoGuardian`, `IntentoCima`, `IntentoRescateEstrellas`. No modelo de ledger competitivo ni Memoria. |
| F1 | `lib/features/games/trivia_rush/data/remote_trivia_rush_repository.dart:20`; `trivia_rush/presentation/trivia_rush_page.dart:90`; `ghost_duel/data/remote_ghost_duel_repository.dart:21`. |
| F2 | `lib/features/games/memory_match/domain/memory_match_models.dart` (`buildMemoryMatchDeck`); `presentation/memory_match_page.dart:80` (comparación local), `:123` (pista). |

Los documentos históricos de Memoria/Duelo excluyen partidas asistidas de récords limpios. Eso no autoriza excluir automáticamente del nuevo ranking competitivo todas las ayudas legítimas. El plan maestro actual tiene prioridad. Las fórmulas anteriores no cambian esas funciones históricas por sí solas.

## 8. Verificación y pendientes de implementación

Regresión dirigida ejecutada el 30 de septiembre: **84 pruebas backend en 15 suites y 69 pruebas Flutter aprobadas**, ambos procesos con código 0. Son pruebas existentes de motores, contratos, privacidad y clientes con dobles de prueba; no son validación de PostgreSQL real, producción ni de las fórmulas propuestas. No se ejecutó la suite completa ni se escribieron tests que pretendan certificar fórmulas aún no aprobadas.

Comandos reproducibles, desde cada repositorio correspondiente:

```powershell
# SaberPlus-Backend/backend
node node_modules/jest/bin/jest.js --runInBand --silent --testPathPatterns='trivia-rush|guardian|summit|star-rescue|tira-afloja|batallas'

# saber_plus
flutter test test/memory_match_test.dart test/ghost_duel_test.dart test/remote_ghost_duel_repository_test.dart test/remote_trivia_rush_repository_test.dart test/guardian_test.dart test/remote_summit_repository_test.dart test/remote_star_rescue_repository_test.dart test/tug_online_test.dart test/async_battles_test.dart --reporter compact
```

Para cerrar PR-I1 posteriormente hacen falta migraciones, ledger/proyección, verificadores de los ocho juegos, contrato de Memoria, distinción Duelo/Trivia, presencia/cierre durable, seguridad y pruebas reales de concurrencia sobre PostgreSQL temporal aislado. Pruebas de aceptación pendientes: fraude de payload, fuente inexistente/ajena, UUID duplicado y conflictivo, doble liquidación, caída entre cierre y crédito, respuesta contra abandono, ayuda válida, rol no estudiante, offline sin XP, cambio de institución durante partida y liquidación demorada, corrección/piso/fecha de alcance, límite Bogotá, versiones y preservación del XP general. Las pruebas actuales no acreditan esos componentes nuevos.

## 9. Entrega y decisión solicitada

Archivos propios: este informe; copia íntegra `PLAN_MAESTRO_COMPETITIVO.md`; enlaces de estado en índice, etapas y relevo. Migraciones, endpoints ejecutables, servicios y contratos de runtime modificados: **ninguno**. Las rutas existentes auditadas son `/trivia-rush/intentos` y `/trivia-rush/fantasma`, `/salto-cima/intentos`, `/tira-afloja`, `/guardian/intentos`, `/batallas`, `/rescate-estrellas/intentos`; Memoria aún no tiene API.

El plan maestro conserva el encargo original; la sección 11 registra las decisiones estructurales vigentes de la tercera ronda. La primera referencia del Duelo sin bono, el abandono sin premio parcial, ambos ausentes sin ganador, `alcanzadoEn`, temporada e institución ya no son decisiones abiertas. Quedan exactamente cuatro grupos pendientes: coeficientes exactos de XP de los ocho juegos; penalización nominal por abandono; tiempos de reconexión por juego; importe de victoria validada por abandono.

**Punto de revisión:** aprobar o ajustar estas propuestas antes de programar/congelar `xpRulesVersion`. No pasar a PR-I2. Esta pausa procede expresamente de «El propietario revisará esa matriz y aprobará las fórmulas antes de implementar el sistema competitivo definitivo» en el plan recibido; no es una aprobación adicional inventada.

## 10. Historial de calibración — segunda ronda revisada, importes NO aprobados

**Lectura histórica:** los escenarios y alternativas siguientes explican las decisiones posteriores; no representan las estructuras vigentes. La sección 11 descarta `floor(S/10)`, U en Cima, R en Tira (también `min(R,4)`) y eficiencia que ignore pistas en Memoria, y separa victoria normal de victoria por abandono. Los máximos numéricos calculados aquí no son techos aprobados del futuro sistema.

### 10.1 Método y límites de la comparación

Los escenarios bajo/medio/alto son **casos sintéticos válidos**, no percentiles de estudiantes ni predicciones de rendimiento. «Medio» identifica un ejemplo intermedio, no una media medida. Son cierres normales salvo donde se indica abandono; ningún importe es XP competitivo que el runtime entregue hoy. En particular, Memoria local sigue concediendo **0 XP competitivo**.

`N` cuenta preguntas efectivamente respondidas por ese jugador, no el tamaño del banco; `C/E` son aciertos/errores. En Memoria un movimiento son dos giros, no dos preguntas académicas. XP/pregunta significa XP total dividido por N, incluyendo bonos; XP/pareja usa parejas completadas. No se equipara cognitivamente una pareja con una pregunta, una ronda o un acierto. Redondeo de cocientes: dos decimales; la fórmula de XP solo redondea donde lo indica `floor`.

**Sin telemetría** de duración humana, latencia, dificultad efectiva, ayudas disponibles, tasa de acierto ni espera de rival. Hay cronómetros/plazos y algunas esperas de interfaz, que se distinguen abajo. No inferir XP/min reales de un vencimiento de 24 h, de la duración nominal de Trivia o de una animación. Ningún resultado permite afirmar cuál domina por minuto en uso real.

### 10.2 Escenarios de los ocho juegos

| Juego | Bajo: acciones → XP → ratio | Medio: acciones → XP → ratio | Alto/perfecto: acciones → XP → ratio | Duración/acciones sustentadas en reglas |
|---|---|---|---|---|
| Trivia Rush | `CECECE`, 3 aciertos aislados, N=6 y cierre por reloj → **30** → **5/pregunta**, 10/acierto. | 10 aciertos seguidos, N=10 y cierre por reloj → **240** → **24/pregunta**. | 30 seguidos, banco completo agotado → **1.040** → **34,67/pregunta**. | 60/90/120 s nominales, más 10 s por tiempo extra válido; puede cerrar antes por banco agotado. Hasta 30 preguntas. Duración real y viabilidad de 30 aciertos dentro del reloj: **sin telemetría**. |
| Duelo fantasma | N=6, 3 aciertos, pierde contra referencia mejor → **30** → **5/pregunta**. | N=10, 10 seguidos y supera fantasma previo de 9 aciertos → **110** → **11/pregunta**. | N=30, 30 seguidos y supera referencia inferior → **310** → **10,33/pregunta**. Si iguala un fantasma ya perfecto: **305**; si no había fantasma: **300**. | Hereda 60/90/120 s y hasta 30 preguntas, sin ayudas en este modo actual. Primer intento también puede ser de 30 aciertos. Duración efectiva: **sin telemetría**. |
| Salto a la cima | `C` y 11 errores, N=12, máximo H=1, agotado → **10** → **0,83/pregunta**, 10/altura máxima. | `CCECCECCC`, N=9, C=7/E=2, victoria, H=5/U=3 → **75** → **8,33/pregunta**, 15/escalón objetivo. | `CCCCC`, N=5, H=5/U=7 → **95** → **19/pregunta**, 19/escalón objetivo. | 5–12 respuestas para victoria; hasta 12 para agotado. Errores en piso pueden permitir victoria con N par; no imponer paridad falsa. Sin reloj de pregunta, ventana de 24 h; duración real **sin telemetría**. |
| Tira y afloja | N=3: ambos correctos y rival más rápido dos veces, después solo rival correcto (`-1,-1,-2`): C=2/R=0, derrota → **10** → **3,33/pregunta propia**. | N=4: ambos correctos, jugador más rápido siempre (`+1,+1,+1,+1`): C=4/R=4, victoria → **80** → **20/pregunta**. | Alto de XP: N=20, C=20/R=12, movimientos `+1,+1,(-1,+1)×8,+1,+1`, victoria → **240** → **12/pregunta**. Perfecto rápido: N=2, solo jugador acierta (`+2,+2`) → **50** → **25/pregunta**. | Rondas de hasta 10 s, inicio 3 s y pausa 1,5 s entre rondas; resolución temprana cuando ambos respondieron. En n rondas, calendario nominal desde inicio activo: `3+1,5*(n-1)+sum(t_ronda)`, sin espera de emparejar, red ni retrasos del worker. Para 2/4/20 rondas, término nominal máximo 24,5/47,5/231,5 s; no son SLA ni duraciones observadas. **Sin telemetría**. |
| Guardián | `CEEE`, N=4, C=1/E=3, derrota → **10** → **2,50/pregunta**. | `CCCECCC`, N=7, C=6/E=1, 2 escudos, victoria → **80** → **11,43/pregunta**, 13,33/acierto objetivo. | 6 seguidos, N=6, 3 escudos → **90** → **15/pregunta y acierto objetivo**. | Cierre entre 3 respuestas (derrota sin aciertos) y 8; victoria en 6–8. Ventana 24 h, duración real **sin telemetría**. |
| Memoria | Tablero completo con M=3P: P=6/8/10 → **80/106/133** XP; detalle de giros y ratios en 10.3. | Completo con M=2P: P=6/8/10 → **90/120/150**. | Completo sin fallar, M=P: P=6/8/10 → **120/160/200**; **20/pareja**, **10/giro** en los tres niveles. | No tiene límite de movimientos ni cronómetro servidor hoy. Son 2M giros; leer/pensar y futura latencia **sin telemetría**. Las esperas locales no son evidencia competitiva. |
| Batallas | Carrera/Relámpago: C=1/E=7 y derrota → **15**, **1,88/pregunta**. Supervivencia: C=1/E=3, N=4, rival mejor → **15**, **3,75/pregunta**. | Carrera/Relámpago: C=4/E=4, gana a rival con 3 aciertos → **40**, **5/pregunta**. Supervivencia: C=2/E=3, N=5, gana a rival C=1/E=3 → **40**, **8/pregunta**. | Carrera/Relámpago: 8/8 y victoria → **50**, **6,25/pregunta**. Supervivencia: 10/10 y victoria → **50**, **5/pregunta**. | Dos participantes asíncronos; cada uno 8 respuestas en Carrera/Relámpago, 3–10 en Supervivencia; ambos deben cerrar. Ventana 24 h no mide trabajo. El tiempo almacenado se redondea y acota a 1–3.600 s por respuesta: no es una espera mínima impuesta. **Sin telemetría**. |
| Rescate de estrellas | C=2/E=8, N=10, 0 constelaciones, agotado → **20** → **2/pregunta**, 10/estrella. | C=3/E=7, N=10, 1 constelación, agotado → **40** → **4/pregunta**, 13,33/estrella. | C=6/E=0, N=6, 2 constelaciones y victoria → **90** → **15/pregunta y estrella**. | Victoria en 6–10 preguntas; agotado en 10. Ventana 24 h; duración real **sin telemetría**. |

Números de cierre y secuencias importan: no se puede simular 12 preguntas en Cima si la quinta ya ganó, ni seguir sumando aciertos en Guardián después del sexto, ni farmear estrellas después de la sexta. En Tira, los 20 aciertos del caso alto no implican ganar todas las rondas: el rival acertó también y alternó la ventaja de tiempo.

### 10.3 Memoria: separación explícita de niveles y pistas

| Parejas P | Bajo M=3P: movimientos / giros / XP | XP/pareja; XP/movimiento | Medio M=2P: movimientos / giros / XP | XP/pareja; XP/movimiento | Perfecto M=P: movimientos / giros / XP |
|---|---|---|---|---|---|
| 6 | 18 / 36 / **80** | 13,33; 4,44 | 12 / 24 / **90** | 15; 7,50 | 6 / 12 / **120** |
| 8 | 24 / 48 / **106** | 13,25; 4,42 | 16 / 32 / **120** | 15; 7,50 | 8 / 16 / **160** |
| 10 | 30 / 60 / **133** | 13,30; 4,43 | 20 / 40 / **150** | 15; 7,50 | 10 / 20 / **200** |

La fórmula escala casi linealmente a igual eficiencia `M/P`: no paga más por pareja en difícil. Sí exige recordar un tablero mayor, dificultad no cuantificada. Por eso fácil podría ser más rentable por tiempo/precisión, pese a que difícil paga más por partida; **sin telemetría** no se puede resolver esa comparación. Selección por área/tipo y familiaridad con las flashcards también cambian el esfuerzo sin alterar XP.

En la UI actual cada pareja acertada espera 450 ms y cada fallo 850 ms: esperas acumuladas `0,45P+0,85(M-P)` segundos. Para P=6/8/10 son **12,9/17,2/21,5 s** en el caso bajo, **7,8/10,4/13 s** en el medio y **2,7/3,6/4,5 s** en el perfecto. Son solamente esperas del código Flutter, excluyen todos los toques/lectura/red y no deben convertirse en XP/min ni imponerse como autoridad futura.

Cada pista actual revela una pareja 1.200 ms sin sumar movimiento. Con pistas suficientes, el jugador puede aprender una pareja y luego acertarla, repitiendo hasta M=P: mantiene el **máximo 120/160/200** y añade P pistas/esperas. Eso no es fraude si la ayuda está permitida; sí reduce la dificultad efectiva que la fórmula de eficiencia pretende medir. No excluir al asistido ni asumir que AdMob/derechos de pistas ya funcionan. El diseño de autoridad servidor debe verificar concesión/uso, y el producto debe decidir si ese incentivo es aceptable.

### 10.4 Efectos específicos de combos, objetivos, modos y referencia

**Trivia.** Para k aciertos consecutivos el XP es `10*min(k,2) + 20*min(max(k-2,0),3) + 30*min(max(k-5,0),4) + 40*max(k-9,0)`. Con 4/5/6/8/10/15/30 aciertos da **60/80/110/170/240/440/1.040**. El salto de marginal 10 a 40 multiplica por cuatro el premio de un acierto tardío. A partir del décimo, el incremento de una sola pregunta ya iguala una victoria no perfecta de Batallas.

Un error sin escudo rompe combo; el escudo puede conservarlo; la segunda oportunidad puede rescatar un acierto; 50/50 facilita acertar; saltar no aumenta XP y conserva combo según el motor actual. Tiempo extra amplía oportunidades pero **no añade preguntas** al banco de máximo 30, por lo que no vuelve infinito el XP por partida. Sin límite global de ayudas, la duración no tiene un techo simple de 120 s en el contrato revisado; depende de concesiones y expiración. La duración 120 s ofrece más oportunidad que 60 s con la misma fórmula; no afirmar que dobla XP. El banco varía entre 4 y 30: techo de partida de **60 a 1.040**, diferencia de oferta además de habilidad. El selector intenta 10 preguntas por dificultad y rellena según disponibilidad, no certifica idéntica dificultad entre partidas.

**Cima.** Bono de preguntas no utilizadas: 5 XP por cada pregunta ahorrada al vencer, además del máximo alcanzado y victoria. N=5/9/12 con victoria da **95/75/60** y **19/8,33/5 XP por pregunta**. El perfecto combina mayor premio con menos trabajo; una pregunta adicional reduce premio en 5. El techo de agotado es **40** (H=4); llegar finalmente a meta al intento 12 da **60**. Fallar en la base no genera altura y oscilar no aumenta H, pero buscar preguntas conocidas/fáciles maximiza repetibilidad del perfecto. Eso es optimización de una regla, no prueba de fraude.

**Guardián.** Victoria con 0/1/2 errores conserva 3/2/1 escudos: **90/80/70** XP en 6/7/8 preguntas, ratios **15/11,43/8,75**. Derrota con hasta 5 aciertos paga como máximo **50**, después del tercer error. Hay doble ventaja del perfecto —más escudos y menos preguntas—, pero el efecto es menor que el de Cima. Dificultad seleccionada no multiplica XP; elegir un nivel más fácil podría mejorar rentabilidad, **sin telemetría** para cuantificarla.

**Batallas.** `CARRERA_FANTASMA` y `DUELO_RELAMPAGO` tienen el mismo número de preguntas y criterio de desempate en el servicio auditado; no atribuirles una diferencia económica que el código no establece. Supervivencia puede cerrar pronto con 3 errores, y vidas precede a aciertos. Gana con C=2/E=3 frente a C=1/E=3, cobrando **40 por solo 5 preguntas**, mientras una victoria perfecta de ese modo exige 10 para **50**. A igual perfección, ambos modos de 8 pagan **6,25/pregunta** y Supervivencia **5**: 25% más por pregunta en los de 8, sin afirmar igual dificultad.

Caso importante de la propuesta actual: la excepción de cero aciertos solo menciona empate/derrota. Si ambos tienen C=0, el desempate temporal puede declarar ganador a uno; ese ganador recibiría **40**, el otro 0. En Supervivencia bastan **3 errores por jugador** (6 respuestas entre ambos) para ese resultado: **13,33 XP por pregunta del ganador** sin aprendizaje acreditado. En Carrera/Relámpago son 8 errores por jugador: **5/pregunta del ganador**. Es un incentivo concreto a resultados vacíos/colusión, no una acusación contra jugadores repetidos. En los ejemplos de tablas, los rivales no son perfectos; si ambos son perfectos, ganar/empatar/perder paga **50/35/25**, aunque ambos acertaron todo. Un abandono validado añade otra vía: el rival que permanece puede recibir 40 incluso sin haber respondido; necesita evidencia firme de inicio y presencia, y no debe mezclarse con derrota normal.

**Rescate.** Estrellas 0/1/2/3/4/5/6 dan **0/10/20/40/50/60/90**. La tercera añade 20 y la sexta 30 (estrella, segunda constelación y victoria): recompensa de hitos, no XP uniforme por acierto. Seis aciertos pagan **90** tanto con N=6 como con N=10: ratios **15 frente a 9/pregunta**. Errores no reducen XP final de una victoria, mientras sí reducen el de Guardián. No hay premio por repetir constelaciones dentro de una partida: cierra al llegar a dos.

**Tira.** La fórmula paga aciertos y cada ronda favorable incluso si después se pierde ese avance. Ganar rápido con dos movimientos de 2 paga **50**; ganar con cuatro movimientos de 1 paga **80**; alternar ventaja hasta 20 puede pagar **240**. El premio bruto incentiva alargar/recuperar terreno; el premio por pregunta favorece el cierre rápido (**25 frente a 20 frente a 12**). Por tanto no concluir que prolongar domina por tiempo. Si ambos aciertan y alternan exactamente ±1 diez veces, acaban empatados con C=20/R=10 cada uno: **210 cada uno**, **420 combinados**, frente a **50 combinados** en victoria de dos rondas contra un rival que falla todo. Requiere cooperación para fabricarlo, pero una partida reñida legítima también puede producirlo; no bloquearla solo por esa secuencia.

**Duelo.** El fantasma se fija al inicio, con misma configuración y mejor registro elegible; no se selecciona uno inferior a voluntad. N=10/C=10 paga **100** sin fantasma, **110** al superar uno inferior, **105** al igualar perfecto de diez y **100** al perder contra uno superior. Los 10 de victoria no se multiplican por diferencia de puntaje: no hay bono por ganar por mucho. Crear referencias débiles por área/duración ofrece una victoria posterior relativamente fácil, pero la primera partida no paga ese bono y el mejor fantasma crece; no se debe reiniciar la referencia con cada partida. La dificultad del rival propio no afecta los 10 por acierto. Una vez fijado un récord perfecto de 30, repetirlo paga **305**, no 310. En el mismo rendimiento de 30 aciertos sin ayudas, Trivia paga 1.040: **3,35 veces** el máximo de Duelo (310) por las mismas preguntas calificadas. Es una asimetría demostrable de fórmula, sin inferir duración real.

### 10.5 Límites naturales, farming y comparación con los otros siete

Los techos siguientes se derivan del número de preguntas/objetivos y del cierre real. **No son topes diarios ni coeficientes aprobados.** El techo es por jugador y partida; suma de dos jugadores solo donde se explicita.

| Juego | Límite natural de XP de la propuesta | Estrategias/incentivos que revisar | Comparación dentro del conjunto de ocho |
|---|---|---|---|
| Trivia | **1.040** con 30 consecutivas; para banco de K≤30, fórmula de k en 10.4. Ayudas no amplían K. | Mantener combo con ayudas oficiales, duración larga, contenido conocido; banco pequeño reduce techo y permite más cierres. Manipulación de concesiones sería fraude; usar concesión válida no. | Mayor techo de los ocho; a igual secuencia de 10 perfectas paga 240 frente a Duelo 110. Ya 6 perfectas dan 110, más que techo Cima 95, Guardián/Rescate 90 y Batallas 50, aunque sus tareas no son idénticas. |
| Duelo | **310** si vence referencia inferior con 30; **305** empate perfecto, **300** primer récord. | Elegir configuración conocida, preparar primer récord débil, repetir contra su mejor marca. Fijar referencia evita cambiar rival al cierre y reutilizar intento como Trivia. | Segundo techo, por debajo de Trivia y encima de Tira 240, Memoria 200, Cima 95, Guardián/Rescate 90 y Batallas 50. No es el segundo por minuto demostrado. |
| Cima | **95**, victoria en 5; agotado ≤40. | Repetir filtros fáciles/conocidos para ganar en 5; el bono U aumenta la ventaja del acierto temprano. No se repremia subir el mismo escalón. | Techo menor que Trivia/Duelo/Tira/Memoria y mayor que Guardián/Rescate/Batallas. Perfecto 19/pregunta frente a 15 en Guardián/Rescate y 6,25/5 en Batallas. |
| Tira | **240** con 20 rondas y final válido, no 320: meta ±4 impide ganar las 20 seguidas. | Alternar terreno para acumular R, sincronizar aciertos, abandonos acordados. Separar observación de sanción y verificar rival/presencia. | Techo tercero, inferior a Trivia/Duelo y superior a Memoria/Cima/Guardián/Rescate/Batallas. Dos rondas ganadas pagan tanto como una victoria perfecta en Batallas; requiere comparar también rival y tiempo, desconocidos. |
| Guardián | **90** perfecto; victoria mínima 70; derrota ≤50. | Elegir dificultad asequible, repetir preguntas conocidas, conservar escudos. No hay escudos comerciales que comprar en este motor. | Por debajo de Trivia/Duelo/Tira/Memoria/Cima; empata techo Rescate y supera Batallas. Con errores, Rescate puede pagar más por iguales 6 aciertos; Guardián paga por supervivencia. |
| Memoria | P=6/8/10: **120/160/200**. Sin tope de M, al completar XP es al menos 10P y el bono tiende a 0; no hay premio por tablero incompleto. | Repetir flashcards conocidas; aprovechar pistas legales sin aumentar M; fácil puede ser más eficiente. Exponer `pairId` o barajado al cliente haría trivial la automatización: es el bloqueo técnico previo, no un comportamiento a aceptar como competitivo. | Techo máximo debajo de Trivia/Duelo/Tira, encima de Cima/Guardián/Rescate/Batallas. Incluso fácil perfecto 120 supera techos de esos cuatro. No equiparar 12 giros con 12 preguntas. |
| Batallas | **50** en los tres modos; perfecto empate 35 y derrota 25. Banco completo aprobado: no usar el legado de una pregunta. | Cero aciertos + desempate temporal; cierre corto en Supervivencia; victorias/abandono coordinados. No reintroducir límites diarios/de rival como solución. | Menor techo de todos; también menor XP por pregunta perfecta. Pero Supervivencia con 0 aciertos puede pagar 40 por 3 respuestas fallidas: bajo esfuerzo posible, no reflejado en el techo. |
| Rescate | **90** con 6 estrellas/2 constelaciones; agotado ≤60. | Optimizar banco/filtros, buscar hitos de tercera/sexta estrella; errores tolerados no bajan recompensa de victoria. No se puede abandonar en 3 para cobrar 40: debe cerrar normalmente. | Techo igual a Guardián, mayor que Batallas y menor que los otros cinco. En victoria con 2 errores: 90/8 frente a Guardián 70/8; Cima depende de secuencia, no solo aciertos. |

Prueba del techo de Tira: explorar los estados de posición -3…3 por ronda, con movimientos válidos -2/-1/0/+1/+2 y el acierto propio asociado; cerrar al tocar ±4 o agotar banco. Maximizar `5C+10R+20V+10T` hasta 20 da **240**, alcanzable por la secuencia de 10.2. No usar el límite ingenuo `5*20+10*20+20=320`, que viola cierre temprano. Con 20 rondas, 12 favorables y 8 desfavorables de un paso se llega a +4 sin victoria anterior.

**Diagnóstico comparativo:** hay dominancia de importe/pregunta de Trivia sobre Duelo para rachas suficientemente largas con el mismo contenido; Cima favorece especialmente el perfecto corto; Memoria escala por tamaño sin compensar dificultad de recordar más fichas; Batallas penaliza económicamente la perfección en Supervivencia respecto de sus modos de 8 pero puede premiar fallar rápido; Tira tiene incentivo bruto a alargar, y Rescate tolera errores más que Guardián. Ninguna de estas relaciones prueba dominancia de facilidad o XP/min reales. Esas conclusiones requieren telemetría futura de práctica/piloto, no inventada en esta ronda. La suma institucional puede inclinar esfuerzo hacia los juegos más rentables, aunque los rankings individuales estén separados.

### 10.6 Alternativas explícitas para discutir, sin sustituir coeficientes

Estas opciones conservan la sensibilidad matemática de la segunda ronda, **no una lista vigente de fórmulas aprobadas** ni cambios al runtime. Las estructuras confirmadas de la sección 11 sustituyen las incompatibles: la alternativa de Tira con `min(R,4)` no satisface retirar el pago por rondas, y reducir el bono de Memoria sin contar pistas tampoco satisface la decisión. Las cantidades de Duelo, Guardián y Rescate siguen sin aprobar aunque se conserven sus estructuras.

| Juego: fórmula actual propuesta | Problema observado | Fórmula alternativa, también propuesta | Ejemplos: actual → alternativa / efecto residual |
|---|---|---|---|
| Trivia: `floor(S/10)` | Combo x4 convierte la pregunta tardía en 40 XP, gran distancia respecto del Duelo que comparte motor. | `10*C + floor((S-100*C)/100)`: mantener 10 por acierto y bonificar moderadamente el puntaje de combo sobre base. Es cambio deliberado de escala del combo, no equivalencia al original. | 5/10/30 perfectas: **80→53 / 240→114 / 1.040→374**. 3 aislados: **30→30**. Reduce diferencia con Duelo a 374 vs 310 en alto; todavía favorece racha, tiempo y ayudas. No normaliza duración ni dificultad. |
| Cima: `10*H + V*(10+5*U)` | Mejor resultado recibe hasta 35 adicionales precisamente cuando consume menos preguntas. | `10*H + 10*V`, eliminar el bono U sin tocar alturas ni victoria. | Victoria en N=5/9/12: **95→60 / 75→60 / 60→60**. Agotado H=4: **40→40**. Perfecto baja de 19 a 12/pregunta; rápido sigue rindiendo más por pregunta, pero no además en premio absoluto. |
| Memoria: `10*P+floor(10*P*P/M)` | Premio de eficiencia puede duplicar base; pistas no cuentan movimientos y pueden facilitar el máximo. | `10*P+floor(5*P*P/M)`, reducir peso de eficiencia sin excluir asistidas. | P=6: M=18/12/6, **80→70 / 90→75 / 120→90**. Perfectas P=8/10: **160→120 / 200→150**. Reduce máximo por pareja 20→15; las pistas aún facilitan alcanzar ese máximo. No resuelve autoridad ni mide mayor dificultad de niveles. |
| Tira: `5*C+10*R+20*V+10*T` | Paga repetidamente rondas que recuperan terreno, incentivando alargar. | `5*C+10*min(R,4)+20*V+10*T`, limitar solo el componente de rondas al objetivo de cuatro; mismo requisito C>0 para bono de empate. | Victoria 2/4/20 rondas del escenario: **50→50 / 80→80 / 240→160**; empate alternado 20: **210→150 por jugador**. No es límite de partidas ni diario. Aciertos todavía pagan más en partidas largas; si se quiere eliminar esa ventaja hará falta otra decisión, no esconderla. |
| Batallas: base 40/25/15 por resultado + 10 perfecta; cero aciertos solo excluye empate/derrota | Ganar fallando todo aún paga 40; Supervivencia permite atajo de pocas preguntas. | Para **resultado normal**, `floor(baseResultado*C/Q)+10*perfecta`, Q=8/8/10 según modo, siempre banco completo. No usar N respondidas como denominador, pues premiaría cerrar pronto. | Ganador 0 aciertos: **40→0**. Carrera/Relámpago 4/8 ganador: **40→20**; perdedor 1/8: **15→1**. Supervivencia 2/10 ganador al perder 3 vidas: **40→8**; perfecto ganador en cualquier modo: **50→50**. Reduce drásticamente premio de derrota parcial: decisión de producto relevante. |

La discusión histórica anterior mostró el riesgo de conservar 40 por victoria por abandono. **Decisión posterior vigente:** liquidación separada con validación servidor; no heredar 40 ni la fórmula normal. Solo queda pendiente su importe, como indica la sección 11. El mero vencimiento del otro jugador o múltiples duelos repetidos no valida colusión. Tampoco se aprueban multas más fuertes para compensar fórmulas desbalanceadas.

### 10.7 Comprobación de esta ronda

Se ejecutaron cálculos locales en memoria, sin escribir código de producto, importar servicios de base de datos ni crear fixtures persistentes. Para Cima, Guardián, Rescate y Trivia se cargaron las funciones puras TypeScript actuales mediante transpilación en memoria y se reprodujeron las secuencias de 10.2; se confirmó el cierre y el puntaje. Para Tira se usaron movimiento/cierre del motor y programación dinámica sobre movimientos válidos para verificar el máximo 240. Las tablas de Memoria y las alternativas se verifican por sustitución aritmética; no son ensayos de jugadores.

La regresión de **84 backend y 69 Flutter** de la sección 8 pertenece a la primera entrega, no se volvió a ejecutar ni se presenta como validación de la calibración. Los únicos cambios de esta ronda son documentales; los importes siguen siendo propuestas. No hay migraciones, ledger, balances, API nueva, backend de Memoria, cambios de runtime, commit, push ni PR-I2.

## 11. Decisiones estructurales congeladas — criterio vigente de la tercera ronda

La calibración quedó revisada por el propietario. Esta sección es el criterio vigente y prevalece sobre las fórmulas, alternativas e importes históricos de las secciones 4 y 10. **Congelación documental de estructuras, no de coeficientes ni de `xpRulesVersion`.** No autoriza runtime, migraciones, endpoints, ledger, balances ni PR-I2.

### Estructuras de XP confirmadas para los ocho juegos

Las letras y funciones siguientes describen componentes, no coeficientes numéricos aprobados. Cada componente se calcula desde evidencia del servidor; ningún resultado, XP, combo, movimiento o pista declarado por Flutter se acepta sin verificación.

| Juego | Estructura confirmada | Condiciones obligatorias / propuesta anterior descartada |
|---|---|---|
| Trivia Rush | Base por acierto verificado + bono moderado y acotado por combo. | **Rechazada `floor(S/10)` como fórmula competitiva definitiva.** El combo premia rendimiento, pero no multiplica sin límite práctico la economía. Debe tener un límite explícito de aporte competitivo, no descansar únicamente en que el banco termine. Cuantía base, escala y cota del bono: **POR APROBAR**. |
| Duelo fantasma | Base por rendimiento verificable + bono pequeño por victoria o empate contra fantasma fijado por servidor. | Primer intento genera referencia y **no recibe bono de victoria ni de empate**; solo puede recibir la base de rendimiento. Debe distinguirse de Trivia en backend antes de habilitar competitivo y fijar la referencia al inicio. Coeficientes: **POR APROBAR**. |
| Salto a la cima | Altura máxima alcanzada + bono fijo de victoria. Representación estructural: `baseAltura(H) + bonoVictoria*V`. | **Eliminar U y todo bono por preguntas no utilizadas.** No pagar adicionalmente por terminar con menos preguntas; alturas repetidas no aumentan el máximo. Coeficientes: **POR APROBAR**. |
| Tira y afloja | Rendimiento por aciertos válidos verificados + componente de resultado final + empate válido cuando corresponda. | **No pagar por cada ronda favorable R**, tampoco mediante la alternativa histórica `min(R,4)`. Oscilar terreno deliberadamente no debe resultar económicamente conveniente. La calibración del componente de aciertos y del resultado deberá comprobar esa condición: retirar R por sí solo no demuestra haberla cumplido. Coeficientes: **POR APROBAR**. |
| Guardián | Aciertos válidos + bono por escudos restantes **solo si existe victoria**. Representación: `baseAciertos(C) + V*bonoEscudos(E)`. | Sin victoria no se bonifican escudos restantes; las vidas propias del motor no se tratan como fraude. Coeficientes: **POR APROBAR**. |
| Memoria | Base por parejas completadas + bono de eficiencia medido con **movimientos y pistas verificados por servidor**. | Pistas oficiales no invalidan la partida, pero deben afectar la eficiencia: una pista no puede facilitar gratuitamente el mismo máximo de una partida perfecta sin ayuda. Se descartan ambas fórmulas históricas que solo usan M. Coeficientes/peso de pistas: **POR APROBAR**. Competitivo sigue bloqueado hasta existir motor autoritativo backend; Memoria local concede 0 XP competitivo. |
| Batallas | Para resultado normal, recompensa dependiente de resultado **y rendimiento real**. | Victoria con cero aciertos no genera recompensa normal completa. Banco competitivo completo de **8/8/10 preguntas** según Carrera fantasma/Relámpago/Supervivencia. Victoria por abandono validado es otro tipo de liquidación, sin importe heredado. Coeficientes normales y cuantía por abandono: **POR APROBAR**. |
| Rescate de estrellas | Estrellas verificadas + hitos de constelación + bono de victoria. Representación: `baseEstrellas(S_e) + bonoHitos(K) + bonoVictoria*V`. | Se conservan los componentes; no se aprueban los valores 10/10/10 históricos ni otros. Coeficientes: **POR APROBAR**. |

### Memoria: diseño estructural de eficiencia con pistas

Definir `P` como parejas completadas de un tablero válido, `M` como movimientos confirmados (dos giros) e `I` como pistas efectivamente usadas y confirmadas por servidor. Reintentar la misma solicitud no duplica M ni I. La pista no se disfraza como un movimiento realmente jugado: se registra por separado y se incorpora al coste de eficiencia.

Representación simbólica de diseño: `costeEficiencia = M + pesoPista*I`, con `pesoPista > 0`; `XP = baseParejas(P) + bonoEficiencia(P, costeEficiencia)`. El bono es acotado y no aumenta cuando crecen M o I, para P fijo. Su máximo corresponde a completar sin fallos ni pistas (`M=P`, `I=0`). A igual tablero, cualquier uso de pistas debe dejar el bono por debajo de ese máximo: incluso con `M=P`, `I>0` ya no cuenta como eficiencia perfecta sin ayuda. La partida conserva su validez y la base por parejas completadas.

**Condición de calibración entera:** la reducción debe sobrevivir al redondeo final de XP; no basta que una fracción baje si termina pagando el mismo máximo entero. Para P=6/8/10 se deberán comparar `M=P,I=0`, `M=P,I=1` y `M=P,I=P`, además de movimientos con errores. El peso de cada pista, la cuantía/cota del bono y la escala base son parte de los **coeficientes exactos POR APROBAR**; aquí no se asignan importes ni se aprueba una función numérica definitiva. No se implementa el motor ni se usa la memoria local como evidencia.

### Abandono, victoria por abandono y ambos ausentes — confirmados

| Caso | Decisión congelada documentalmente |
|---|---|
| Jugador que abandona | No conserva recompensa positiva parcial de esa partida. Registrar evento de abandono/penalización; balance competitivo con piso cero. El importe nominal sigue **POR APROBAR**. Un delta efectivo cero por el piso no borra la evidencia del abandono. |
| Rival que permanece | Puede recibir recompensa **solo** si el servidor valida conjuntamente: partida competitiva activa, participación válida, presencia suficiente y abandono definitivo del rival. Tipo de liquidación separado de victoria normal. No asumir la misma fórmula ni importe; valor exacto **POR APROBAR**. |
| Ambos ausentes sin evidencia suficiente de un jugador presente | **No existe ganador ni recompensa positiva.** Procesar los abandonos según evidencia individual; no convertir ausencia de información en una sanción automática para ambos. |

No se conservan como valores vigentes los 20/40 XP de victoria por abandono de la primera propuesta. Tampoco se decide ahora el importe de esa recompensa mediante los coeficientes de victoria normal. Los tiempos para resolver reconexión/abandono definitivo permanecen **POR APROBAR por juego**; los plazos del runtime auditado son evidencia histórica, no aprobación automática.

### Fecha de alcance — confirmada

`alcanzadoEn` se actualiza cuando **cualquier delta competitivo efectivo distinto de cero cambia el balance**, incluyendo resultado, penalización o corrección. Un delta cero no modifica `alcanzadoEn`. Por tanto, regresar a un balance anterior tras pérdida/corrección no recupera su antigua fecha de alcance. Esta regla ya no es una decisión pendiente.

### Arquitectura aprobada para el diseño, sin autorización de implementación

- XP competitivo separado de `Usuario.xpTotal`; el XP general existente se conserva.
- Ledger como fuente de verdad y balance como proyección.
- Idempotencia por fuente/participante; cambiar `rulesVersion` nunca permite pagar dos veces.
- Piso del XP competitivo en cero; importes y tratamiento de correcciones siguen requiriendo detalle auditado.
- Memoria local no concede XP competitivo; necesita autoridad servidor antes de habilitarlo.
- Duelo debe distinguirse de Trivia en backend y fijar el fantasma al inicio.
- Batallas competitivo requiere banco completo.
- Partida iniciada offline no concede XP competitivo.
- Ayudas oficiales no invalidan por sí mismas una partida.
- Profesores y administradores no compiten.

Estas decisiones actualizan el estado de las propuestas técnicas de secciones anteriores; no aprueban sus DTO, tablas o implementación concreta ni permiten comenzar a programarlos en esta ronda.

### Temporada e institución — decisiones confirmadas y efectos

| Decisión confirmada por el propietario | Efecto documentado |
|---|---|
| Temporada por fecha servidor del resultado terminal | No usar fecha de inicio, del teléfono ni del procesamiento del ledger. Si termina el 31 de diciembre de 2026 a las 23:59:59 Bogotá y el worker acredita el 1 de enero, pertenece a 2026. El cierre anual futuro deberá conciliar resultados pendientes antes de congelar, no excluirlos por demora técnica. |
| Partida que cruza año pertenece íntegramente al año del resultado terminal | Empieza el 31 de diciembre de 2026 y termina el 1 de enero de 2027: todo el XP va a 2027; no se reparte por preguntas. El usuario puede tener incentivo a retrasar la última respuesta en juegos sin reloj corto; respetar sus plazos naturales y fecha terminal del servidor. No inventar fecha anterior ni extender ventana al cruzar año. |
| Institución por membresía válida en esa misma fecha | Si empieza en A, cambia válidamente a B y termina en B, el premio completo de esa partida va a B. XP de partidas que ya terminaron en A permanece en A. Si termina en A y cambia a B antes de que el worker liquide, sigue en A. Si no tiene institución al terminar, aporte institucional nulo. Esto permite orientar una partida aún no cerrada hacia B; es efecto del criterio de cierre, no traslado del XP ya devengado. |

Requiere historial efectivo de membresías y orden transaccional determinista ante cierre/cambio simultáneos. Una liquidación posterior debe consultar ese historial; **no usar `Usuario.institucionId` actual** para reconstruir una membresía pasada. El XP ya devengado nunca se transfiere al cambiar de institución. La regla de temporada terminal también sitúa el resultado de abandono de una partida cruzada en esa temporada; no tomar XP general ni otro juego para cubrir una penalización. Las correcciones se vinculan al evento/año/institución originales y, si cambian el balance con delta efectivo no nulo, actualizan `alcanzadoEn` conforme a la regla confirmada. No se permite editar fechas retrospectivamente ni duplicar aportes.

### Decisiones pendientes y punto de parada

Quedan abiertos **exactamente estos cuatro grupos de decisiones**:

1. **Coeficientes exactos de XP de los ocho juegos**, dentro de las estructuras confirmadas: bases, bonos y cotas; incluye el peso de pistas/eficiencia de Memoria y la calibración de Tira para no incentivar oscilación deliberada.
2. **Penalización nominal por abandono.** No queda pendiente el piso cero ni la pérdida de recompensa positiva parcial: ambos están confirmados.
3. **Tiempos de reconexión por juego.** Ningún tiempo propuesto en la sección 5 queda aprobado por esta congelación estructural.
4. **Importe de victoria validada por abandono.** La liquidación separada y sus cuatro condiciones de evidencia están confirmadas; no su valor.

No se mantienen como pendientes el primer Duelo sin bono de victoria/empate, ambos ausentes sin ganador/premio positivo, fecha de alcance, temporada terminal, institución al resultado terminal, separación de liquidaciones ni abandono sin recompensa parcial. No se reabren las estructuras descartadas. `xpRulesVersion` permanece sin congelar hasta resolver los valores pendientes.

**Entrega de esta tercera ronda:** se actualizó únicamente `docs/PR_I1_AUDITORIA_FORMULAS.md`. Se conservaron los cálculos de calibración como historial y se revisó su estado frente a las decisiones confirmadas; no se ejecutaron pruebas de runtime ni se atribuyen nuevos resultados a las pruebas anteriores. `pubspec.yaml` y `pubspec.lock` conservan sus cambios previos, sin modificación en esta ronda. Misma rama/HEAD de la sección 1, sin commit ni push. No se modificó código ni se implementaron runtime, migraciones, endpoints, ledger, balances o PR-I2. **Detenerse para revisión del propietario.**
