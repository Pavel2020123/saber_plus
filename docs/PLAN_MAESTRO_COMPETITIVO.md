# PLAN MAESTRO COMPETITIVO DE SABERPLUS

## 1. Reglas de producto confirmadas

### XP competitivo

Cada uno de los ocho juegos tendrá su propio XP competitivo independiente.

Ejemplo conceptual:

| Juego | XP competitivo |
|---|---:|
| Trivia Rush | 4.500 XP |
| Duelo fantasma | 2.800 XP |
| Salto a la cima | 6.100 XP |
| Tira y afloja | 3.900 XP |
| Guardián | 5.200 XP |
| Memoria | 2.300 XP |
| Batallas | 7.600 XP |
| Rescate de estrellas | 4.100 XP |

También existirá un valor agregado:

`XP competitivo total = suma del XP de los ocho juegos`

Este valor puede servir para estadísticas generales e instituciones.

Sin embargo, los rankings por juego nunca deben utilizar `Usuario.xpTotal` como sustituto del XP específico de cada juego.

El XP general existente de SaberPlus no debe romperse ni reemplazarse accidentalmente durante PR-I1.

---

# 2. Los ocho juegos competitivos

Los únicos juegos competitivos vigentes son:

1. Trivia Rush
2. Duelo fantasma
3. Salto a la cima
4. Tira y afloja
5. Guardián
6. Memoria
7. Batallas
8. Rescate de estrellas

Escudo del conocimiento está retirado.

Taller de inventos está cancelado.

Instituciones NO es un noveno juego.

---

# 3. Fórmula diferente para cada juego

Cada juego tendrá su propia lógica de XP.

No se utilizará una fórmula idéntica para todos.

La fórmula puede considerar elementos como:

- victoria;
- derrota;
- rendimiento;
- respuestas correctas;
- tiempo;
- dificultad;
- objetivos;
- puntuación del juego;
- rival;
- resultado final.

La fórmula exacta se diseñará después de auditar la lógica real de cada juego.

Codex NO debe inventar cantidades arbitrarias de XP sin revisar primero cómo funciona cada juego actualmente.

PR-I1 debe producir una tabla para los ocho juegos con:

`acción → evidencia → XP → restricciones`

y presentarla al propietario antes de congelar los valores definitivos.

---

# 4. Autoridad del servidor

Todo XP competitivo debe ser verificado por el backend.

Flutter nunca podrá enviar:

`gané 500 XP`

y conseguir que el servidor lo acepte.

Flutter podrá enviar la información necesaria sobre la partida o una referencia a ella.

El backend deberá:

1. comprobar que la partida existe;
2. comprobar quién participó;
3. comprobar el resultado;
4. comprobar que no fue acreditada anteriormente;
5. aplicar las reglas del juego;
6. calcular el XP;
7. registrar el evento;
8. actualizar el balance competitivo.

---

# 5. Offline

Existen dos situaciones diferentes.

### Juego iniciado completamente offline

Puede permitirse jugar como práctica.

No concede XP competitivo.

No modifica rankings.

No concede posición competitiva.

No puede convertirse retroactivamente en una partida competitiva salvo que exista evidencia servidor suficiente.

### Partida competitiva online con desconexión

Si una partida competitiva ya comenzó online y un jugador:

- abandona;
- cierra la aplicación;
- pierde Internet;
- desaparece de la partida;

el servidor puede cerrar la partida como abandono.

El jugador que abandona:

- pierde la partida;
- no recibe XP de victoria;
- puede recibir una penalización de XP competitivo.

El rival que permanece:

- gana la partida si el servidor puede validar correctamente el abandono;
- recibe la recompensa correspondiente.

La cantidad exacta de penalización deberá definirse por juego.

Una derrota normal NO tiene por qué quitar XP.

La pérdida de XP estará principalmente asociada a abandono/desconexión de una partida competitiva activa y a correcciones administrativas.

---

# 6. Reconexión

Debe diseñarse una pequeña política técnica de reconexión para evitar que un microcorte de red sea interpretado inmediatamente como abandono.

La duración deberá decidirse según el juego y su arquitectura.

Después del tiempo de reconexión permitido, el servidor podrá declarar abandono.

Esto no cambia la regla principal:

si finalmente no regresa, pierde.

---

# 7. Comodines y ayudas

Los comodines y ayudas permitidos por el propio juego NO invalidan automáticamente una partida competitiva.

Si el juego permite oficialmente utilizar un comodín durante una partida online, la partida continúa siendo válida y puede conceder XP normalmente.

