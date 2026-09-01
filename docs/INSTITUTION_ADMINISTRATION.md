# Administración institucional

La etapa 7B organiza al equipo docente sin crear credenciales compartidas. Cada propietario, administrador y profesor conserva una cuenta personal verificada.

## Permisos

| Acción | Profesor | Administrador | Propietario |
| --- | --- | --- | --- |
| Consultar su espacio docente | Sí | Sí | Sí |
| Revisar solicitudes | No | Sí | Sí |
| Invitar profesores | No | Sí | Sí |
| Invitar o cambiar administradores | No | No | Sí |
| Retirar profesores | No | Sí | Sí |
| Retirar administradores | No | No | Sí |
| Consultar auditoría | No | Sí | Sí |
| Transferir la propiedad | No | No | Sí |

Un administrador nunca puede modificar o retirar al propietario. La propiedad se transfiere únicamente a un miembro existente y exige escribir el código institucional. El propietario anterior queda como administrador para evitar perder el acceso accidentalmente.

## Solicitudes

Una solicitud pendiente puede aprobarse o rechazarse una sola vez. La aprobación:

1. comprueba que la cuenta siga siendo de profesor y no pertenezca a otra institución;
2. vincula la cuenta con rol `PROFESOR`;
3. cancela otras solicitudes pendientes de esa cuenta;
4. registra quién aprobó el ingreso.

## Invitaciones

Las invitaciones se crean para el correo de una cuenta personal y expiran después de siete días. Pueden existir antes de que el profesor termine su registro, pero solo una cuenta de profesor con correo verificado puede aceptarlas.

Aceptar una invitación cancela solicitudes e invitaciones incompatibles. No se envían contraseñas, enlaces con acceso automático ni códigos que otra persona pueda reutilizar.

## Auditoría

Se registran la institución, la acción, el actor, la cuenta afectada, la fecha y un detalle técnico limitado. El panel muestra las treinta acciones más recientes. No se guardan contraseñas, tokens ni resultados académicos en la auditoría.

Las acciones registradas incluyen creación institucional, revisión de solicitudes, creación o cancelación de invitaciones, aceptación o rechazo, cambios de rol, retiro de miembros y transferencia de propiedad.

## Rutas del backend

- `GET /instituciones/me/administracion`
- `PATCH /instituciones/me/solicitudes/:id`
- `POST /instituciones/me/invitaciones`
- `DELETE /instituciones/me/invitaciones/:id`
- `GET /instituciones/invitaciones/me`
- `POST /instituciones/invitaciones/:id/responder`
- `PATCH /instituciones/me/miembros/:id/rol`
- `DELETE /instituciones/me/miembros/:id`
- `POST /instituciones/me/transferir-propiedad`

## Despliegue

La migración `20260901063000_institution_administration` agrega invitaciones, auditoría y una restricción de base de datos que permite un solo propietario por institución.

```powershell
npx prisma migrate deploy
```

La siguiente entrega 7C agregará grupos con códigos temporales y aceptación explícita de estudiantes. Las importaciones masivas continuarán fuera de la aplicación móvil.
