# Base de profesor e institución

La etapa 7A reemplaza el panel institucional ficticio por un flujo conectado. Cada docente usa una cuenta personal: no existen correos o contraseñas compartidos por una institución.

## Registro de profesor

El formulario de registro permite elegir `Estudiante` o `Profesor`. Flutter envía únicamente `ESTUDIANTE` o `PROFESOR`; el backend no acepta que una persona se registre como administrador de plataforma.

Las cuentas individuales de profesor deben verificar su correo antes de crear una institución o solicitar ingreso. Los códigos de referido estudiantiles no se aplican a profesores.

## Estados del vínculo

`GET /instituciones/profesor/contexto` devuelve uno de estos estados:

- `SIN_INSTITUCION`: la cuenta puede crear una institución o solicitar ingreso.
- `SOLICITUD_PENDIENTE`: muestra la institución solicitada y permite cancelar.
- `VINCULADO`: devuelve los datos de la institución, el rol del miembro y conteos agregados.

El contrato no lista nombres, correos ni resultados de estudiantes. Las estadísticas individuales y grupales se incorporarán cuando existan permisos y grupos autorizados.

## Crear una institución

`POST /instituciones` conserva la ruta existente, pero ahora ejecuta una transacción que:

1. crea la institución con plan gratuito y cupo inicial de 40 estudiantes;
2. vincula la cuenta personal;
3. crea su membresía con rol `PROPIETARIO`;
4. cancela cualquier solicitud pendiente anterior.

El código `INST-*` mostrado al propietario es exclusivamente para solicitudes de docentes. No reemplaza los futuros códigos temporales de grupos para estudiantes.

## Solicitar ingreso

- `POST /instituciones/solicitudes` recibe `codigoInstitucion` y un mensaje opcional.
- `DELETE /instituciones/solicitudes/me` cancela la solicitud pendiente de la cuenta activa.

Una solicitud no concede acceso por sí sola. La aprobación, el rechazo, las invitaciones y la transferencia de propiedad corresponden a la etapa 7B.

## Persistencia

La migración `20260831233000_teacher_institution_membership` agrega:

- roles `PROPIETARIO`, `ADMINISTRADOR` y `PROFESOR`;
- membresías personales con una sola institución por cuenta;
- solicitudes con estados auditables;
- una restricción que impide dos solicitudes pendientes simultáneas.

Los profesores y administradores ya vinculados se migran automáticamente. La primera cuenta vinculada de cada institución queda como propietario y las demás conservan un rol compatible.

Antes de probar contra PostgreSQL debe ejecutarse en la carpeta del backend:

```powershell
npx prisma migrate deploy
```

La aplicación conserva un repositorio demostrativo para revisar todo el flujo sin modificar una base real.