No debe considerarse fraude utilizar una mecánica legítima del juego.

Sí deberán detectarse:

- manipulación del cliente;
- eventos imposibles;
- duplicación de recompensas;
- alteración de resultados;
- partidas inexistentes;
- solicitudes fabricadas.

---

# 8. Cantidad de partidas

No existirá un límite artificial de partidas diarias.

Un usuario podrá jugar:

- 10;
- 100;
- 500;

partidas si realmente encuentra rivales y todas son partidas válidas.

El sistema no utilizará un límite diario únicamente para impedir subir en ranking.

Sin embargo, deben existir mecanismos antifraude.

Jugar repetidamente no es fraude por sí mismo.

La manipulación, colusión automatizada o fabricación de resultados sí puede serlo.

---

# 9. Qué mide el ranking

El ranking mide únicamente:

**XP competitivo válido acumulado en ese juego durante la temporada.**

Ejemplo:

Trivia Rush:

Juanito: 15.200 XP  
Pedrito: 13.800 XP  
Laura: 12.900 XP

La posición depende de esos XP.

No se calculará un puntaje diferente oculto.

---

# 10. Temporadas

Por ahora solo existirán temporadas anuales.

No se crearán rankings oficiales:

- diarios;
- semanales;
- mensuales.

La temporada será:

`1 de enero → 31 de diciembre`

Zona oficial:

`America/Bogota`

Internamente pueden almacenarse timestamps UTC, pero los límites de temporada deberán calcularse de acuerdo con la hora colombiana.

Ejemplo:

`Temporada 2026`

`Temporada 2027`

`Temporada 2028`

---

# 11. Primera temporada y datos históricos

No se inventará XP competitivo retroactivo.

Si PR-I1 entra en funcionamiento cuando la temporada 2026 ya está avanzada, solo se podrán recuperar partidas anteriores cuando exista evidencia servidor suficiente para reconstruir correctamente el XP.

Si esa evidencia no existe:

la temporada 2026 seguirá llamándose 2026, pero el XP competitivo empezará a acumularse desde la activación real del sistema.

Esto deberá quedar documentado como temporada inicial parcial.

---

# 12. Desempate

Orden principal:

`XP competitivo DESC`

Si dos usuarios tienen exactamente el mismo XP:

gana quien alcanzó primero ese total.

Por tanto, también deberá persistirse información suficiente para saber cuándo el usuario alcanzó su balance competitivo actual.

Orden:

`XP DESC`

`fechaDeAlcance ASC`

Si extraordinariamente ambos valores son idénticos, se utilizará un identificador técnico estable únicamente como tercer desempate para garantizar que el orden sea determinista.

Ese criterio técnico no debe mostrarse al usuario como una regla de mérito.

---

# 13. TOP 50

Solo los puestos del 1 al 50 reciben insignia anual.

Las categorías serán exactamente:

| Posición final | Insignia |
|---|---|
| 1 | TOP 1 |
| 2 | TOP 2 |
| 3 | TOP 3 |
| 4 | TOP 4 |
| 5 | TOP 5 |
| 6–10 | TOP 6–10 |
| 11–20 | TOP 11–20 |
| 21–30 | TOP 21–30 |
| 31–40 | TOP 31–40 |
| 41–50 | TOP 41–50 |
| 51+ | Sin insignia |

Las 90 imágenes existentes son solamente el catálogo visual.

No acreditan propiedad.

---

# 14. Posición provisional

Estar TOP 1 durante marzo, junio o noviembre NO concede la insignia TOP 1.

La posición durante el año es provisional.

La insignia se determina únicamente utilizando la posición final al cerrar la temporada.

Ejemplo:

Junio:

Juanito → TOP 1

31 de diciembre:

Juanito → TOP 5

Resultado:

Juanito recibe únicamente la insignia TOP 5 de esa temporada.

---

# 15. Insignias permanentes

Una insignia obtenida correctamente permanece en el historial.

Ejemplo:

### 2026

Trivia Rush → TOP 3

Batallas → TOP 6–10

### 2027

Trivia Rush → TOP 1

### 2028

Guardián → TOP 20

El usuario conserva todas.

Al tocar una insignia deberá poder verse como mínimo:

- juego;
- temporada;
- rango obtenido;
- posición final;
- fecha de concesión.

---

# 16. Correcciones

El servidor podrá corregir XP cuando exista:

- fraude;
- bug;
- resultado duplicado;
- evento inválido;
- error administrativo justificado.

