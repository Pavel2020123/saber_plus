# IC-1B — Cliente competitivo del Guardián

## Estado — 8 de octubre de 2026

IC-1B1 implementada e IC-1B2 validada en su alcance local Android/API/ledger:
victoria, recuperación, red/reintento, ranking sin duplicación, modo normal sin XP,
derrota y abandono confirmados. Siguiente IC-1C, Rescate de estrellas.
No declarar toda IC-1 ni producción validadas por este ensayo acotado.
Cima conserva su [validación local previa](IC1_CIMA.md). Después del ensayo del
Guardián siguen Rescate, Trivia, Duelo y Tira, sin activar producción.
El propietario cambió la decisión: un commit por juego después de terminar sus
pruebas y actualizar documentación. Revisar los cambios acumulados de Cima y
Guardián antes de agruparlos; no publicar automáticamente cambios ajenos.

## Contrato y comportamiento

- Cuenta estudiantil real: «Competir en el ranking», apagado inicialmente.
  Normal omite el campo; competir envía `competitive: true` con los filtros.
  Demo no ofrece el interruptor y rechaza competir; profesor/sin sesión no juegan.
- `competitive` del servidor debe ser booleano. Ausencia en API antigua significa
  normal, nunca admisión competitiva. Se rechazan otra modalidad, otro intento,
  otros filtros o estado regresivo; tampoco cambia el modo al recuperar.
- Flag OFF: rechazo explícito, sin cambiar silenciosamente a demo o normal.
  Desactivar la admisión no debe impedir recuperar/terminar un intento admitido.
- Antes de empezar se consulta el estado remoto. Si falla, iniciar queda
  deshabilitado. Ante acuse perdido de creación se ofrece buscar partida guardada.
- Recuperación cifrada y separada por API/cuenta: guarda únicamente ID del intento,
  modalidad e IDs/UUID del envío pendiente. No guarda soluciones, XP ni tokens.
  Persistir falla o registro corrupto: no se envía otra respuesta automáticamente.
- Antes del POST se persiste la selección y su clave. Reintentar conserva ambas;
  sincronizar consulta al servidor. Un GET que confirma el envío evita reenviarlo.
  Recrear el repositorio recupera el pendiente; cambio de cuenta invalida el viejo.
- Se conservan motor y reglas: 6 aciertos, 3 errores, máximo 8 preguntas, 24 horas,
  sin cronómetro de respuesta ni potenciadores. No añadir presencia/latidos de
  Trivia/Tira ni cambiar fórmulas competitivas para integrar este juego.
- Resultado competitivo enlaza al ranking del Guardián con lectura nueva. Muestra
  liquidación pendiente, no XP inventada. Abandonar requiere confirmación; volver
  atrás no es abandonar. Diagnóstico y progreso académico no se modifican aquí.
- Selector de dificultad adaptable a pantalla estrecha/texto grande. Se preservan
  escena, sonidos, revisión de explicaciones y navegación existentes.

## Archivos y pruebas

`lib/features/games/guardian/`: modelos, repositorio remoto/demo, nuevo
`guardian_resume_store.dart` y pantalla. Sin dependencias ni migraciones nuevas.

34 pruebas dirigidas aprobadas: 19 de contrato/repositorio, 6 widgets competitivos
y 9 existentes. Comprueban modalidad estricta, OFF, persistencia, cambio de cuenta,
recuperación, acuse perdido simulado, mismo UUID, permisos de acceso visual,
resultado/ranking y texto ampliado. Fixture exclusivamente en `test/helpers/`.
Un primer ensayo de pantalla estrecha encontró un overflow de 5,2 px del selector
de dificultad: corregido con `isExpanded`, manteniendo la prueba y su aserción.

Validación final de código: `flutter analyze --no-pub`, sin incidencias;
`flutter test --no-pub --reporter expanded`, 732 aprobadas y 9 opt-in omitidas,
sin fallos (4 min 5 s). Backend: 23/23 tests existentes del Guardián en tres suites
y 8/8 del control IPC local. Formato de Dart afectado y `git diff --check` correctos.
No se repitió la regresión PostgreSQL global del compañero.
No equivalen a una partida real ni a validación de audio, iOS, anuncios o producción.

