# Contrato del backend de Tira y afloja

## Estado de la integracion

La etapa 6F-D-C se divide en tres entregas:

- **6F-D-C-A, terminada:** esquema PostgreSQL, emparejamiento, reloj y rondas autoritativas, respuestas idempotentes, abandono y registro versionado de eventos.
- **6F-D-C-B, terminada:** transporte Socket.IO autenticado, notificaciones inmediatas, presencia, reloj autonomo y protocolo de reconexion.
- **6F-D-C-C, terminada:** arena Flutter conectada a rivales reales, estados de red, sincronizacion HTTP de respaldo y regreso seguro al modo local.

El estudiante puede elegir entre la partida en linea y el entrenamiento local contra CPU. Las cuentas demo solo utilizan el entrenamiento local.

## Autenticacion

Todas las solicitudes usan el access token existente:

```http
Authorization: Bearer <access-token>
```

El usuario debe tener correo verificado y rol `ESTUDIANTE`. El juego no depende de un plan pago: la cuenta gratuita conserva acceso academico completo.

## Endpoints

### Buscar o recuperar una partida

```http
POST /tira-afloja/emparejamiento
Content-Type: application/json

{
  "area": "MATEMATICAS"
}
```

`area` es opcional. Si el estudiante ya tiene una busqueda o partida abierta, el servidor devuelve esa misma partida. Dos jugadores solo se emparejan cuando eligieron la misma area, incluida la opcion sin filtro.

### Consultar la partida abierta

```http
GET /tira-afloja/activa
```

Devuelve `null` cuando el estudiante no tiene busqueda ni partida abierta.

### Sincronizar estado y eventos

```http
GET /tira-afloja/{partidaId}?desdeVersion=4
```

La respuesta incluye el estado actual completo y solo los eventos cuya version sea mayor que `desdeVersion`. Esto permite reconstruir la partida despues de perder internet sin confiar en la posicion guardada por el telefono.

### Confirmar que el jugador esta listo

```http
POST /tira-afloja/{partidaId}/listo
```

Cuando ambos jugadores estan listos, el servidor programa la primera ronda con tres segundos de cuenta regresiva.

### Responder una ronda

```http
POST /tira-afloja/{partidaId}/respuestas
Content-Type: application/json

{
  "ronda": 3,
  "preguntaId": "uuid",
  "respuestaId": "uuid",
  "idempotencyKey": "uuid-generado-por-el-dispositivo"
}
```

El cliente no envia milisegundos ni indica si acerto. El servidor registra su propia hora de llegada, verifica que la opcion pertenezca a la pregunta y calcula el acierto. Reenviar la misma clave devuelve el estado sin crear otra respuesta.

### Abandonar

```http
POST /tira-afloja/{partidaId}/abandonar
```

Cancelar una busqueda sin rival no produce ganador. Abandonar una partida emparejada entrega la victoria al rival.

## Estado recibido por Flutter

La respuesta de consulta contiene:

- `servidorAhora`, para calcular la diferencia con el reloj local.
- `partida.estado`: `BUSCANDO`, `PREPARANDO`, `ACTIVA`, `FINALIZADA`, `CANCELADA` o `EXPIRADA`.
- `partida.lado`: `A` o `B`.
- `partida.version`, usada para solicitar eventos faltantes, y `versionReglas`, que identifica la formula aplicada por el servidor.
- `posicionCuerda`, canonica desde el lado A, y `posicionDesdeMiLado`, positiva cuando favorece al usuario actual.
- jugadores, ronda, tiempos absolutos, pregunta, opciones y confirmacion `yaRespondi`.
- `eventos`, con las resoluciones ocurridas desde la version solicitada.

La respuesta correcta y la explicacion no aparecen en la pregunta activa. Se publican dentro de `RONDA_RESUELTA`, una vez cerrada la ronda.

## Reglas autoritativas

- Cada ronda dura diez segundos segun el reloj del servidor.
- Solo A acierta: movimiento `+2`; solo B acierta: `-2`.
- Ambos aciertan: el mas rapido mueve una marca.
- Una diferencia de hasta 200 ms se considera empate.
- Si ninguno acierta, la cuerda no se mueve.
- La posicion se limita entre `-4` y `+4`; alcanzar un extremo termina la partida.
- Si se agotan las preguntas, gana el lado favorecido por la posicion o se declara empate.
- Cada estudiante solo puede tener una busqueda o partida abierta.