Nunca debe editarse silenciosamente el balance.

Toda modificación debe dejar auditoría.

Si una corrección modifica el ranking:

las posiciones deberán recalcularse.

Incluso después de una temporada cerrada podrá existir una corrección administrativa extraordinaria.

Si cambia una insignia concedida:

- se corrige la propiedad efectiva;
- se conserva el registro histórico/auditoría de la modificación;
- no se continúa mostrando como válida una insignia revocada.

---

# 17. Perfil estudiantil

Cada estudiante podrá tener:

- nombre;
- alias;
- avatar/foto;
- institución;
- insignias;
- estadísticas competitivas;
- historial de temporadas.

El usuario podrá elegir ocultar su nombre real al resto de estudiantes.

En ese caso se mostrará principalmente:

`@alias`

Ejemplo:

Nombre real:

Juan David Pérez

Alias:

`@ShadowJuan`

Para otros estudiantes puede aparecer:

`ShadowJuan`

La institución sí podrá conocer el nombre real del estudiante cuando sea necesario para administrar su membresía.

---

# 18. Privacidad

Nunca debe aparecer públicamente en perfiles competitivos:

- correo;
- contraseña;
- diagnóstico académico privado;
- respuestas privadas;
- progreso académico privado;
- información administrativa sensible.

Por defecto el ranking competitivo deberá ser visible para usuarios autenticados de SaberPlus.

La identidad pública utilizada en rankings será principalmente el alias.

Si el usuario oculta su nombre real:

el ranking no deberá revelarlo.

---

# 19. Profesores y administradores

Profesores y administradores NO participan como jugadores en rankings competitivos.

Pueden administrar:

- instituciones;
- solicitudes;
- contenido;
- estudiantes;
- funciones autorizadas.

Pero no competir por TOP 50.

La institución sí participa como entidad en PR-I6.

---

# 20. Cambio de institución

El XP institucional se atribuye a la institución a la que pertenecía el estudiante cuando generó ese XP.

Ejemplo:

Universidad A:

Juan genera 5.000 XP.

Después Juan pasa a Universidad B.

Los 5.000 XP permanecen atribuidos a A.

Desde el cambio:

el nuevo XP generado se atribuye a B.

No se transfieren retroactivamente los aportes.

---

# 21. Estudiante sin institución

Puede competir normalmente en los rankings individuales.

Puede:

- ganar XP;
- aparecer en TOP 50;
- obtener insignias.

Simplemente no genera aporte institucional mientras no pertenezca a ninguna institución.

---

# 22. Código institucional

Cada institución podrá tener un código privado independiente de los códigos de grupos/clases.

Los administradores autorizados podrán:

- generarlo;
- revocarlo;
- regenerarlo.

Nunca debe guardarse el código sensible en texto plano si puede evitarse.

---

# 23. Formas de entrar a una institución

Existirán dos mecanismos.

### Código

El estudiante introduce un código institucional válido.

Puede unirse mediante el flujo autorizado correspondiente.

### Solicitud

El estudiante busca la institución y envía una solicitud.

Un administrador/profesor autorizado puede:

- aprobar;
- rechazar.

Esto permite el caso:

“Profesor, no tengo el código.”

“Envíame la solicitud y yo te apruebo.”

---

# 24. Ranking institucional

La institución compite utilizando la suma del XP competitivo válido generado por sus estudiantes mientras pertenecían a ella.

Por ahora NO se normalizará por número de alumnos.

Ejemplo:

Institución A:

120.500 XP válidos

Institución B:

98.200 XP válidos

Institución C:

82.300 XP válidos

El ranking sigue esa suma.

Debe impedirse contabilizar dos veces el mismo evento competitivo.

---

# 25. Ocho juegos desde el inicio

El objetivo es que los ocho juegos participen en el sistema.

Pero antes de habilitar competitivamente un juego debe comprobarse que su resultado pueda verificarse correctamente en servidor.

Si uno de los juegos actuales no dispone todavía de evidencia suficiente:

PR-I1 deberá corregir su contrato o preparar la infraestructura necesaria.

No se debe simular verificación simplemente para afirmar que los ocho están listos.

---

# 26. Recompensas visuales adicionales

Además de las insignias anuales, SaberPlus podrá tener recompensas cosméticas.

Dos conceptos quedan aprobados para diseño posterior.

### Marcos de avatar

Un usuario puede desbloquear marcos especiales.

Ejemplo:

marco de campeón;
marco competitivo;
marco de temporada.

### Títulos de perfil

Son diferentes al alias.