APK arm64 debug compilada con `-PsaberplusValidationApk=true`; aapt confirmó
`com.example.saber_plus.i2validation`, 339841229 bytes. Instalación por USB
no-streaming finalizó con `Success`; no se desinstaló ni reemplazó la app habitual.
Defines únicamente dev/API loopback, sin archivo privado de autenticación.
Avisos Java/native-access y flutter_timezone/KGP no impidieron compilar; conservar
la compatibilidad futura como deuda, no actualizar dependencias sin probarlas.
API/panel responden HTTP 200; USB reverse `43187` configurado. SQL inicial de
solo lectura del contenedor propio confirma 0 intentos y 0 eventos GUARDIAN.
Admisión inició OFF. El propietario confirmó el mensaje de rechazo al intentar
competir; SQL de solo lectura acreditó 0 intentos GUARDIAN después del rechazo.
Control IPC del harness confirmó `local-solo-admission`, `enabled: true` para
continuar el ensayo exclusivamente local. Siguiente checkpoint: iniciar la
partida competitiva y comprobar su recuperación. Victoria/ledger aún pendientes.
El primer intento ON rechazó banco insuficiente porque estaba seleccionada Media;
el propietario lo corrigió a Básica y confirmó las preguntas de sumas. SQL de
solo lectura acredita un único intento `a13a226b-f683-4a43-9c4c-e0183a0f4063`,
ACTIVO, MATEMATICAS/BASICO, competitiveRulesVersion 1 y 0 respuestas confirmadas;
todavía 0 eventos GUARDIAN. Siguiente checkpoint: cerrar y recuperar ese intento.
Propietario cerró/reabrió la app y confirmó que volvió a la partida. SQL acredita
el mismo ID ACTIVO/versión 1, 0 respuestas y un único intento total: recuperación
sin duplicación confirmada. Se retiró únicamente el reverse USB `43187` para el
siguiente ensayo de envío sin conexión; no se detuvo API/base ni se tocó Wi-Fi.
Propietario confirmó error al enviar sin el reverse USB. SQL posterior mantiene
el mismo intento ACTIVO y 0 respuestas confirmadas. Se restableció el reverse
`43187`; pendiente comprobar reintento y una sola respuesta registrada. Este
corte fue previo al guardado, no una pérdida de acuse posterior a la persistencia.
Propietario confirmó que reintentar mostró feedback y permitió avanzar. SQL
acredita exactamente 1 respuesta/1 acierto en el mismo intento ACTIVO, sin
evento GUARDIAN todavía. Control IPC confirmó admisión OFF nuevamente: se
comprobará que el intento admitido conserva el permiso para terminar y liquidarse.
Propietario llegó a la victoria con admisión OFF. SQL de solo lectura confirmó
VICTORIA, 6 respuestas/6 aciertos y competitiveSettledAt presente. Un único evento
GUARDIAN_ATTEMPT de ese ID, RESULTADO/APLICADO, xpRulesVersion 1, delta 100,
saldo 0 → 100 y balance GUARDIAN/2026 de 100. Un participante con balance positivo.
Concesión real de esta partida, no fixture de Trivia. Pendiente confirmar ranking
visual, lecturas/reapertura sin duplicación y práctica normal sin XP.
Propietario abrió el ranking del Guardián y confirmó que solo aparece él,
coincidiendo con el único balance positivo local. No confirmó aún verbalmente
los valores visuales de XP/puesto; siguiente checkpoint: reabrir y actualizar
el ranking, confirmar 100 XP/puesto 1 y contrastar que siga un único evento.
Propietario confirmó que cerrar/reabrir y actualizar dos veces mantiene el ranking
correcto. SQL posterior: un intento, un evento GUARDIAN, delta aplicado total 100
y balance 2026 de 100: lecturas/reapertura sin duplicación confirmadas.
Siguiente checkpoint: victoria en modo normal y verificar ausencia de nuevo evento.
Victoria normal confirmada por el propietario y SQL: segundo intento
`dc6892c2-a7cc-41a6-b457-1c8c12130d71`, VICTORIA, 6/6 respuestas correctas,
competitiveRulesVersion NULL, sin settledAt ni evento. Se mantiene un único evento
GUARDIAN con delta total 100 y balance 2026=100. Práctica normal sin XP acreditada.
Siguiente checkpoint físico: derrota y abandono competitivos conforme a reglas
vigentes, sin cambiar fórmulas; no declarados probados ni cerrar toda IC-1B aún.
Para comenzar derrota se verificaron API HTTP 200 y reverse USB; control IPC
confirmó admisión ON otra vez en el harness propio. Pendiente interacción física.
Propietario confirmó «Tu escudo necesita recargarse». SQL acredita derrota
`df46bbc6-3661-4e7d-bc45-72ac4a85af11`, competitiva versión 1, 6 respuestas:
3 correctas y 3 incorrectas, settledAt presente. Evento RESULTADO/APLICADO único
de esa derrota con +30 XP (10 por acierto, sin bonus de victoria), saldo 100 → 130.
La predicción de cero XP suponía 0 aciertos y no corresponde a esta partida:
se conserva la regla vigente y el resultado real, sin tratarlo como fallo.
Siguiente checkpoint en ese momento: abandonar una nueva partida competitiva.
Propietario confirmó balance 120 después de abandonar sin responder. SQL acredita
`18833652-bed2-4a7e-980b-733b6dd49e83`, ABANDONADO, versión competitiva 1,
0 respuestas, settledAt presente y un único evento ABANDONO/APLICADO de −10 XP,
saldo 130 → 120. Total: 4 intentos (3 competitivos y 1 normal), 3 eventos GUARDIAN
reales: +100 victoria, +30 derrota con 3 aciertos, −10 abandono. Normal sin evento.
Ensayo local del Guardián cerrado con esos límites; no se probó TTL de 24 horas,
pérdida real de acuse posterior al guardado, iOS, audio, animación ni producción.
No se repitió regresión PostgreSQL global. Siguiente Rescate de estrellas IC-1C.
Al cerrar, control IPC confirmó admisión OFF nuevamente. No se detuvo el ensayo
ni se borró su evidencia; API/base siguen siendo recursos temporales con plazo
de dos horas. Verificar disponibilidad antes de continuar, no asumir persistencia.
311 enlaces locales de documentos de entrada/entrega comprobados, 0 ausentes.