## Seguridad y siguiente entrega

El backend usa transacciones y bloqueos por partida para evitar que dos solicitudes resuelvan la misma ronda simultaneamente. Tambien guarda un historial ordenado de eventos y no acepta tiempos calculados por el cliente.

## Conexion en tiempo real

Socket.IO usa el namespace `/tira-afloja` y exclusivamente el transporte WebSocket. El access token se entrega en el campo `auth` del handshake, nunca como parametro de la URL:

```text
URL base del backend + namespace /tira-afloja
auth.token = <access-token>
transports = [websocket]
```

El servidor verifica firma y vencimiento del JWT, existencia del usuario, rol de estudiante y correo verificado. Una conexion invalida recibe `tira:error` y se cierra.

### Mensajes que envia Flutter

- `tira:emparejar`: `{ area? }`.
- `tira:sincronizar`: `{ partidaId, desdeVersion? }`.
- `tira:listo`: `{ partidaId }`.
- `tira:responder`: `{ partidaId, ronda, preguntaId, respuestaId, idempotencyKey }`.
- `tira:abandonar`: `{ partidaId }`.
- `tira:latido`: no requiere datos y permite estimar la diferencia con el reloj del servidor.

Los mensajes tienen validacion estricta y un limite de 30 acciones por socket cada diez segundos. Las mutaciones llaman al mismo motor autoritativo utilizado por HTTP; WebSocket no contiene reglas paralelas.

### Mensajes que recibe Flutter

- `tira:conectado`: confirma autenticacion e indica si habia una partida recuperable.
- `tira:estado`: entrega el estado completo y los eventos faltantes.
- `tira:actualizada`: avisa que la version del servidor cambio; Flutter debe solicitar `tira:sincronizar` usando su ultima version aplicada.
- `tira:presencia`: informa si el rival se desconecto o regreso. Una desconexion no concede una victoria automaticamente.
- `tira:error`: error seguro con `codigo` y `mensaje`, sin detalles internos ni tokens.

El backend cierra rondas vencidas mediante un reloj propio, aunque ningun telefono consulte el estado. Los bloqueos de PostgreSQL garantizan que varias solicitudes o instancias no resuelvan dos veces una misma ronda.

### Reconexion

1. Socket.IO intenta recuperar la conexion durante un maximo de dos minutos.
2. Al conectarse nuevamente, el backend busca la partida abierta, une el socket a su sala privada y envia `tira:conectado` y `tira:estado`.
3. Flutter conserva la ultima `version` confirmada y emite `tira:sincronizar`.
4. El servidor devuelve los eventos posteriores a esa version y el estado completo actual.
5. Flutter reemplaza su posicion local por la posicion del servidor antes de reanudar animaciones.

La consulta HTTP versionada permanece como respaldo si el canal en tiempo real no esta disponible. No se agregara chat libre entre jugadores.

La publicacion actual funciona con una instancia de NestJS. Si el backend se replica horizontalmente, las salas de Socket.IO necesitaran un adaptador compartido, por ejemplo Redis, sin cambiar este contrato movil.

## Cliente Flutter

La aplicacion usa `socket_io_client` con transporte WebSocket, conexion nueva por partida y token enviado mediante `auth`. La interfaz incorpora:

- Eleccion entre rival real y CPU.
- Busqueda filtrada por materia o con banco mixto.
- Confirmacion de ambos jugadores antes de comenzar.
- Cuenta regresiva calculada con el reloj del servidor.
- Respuestas con UUID de idempotencia generado por intento.
- Animaciones basadas exclusivamente en eventos `RONDA_RESUELTA`.
- Presencia del rival y aviso de reconexion.
- Sincronizacion HTTP cada dos segundos mientras el socket intenta recuperarse.
- Abandono por WebSocket o HTTP, para no dejar al rival esperando.
- Modo CPU disponible cuando el estudiante prefiera practicar sin rival.

La version correcta de la cuerda siempre reemplaza cualquier estado visual local al reconectar. Flutter no calcula aciertos, ganador ni movimiento en partidas en linea.