Ejemplo:

Alias:

`@Pavel`

Título equipado:

`Estratega`

o:

`Veterano 2026`

o:

`Maestro de Trivia`

Visualmente podría aparecer:

`@Pavel`

`Estratega`

Estos títulos NO sustituyen las insignias.

Deberán definirse posteriormente sus condiciones de obtención.

No deben otorgar ventajas competitivas.

---

# 27. Historial competitivo

El perfil podrá navegar por temporadas.

Ejemplo:

## 2026

Trivia Rush  
Posición final: 3  
Insignia: TOP 3

Batallas  
Posición final: 8  
Insignia: TOP 6–10

## 2027

Trivia Rush  
Posición final: 1  
Insignia: TOP 1

Esto debe conservarse permanentemente.

---

# 28. XP negativo

Una derrota normal no necesita disminuir XP.

Las principales situaciones que pueden disminuirlo son:

- abandono de partida competitiva;
- desconexión definitiva durante partida competitiva;
- corrección administrativa;
- invalidación por fraude/error.

La penalización exacta por abandono se determinará por juego.

No debe permitirse que una penalización accidental produzca balances imposibles sin que la regla del juego lo permita.

---

# PR-I1 — CONTRATO E INFRAESTRUCTURA COMPETITIVA

## Objetivo

Construir las bases comunes antes de hacer rankings.

PR-I1 deberá implementar o documentar:

| Elemento | Resultado esperado |
|---|---|
| Identificadores de juegos | 8 IDs estables |
| Temporada | Año + zona Bogotá |
| XP por juego | Balance independiente |
| Ledger | Eventos de XP auditables |
| Idempotencia | Una partida no paga dos veces |
| Fuente | Referencia al intento/partida |
| Institución | Institución al momento del evento |
| Reglas | Versión de fórmula aplicada |
| Penalización | Eventos negativos auditables |
| Corrección | Mecanismo explícito |
| Privacidad | Contratos sin datos privados |
| Roles | Solo estudiantes compiten |

Antes de programar fórmulas, Codex deberá auditar los ocho juegos.

Debe producir para cada juego:

| Juego | Backend autoritativo | Resultado verificable | Datos disponibles | Ayudas | Abandono | Fórmula propuesta | Cambios necesarios |
|---|---|---|---|---|---|---|---|

Después presentará las fórmulas de XP al propietario.

Solo después de aprobación se congelarán como `rulesVersion`.

### Modelo recomendado

No depender exclusivamente de un contador mutable.

Debe existir un ledger/eventos de XP.

Conceptualmente:

`EventoXpCompetitivo`

con información como:

- usuario;
- juego;
- temporada;
- delta XP;
- tipo de evento;
- partida origen;
- idempotency key;
- institución en ese momento;
- versión de reglas;
- fecha servidor;
- estado;
- corrección relacionada.

También puede existir una tabla de balance optimizada para lectura:

`BalanceCompetitivo`

por:

`usuario + juego + temporada`

El ledger será la evidencia.

El balance será la proyección rápida.

### Cierre de PR-I1

Debe terminar con:

- migraciones;
- servicios;
- contratos;
- seguridad;
- idempotencia;
- pruebas;
- documentación.

NO debe implementar todavía todas las pantallas de ranking.

---

# PR-I2 — RANKINGS POR JUEGO

Después de aprobar PR-I1.

Crear ranking independiente para cada juego y temporada.

Consulta conceptual:

`juego + temporada`

Orden:

1. XP DESC
2. fecha de alcanzar ese XP ASC
3. desempate técnico estable

Mostrar TOP 50.

Debe poder identificarse la posición del propio usuario sin exponer información privada de los demás.

Nunca utilizar el XP de un juego para ordenar otro juego.

Pruebas mínimas:

- TOP 50;
- empate;
- posición 1;
- posición 50;
- posición 51;
- mismo XP;
- corrección;
- usuario sin institución;
- privacidad;
- temporada distinta;
- juego distinto;
- concurrencia.

---

# PR-I3 — INSIGNIAS ANUALES

Crear el cierre anual.

Al finalizar el 31 de diciembre según `America/Bogota`:

se congelará el resultado competitivo correspondiente.

El proceso debe ser idempotente.

Ejecutarlo dos veces no puede conceder dos insignias.

Persistir como mínimo:

- usuario;
- juego;
- temporada;
- posición exacta;
- banda de insignia;
- fecha;
- versión de reglas;
- referencia al cierre.

Solo TOP 50 obtiene insignia.

