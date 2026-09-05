# Backend HTTPS de staging en Render

Esta guia completa la parte de despliegue de la Etapa 7F. Render ejecuta la API
NestJS y Supabase aloja PostgreSQL. Flutter siempre consume la API HTTPS; nunca
se conecta directamente a las tablas ni recibe credenciales de base de datos.

## Alcance de este primer ambiente

`saberplus-api-staging` es un ambiente de desarrollo compartido, no el servidor
final de produccion. El plan gratuito permite validar la integracion sin pagar,
pero puede suspender la instancia cuando no recibe trafico y su disco local no
es persistente. Por eso:

- la primera solicitud despues de una pausa puede tardar;
- las conexiones WebSocket pueden interrumpirse durante una suspension o un
  despliegue y el cliente debe reconectarse;
- los archivos guardados en `/uploads` pueden perderse; los logos definitivos
  se moveran a Supabase Storage antes de produccion;
- el correo SMTP no se probara en el plan gratuito, que bloquea los puertos SMTP
  habituales. Mas adelante se usara un proveedor con API HTTPS o un servidor
  compatible;
- no se cargan datos reales de estudiantes ni contenido sin revisar.

## 1. Publicar la configuracion del backend

El archivo `render.yaml`, ubicado en la raiz del repositorio web/backend,
describe un servicio Node en la region Ohio, cercana al proyecto actual de
Supabase. Fija una version exacta de Node, compila NestJS, inicia
`npm run start:prod` y comprueba `/health/ready`.

Antes de crear el servicio, confirmar que estos cambios ya esten en GitHub:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\Icfes_Vida_reference"
git add render.yaml backend
git commit -m "feat: preparar despliegue HTTPS de staging"
git push origin main
```

Si la rama del equipo no es `main`, se reemplaza solamente el ultimo comando y
se elige esa misma rama en Render.

## 2. Crear el Blueprint

1. Entrar a Render y elegir **New > Blueprint**.
2. Conectar GitHub y seleccionar `Pavel2020123/Icfes_Vida`.
3. Elegir la rama que contiene el commit anterior.
4. Confirmar que Render encontro `/render.yaml`.
5. Mantener el nombre `saberplus-api-staging`, el plan Free y la region Ohio.
6. Completar las variables marcadas como secretas y crear el Blueprint.

El despliegue automatico queda apagado intencionalmente mientras validamos el
ambiente. Un cambio de esquema no debe llegar al servidor antes de que su
migracion haya sido revisada y aplicada una sola vez.

## 3. Variables solicitadas por Render

Render ya configura `NODE_VERSION`, `NODE_ENV` y `TRUST_PROXY`. Las otras
variables se introducen en su panel, nunca en `render.yaml`, commits, capturas o
mensajes:

| Variable | Valor para staging |
| --- | --- |
| `DATABASE_URL` | La conexion Session pooler funcional del usuario Prisma guardada en `.env.staging.local`. Puede conservar `sslmode=require`, `connection_limit=5` y `pool_timeout=20`. |
| `DIRECT_URL` | La conexion usada correctamente para las migraciones. En una red solo IPv4 puede ser tambien el Session pooler, con `sslmode=require`. |
| `JWT_SECRET` | Render la genera automaticamente. No reemplazarla ni reutilizarla. |
| `RANKING_ALIAS_SECRET` | Render genera otra distinta automaticamente. |
| `FRONTEND_URL` | El dominio HTTPS que recibira en el futuro los enlaces de correo. Si aun no existe, usar temporalmente la URL final del servicio Render. |
| `ALLOWED_ORIGINS` | Origenes web HTTPS separados por coma. Si por ahora solo existe Flutter, usar temporalmente la misma URL del servicio. Android/iOS no dependen de CORS. |

La URL prevista, si Render no cambia el nombre, es:

```text
https://saberplus-api-staging.onrender.com
```

Si Render asigna otro nombre, actualizar `FRONTEND_URL` y `ALLOWED_ORIGINS` con
la URL real y lanzar **Manual Deploy > Deploy latest commit**. Los enlaces de
verificacion y recuperacion de correo seguiran pendientes hasta implementar los
enlaces profundos de la app; esta URL temporal solo permite iniciar el servidor
de forma segura.

## 4. Comprobar el despliegue

Al terminar el primer deploy, abrir estas dos rutas reemplazando el dominio si
fuera necesario:

```text
https://saberplus-api-staging.onrender.com/health/live
https://saberplus-api-staging.onrender.com/health/ready
```

La primera confirma que NestJS esta vivo. La segunda ejecuta una consulta
minima a PostgreSQL y debe responder:

```json
{
  "status": "OK",
  "service": "saberplus-api",
  "database": "UP"
}
```

El endpoint de salud nunca devuelve la cadena de conexion ni detalles internos
del error. El juego Tira y Afloja utiliza el mismo dominio con `wss://` y hereda
la lista de origenes permitidos.

## 5. Conectar Flutter a staging

Cuando `/health/ready` responda correctamente, ejecutar la app con la URL real:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter run `
  --dart-define=APP_ENV=staging `
  --dart-define=API_BASE_URL=https://saberplus-api-staging.onrender.com `
  --dart-define=CONTENT_BASE_URL=https://saberplus-api-staging.onrender.com `
  --dart-define=DEMO_MODE=false
```

`staging` rechaza deliberadamente direcciones HTTP. La URL se suministra al
compilar y no contiene secretos.

## 6. Migraciones y siguientes despliegues

Las 38 migraciones actuales ya se aplicaron a `saberplus-dev`; el servidor no
debe repetirlas cada vez que arranca. Para un cambio futuro:

1. revisar y probar la nueva migracion localmente;
2. ejecutar el script controlado descrito en `SUPABASE_DEPLOYMENT.md`;
3. confirmar que `prisma migrate status` no tiene pendientes;
4. desplegar manualmente el commit compatible en Render;
5. comprobar `/health/ready` y los flujos afectados;
6. revertir el despliegue de aplicacion si falla, sin manipular manualmente el
   historial de migraciones.

## Referencias oficiales

- [Servicios web de Render](https://render.com/docs/web-services)
- [Limitaciones del plan gratuito](https://render.com/docs/free)
- [WebSockets en Render](https://render.com/docs/websocket)
- [Health checks de Render](https://render.com/docs/health-checks)
- [Especificacion de Blueprints](https://render.com/docs/blueprint-spec)
- [Version de Node en Render](https://render.com/docs/node-version)

