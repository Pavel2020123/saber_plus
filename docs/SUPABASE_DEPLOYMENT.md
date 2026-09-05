# Supabase para el backend de SaberPlus

La Etapa 7F utiliza Supabase exclusivamente como PostgreSQL administrado. NestJS
continua siendo la API y la fuente de verdad; Flutter no usa la Data API de
Supabase, no conoce credenciales de base y no consulta tablas directamente.

## Separacion de ambientes

Se crean proyectos independientes:

- `saberplus-dev`: desarrollo compartido y pruebas de integracion;
- `saberplus-prod`: produccion, creado solamente cuando staging este validado.

Nunca se reutiliza la base de produccion para pruebas automatizadas, datos
demostrativos o verificaciones que creen cuentas temporales.

## 1. Crear el proyecto de desarrollo

Desde Supabase Dashboard:

1. Crear una organizacion del equipo si todavia no existe.
2. Crear el proyecto `saberplus-dev` en la region disponible mas cercana al
   backend que se desplegara.
3. Generar una contrasena larga para PostgreSQL y guardarla en un gestor de
   contrasenas.
4. No copiar la contrasena, `DATABASE_URL` ni `DIRECT_URL` a chats, capturas,
   issues o commits.
5. Si SaberPlus solo usa Prisma, desactivar la Data API publica para reducir la
   superficie expuesta. Supabase Auth tampoco reemplaza la autenticacion NestJS.

## 2. Crear el usuario exclusivo de Prisma

En `SQL Editor`, ejecutar el siguiente bloque despues de reemplazar
`CONTRASENA_ALEATORIA`. La contrasena no debe conservarse dentro del historial de
archivos del proyecto.

```sql
create user "prisma" with password 'CONTRASENA_ALEATORIA' bypassrls createdb;
grant "prisma" to "postgres";

grant usage on schema public to prisma;
grant create on schema public to prisma;
grant all on all tables in schema public to prisma;
grant all on all routines in schema public to prisma;
grant all on all sequences in schema public to prisma;

alter default privileges for role postgres in schema public
  grant all on tables to prisma;
alter default privileges for role postgres in schema public
  grant all on routines to prisma;
alter default privileges for role postgres in schema public
  grant all on sequences to prisma;
```

Este usuario sigue la integracion oficial de Supabase con Prisma. `bypassrls` y
`createdb` se reservan para Prisma Migrate; nunca se entregan a Flutter.

## 3. Preparar las conexiones locales

En el backend:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\Icfes_Vida_reference\backend"
Copy-Item .env.staging.example .env.staging.local
```

Editar `.env.staging.local` sin publicarlo. En `Connect` del Dashboard se
obtienen las URL:

- `DATABASE_URL`: Supavisor **Session pooler**, puerto 5432, apropiado para un
  backend persistente sobre IPv4. Sustituir el usuario `postgres` por
  `prisma.PROJECT_REF`.
- `DIRECT_URL`: conexion directa, puerto 5432, usuario `prisma`, para
  migraciones. Requiere IPv6 o el complemento IPv4.

Si el equipo no tiene IPv6, se puede usar tambien el Session pooler en
`DIRECT_URL` para desplegar migraciones. No debe usarse el Transaction pooler
del puerto 6543 para Prisma Migrate.

Los caracteres especiales de la contrasena dentro de una URL deben codificarse,
por ejemplo `@` como `%40` y `#` como `%23`.

## 4. Validar y aplicar migraciones

El script carga las variables solo dentro del proceso actual y nunca imprime
las conexiones:

```powershell
.\tool\supabase_database.ps1 -Action validate
.\tool\supabase_database.ps1 -Action prepare
.\tool\supabase_database.ps1 -Action status
.\tool\supabase_database.ps1 -Action deploy -ConfirmDeploy
.\tool\supabase_database.ps1 -Action status
```

`deploy` usa las migraciones ya versionadas. En staging y produccion no se usa
`prisma db push` ni `prisma migrate dev`, porque pueden crear divergencias o
cambios no revisados.

La migracion inicial activa `uuid-ossp`, una extension disponible en Supabase.
Supabase la instala en el esquema `extensions`; la accion `prepare` incorpora
ese esquema al `search_path` del usuario `prisma` y crea en `public` una función
puente hacia `extensions.uuid_generate_v4()`. Prisma fija `public` durante las
migraciones, por lo que esta compatibilidad evita modificar el historial SQL.
El despliegue debe detenerse si cualquier migracion falla; no se marca
manualmente como aplicada sin investigar primero la causa.

## 5. Comprobar la base

La etapa queda verificada cuando:

- `prisma migrate status` informa que todas las migraciones estan aplicadas;
- el backend inicia con `NODE_ENV=production` y se conecta sin errores;
- registro, verificacion, login y perfil funcionan contra staging;
- diagnostico, practicas, juegos e instituciones persisten datos;
- ninguna tabla contiene datos demostrativos no aprobados;
- existe un respaldo inicial y se ha documentado su restauracion.

## 6. Despliegue del backend

El proveedor HTTPS recibira las variables mediante su gestor de secretos, no
mediante archivos versionados. El orden del release es:

1. instalar dependencias con `npm ci`;
2. compilar con `npm run build`;
3. aplicar migraciones una sola vez con `npm run db:deploy`;
4. iniciar con `npm run start:prod`;
5. verificar el endpoint raiz y los flujos E2E;
6. configurar la URL resultante como `API_BASE_URL` de Flutter staging.

La configuracion concreta de Render, sus limitaciones de staging, endpoints de
salud y conexion de Flutter se documentan en
[`RENDER_STAGING_DEPLOYMENT.md`](RENDER_STAGING_DEPLOYMENT.md).

No se cargan datos reales de estudiantes hasta completar las pruebas de
seguridad, respaldo y eliminacion de cuenta.

## Estado verificado de desarrollo

El 2 de septiembre de 2026, `saberplus-dev` quedó conectado con un usuario
exclusivo de Prisma. Las 38 migraciones versionadas se aplicaron correctamente,
Prisma informó cero migraciones fallidas y se comprobaron las tablas principales
de usuarios, preguntas, instituciones, Trivia Rush y Tira y afloja.

La base permanece sin semillas demostrativas. El contenido académico se cargará
mediante un proceso idempotente y revisado cuando el equipo entregue preguntas,
lecciones y recursos autorizados.

## Referencias oficiales

- [Integracion de Prisma con Supabase](https://supabase.com/docs/guides/database/prisma)
- [Metodos de conexion a PostgreSQL en Supabase](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Conexion directa y pool de Prisma](https://www.prisma.io/docs/orm/prisma-client/setup-and-configuration/databases-connections)
