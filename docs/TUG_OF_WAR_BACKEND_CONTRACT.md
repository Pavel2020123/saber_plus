# Contrato del backend de Tira y afloja

## Estado de la integracion

La etapa 6F-D-C se divide en tres entregas:

- **6F-D-C-A, terminada:** esquema PostgreSQL, emparejamiento, reloj y rondas autoritativas, respuestas idempotentes, abandono y registro versionado de eventos.
- **6F-D-C-B, pendiente:** transporte en tiempo real autenticado, notificaciones inmediatas y protocolo de reconexion.
- **6F-D-C-C, pendiente:** conexion de la arena Flutter con rivales reales, estados de red y regreso seguro al modo local.

Mientras B y C no esten terminadas, la aplicacion conserva el duelo local contra CPU.

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

En 6F-D-C-B estos mismos eventos se enviaran por una conexion autenticada en tiempo real. La consulta HTTP versionada permanecera como mecanismo de recuperacion y reconciliacion; no se agregara chat libre entre jugadores.