## IC-1B2 — guion de ensayo físico pendiente

1. Verificar API/base temporales propias, USB y paquete separado `.i2validation`.
   No reinstalar encima de la app habitual ni introducir credenciales en la APK.
2. Matemáticas/Básico: banco sintético de 12 preguntas del harness local. Intentar
   competir con admisión OFF; comprobar mensaje y ausencia de nuevo intento.
3. Activar solo el control IPC local autorizado. Iniciar competitivo, comprobar
   modalidad en API; cerrar y volver a abrir conserva ID y respuestas.
4. Desconectar el transporte USB, responder y recuperar: misma selección/UUID,
   sin contar el fallo de red como error. No afirmar acuse perdido posterior al
   guardado si no se provoca y acredita ese caso por separado.
5. Desactivar nuevas admisiones con el intento activo; terminar con 6 aciertos.
   Comprobar evento GUARDIAN único y balance/ranking real en SQL de solo lectura.
   Esperar reconciliación; no usar el fixture sintético de Trivia como prueba.
6. Reabrir y consultar varias veces: balance sin duplicación. Victoria normal no
   crea evento competitivo. Probar derrota/abandono contra reglas vigentes sin
   reinterpretar las fórmulas ni conceder puntos desde Flutter.
7. Registrar evidencia/limitaciones; cerrar solo recursos temporales identificados.
   Actualizar ruta y relevo. No desplegar ni migrar Supabase/Render.