La propiedad es permanente salvo corrección administrativa auditada.

---

# PR-I4 — PERFILES

Ampliar perfil estudiantil.

Debe soportar:

- alias;
- nombre real;
- configuración de privacidad del nombre;
- avatar;
- institución;
- XP competitivo por juego;
- historial anual;
- insignias;
- marco equipado;
- título equipado.

La búsqueda pública deberá respetar la privacidad.

Si el nombre está oculto:

otros estudiantes ven alias.

La institución conserva acceso al nombre necesario para administrar a sus estudiantes.

Las fotografías reales dependen de C5 para almacenamiento persistente.

Hasta resolver C5 no debe diseñarse una solución definitiva basada únicamente en disco efímero de Render.

---

# PR-I5 — INSTITUCIONES

Crear o completar:

- perfil institucional;
- búsqueda;
- membresía;
- historial de membresías;
- solicitud;
- aprobación;
- rechazo;
- código privado;
- regeneración;
- revocación;
- permisos administrativos.

La membresía necesita fechas.

Ejemplo:

`joinedAt`

`leftAt`

Esto será fundamental para PR-I6.

---

# PR-I6 — RANKING INSTITUCIONAL

El aporte institucional proviene de los eventos de XP competitivo.

Cada evento conserva la institución correspondiente al momento en que ocurrió.

Por tanto:

cambiar de institución NO mueve XP histórico.

Ranking:

`SUM(XP competitivo válido atribuido a institución durante temporada)`

Debe garantizar:

- no duplicación;
- no transferencia retroactiva;
- eventos auditables;
- correcciones recalculables;
- estudiantes sin institución ignorados solamente para este ranking.

---

# PR-I7 — PRUEBA INTEGRAL

Realizar una prueba completa:

Usuario A  
→ entra a juego  
→ juega online  
→ backend verifica resultado  
→ recibe XP  
→ aparece en ranking  
→ cambia de posición  
→ finaliza temporada  
→ recibe insignia  
→ insignia aparece en perfil  
→ se conserva históricamente.

Además probar:

Usuario B  
→ mismo XP  
→ desempate por fecha.

Usuario C  
→ abandona  
→ recibe derrota/penalización.

Usuario D  
→ juega offline  
→ no obtiene XP competitivo.

Usuario E  
→ cambia de institución  
→ XP anterior queda en A  
→ XP nuevo va a B.

También comprobar:

- reintentos;
- solicitudes duplicadas;
- fraude básico;
- sesión expirada;
- roles;
- privacidad;
- concurrencia;
- correcciones;
- cierre ejecutado dos veces;
- múltiples temporadas.

---

# ORDEN DE DESARROLLO

El orden obligatorio queda:

`PR-I1`

↓

`PR-I2`

↓

`PR-I3`

↓

`PR-I4`

↓

`C5 si se necesitan fotografías persistentes`

↓

`PR-I5`

↓

`PR-I6`

↓

`PR-I7`

Después se vuelve a evaluar:

`C4 / C5 / C6`

`P5 / D3`

`integración y seguridad`

`certificados y audio`

`Billing`

`anuncios y recompensas`

`privacidad/licencias`

`UI-F`

`beta`

`iOS`

`Google Play`

`mantenimiento`

---

# REGLA PARA CODEX

No debe avanzar automáticamente de una etapa a otra.

Al terminar cada PR-I debe informar:

- rama;
- HEAD;
- archivos modificados;
- migraciones;
- endpoints;
- contratos;
- pruebas;
- resultados;
- decisiones tomadas;
- decisiones pendientes;
- documentación actualizada.

Después debe detenerse para revisión.

No hacer:

- merge;
- despliegue;
- migración Supabase real;
- publicación;
- cambios en producción;

sin autorización.

---

# SIGUIENTE ACCIÓN EXACTA

La siguiente acción del proyecto es:

**PR-I1 — auditar los ocho juegos y diseñar la fórmula competitiva individual de cada uno.**

Todavía NO comenzar PR-I2.

El primer entregable de PR-I1 será una matriz de los ocho juegos mostrando:

- cómo termina una partida;
- qué conoce el servidor;
- qué eventos son verificables;
- qué datos sirven para calcular XP;
- cómo tratar victoria/derrota;
- cómo tratar abandono;
- cómo funcionan comodines;
- qué protección antifraude existe;
- qué falta modificar;
- fórmula de XP propuesta.

El propietario revisará esa matriz y aprobará las fórmulas antes de implementar el sistema competitivo definitivo.