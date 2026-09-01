# Batallas asíncronas

La etapa 6G-E conecta Flutter con el motor autoritativo de batallas del backend. No es el mismo juego que Tira y afloja: aquí cada estudiante puede responder en un momento distinto y la partida permanece disponible durante 24 horas.

## Formas de jugar

- **Rival al azar:** el backend empareja por modo y área. Si no hay una partida compatible, deja la búsqueda abierta.
- **Invitación privada:** crea un código aleatorio de ocho caracteres. El código identifica una partida temporal, nunca una cuenta.
- Modos disponibles: Carrera fantasma, Duelo relámpago y Supervivencia.
- Las preguntas, el reloj de cada respuesta, la puntuación, el resultado y el XP se calculan en el servidor.
- La respuesta correcta y la explicación permanecen ocultas hasta que la batalla queda finalizada.

La cuenta demostrativa acepta `SABER123` y permite recorrer el flujo sin conectarse al servidor.

## Privacidad y convivencia

- La API móvil no ofrece búsqueda por nombre o correo.
- El rival solo se representa como `Rival anónimo`; no se envían identificadores, nombre, foto, grado ni institución.
- Flutter valida el contrato y rechaza una respuesta que incluya campos personales.
- No existe chat entre estudiantes.
- El bloqueo se realiza desde una batalla: el servidor resuelve internamente la otra cuenta y evita emparejamientos posteriores en ambas direcciones.
- La lista de bloqueos usa etiquetas genéricas y permite desbloquear sin revelar identidades.
- Un reporte solo puede crearlo alguien que participe en la batalla. El servidor obtiene internamente al reportado y acepta un único reporte por participante y batalla.
- Motivos: conducta inapropiada, nombre inapropiado, posible trampa u otro.

## Rutas del backend

Todas requieren JWT y correo verificado. Las batallas son contenido gratuito para estudiantes y no usan el antiguo muro de pago.

- `GET /batallas`
- `POST /batallas`
- `POST /batallas/invitaciones/unirse`
- `GET /batallas/:id`
- `POST /batallas/:id/iniciar`
- `POST /batallas/:id/respuestas`
- `POST /batallas/:id/finalizar`
- `POST /batallas/:id/cancelar`
- `POST /batallas/:id/bloquear-rival`
- `POST /batallas/:id/reportes`
- `GET /batallas/bloqueos`
- `DELETE /batallas/bloqueos/:id`

La migración `20260831213000_harden_batallas_asincronas` agrega códigos de invitación, bloqueos y reportes. Antes de probar con PostgreSQL debe desplegarse con:

```powershell
npx prisma migrate deploy
```

## Reglas contra abuso

- Máximo de cinco batallas diarias con XP.
- Máximo de dos recompensas con el mismo rival en 24 horas.
- Un bloqueo impide tanto que el bloqueador encuentre al bloqueado como el caso inverso.
- Los códigos vencen con la batalla, son de un solo uso y la unión se confirma de forma transaccional.
- Solo una respuesta por pregunta y participante; las preguntas deben contestarse en orden.
- Cada pregunta publicada debe tener al menos dos opciones y exactamente una respuesta correcta para entrar al banco de batalla.

## Acceso en Flutter

`Practicar > Batallas asíncronas` abre el panel. Desde allí se puede buscar rival, crear o ingresar un código, continuar partidas, revisar resultados y administrar bloqueos.
