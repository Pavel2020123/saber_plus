# Grupos y vinculación segura

La etapa 7C reemplaza el ingreso automático con códigos permanentes por un flujo temporal y con aceptación explícita. El estudiante puede usar SaberPlus sin pertenecer a una institución y consultar un código no modifica su cuenta.

## Flujo del estudiante

1. El profesor crea un código para un grupo, con vigencia de una hora, un día o siete días y entre 1 y 200 usos.
2. El estudiante escribe el código y recibe una vista previa con institución, grupo, grado, vencimiento y usos disponibles.
3. Si ya pertenece al grupo o está vinculado a otra institución, la aplicación informa el estado sin hacer cambios.
4. Para ingresar debe marcar una aceptación que identifica expresamente la institución y el grupo.
5. El backend vuelve a validar el código y consume un uso dentro de la misma transacción que crea la vinculación.

La aceptación guarda fecha, procedencia del código y el indicador `aceptacionExplicita`. Un código agotado, vencido, revocado o inexistente produce la misma respuesta genérica durante la consulta para evitar revelar códigos válidos.

## Permisos

| Acción | Profesor asignado | Administrador | Propietario |
| --- | --- | --- | --- |
| Consultar su grupo | Sí | Sí | Sí |
| Generar o revocar códigos de su grupo | Sí | Sí | Sí |
| Retirar un estudiante de su grupo | Sí | Sí | Sí |
| Crear o eliminar grupos | No | Sí | Sí |
| Actualizar el nombre de un grupo asignado | Sí | Sí | Sí |
| Asignar o retirar profesores | No | Sí | Sí |
| Agregar estudiantes manualmente | No | Sí | Sí |

Un profesor con rol `PROFESOR` solo recibe los grupos que le asignaron. La asignación a un grupo no cambia su rol institucional ni crea otra cuenta.

## Protección de los códigos

- El código completo tiene el formato `GRP-XXXXXXXX` y se muestra una sola vez al crearlo.
- PostgreSQL almacena un hash SHA-256, nunca el código en texto plano.
- Después de crearlo, el panel solo recibe los últimos cuatro caracteres.
- Cada código tiene vencimiento, límite de usos, estado revocable y creador identificable.
- El contador de usos se incrementa atómicamente para impedir que dos ingresos consuman el último cupo.
- Crear, revocar, asignar, retirar e ingresar queda registrado en la auditoría institucional.

El campo histórico `codigoIngreso` de `Clase` permanece temporalmente para compatibilidad de la base, pero no se devuelve a Flutter y la ruta antigua de unión está deshabilitada.

## Rutas del backend

### Estudiante

- `POST /instituciones/grupos/vista-previa`
- `POST /instituciones/grupos/aceptar`
- `GET /instituciones/grupos/estudiante`

### Equipo docente

- `GET /instituciones/me/grupos`
- `POST /instituciones/me/grupos`
- `PATCH /instituciones/me/grupos/:grupoId`
- `DELETE /instituciones/me/grupos/:grupoId`
- `POST /instituciones/me/grupos/:grupoId/codigos`
- `DELETE /instituciones/me/grupos/:grupoId/codigos/:codigoId`
- `POST /instituciones/me/grupos/:grupoId/profesores`
- `DELETE /instituciones/me/grupos/:grupoId/profesores/:miembroId`

## Despliegue

La migración `20260901143000_temporary_group_codes` crea las asignaciones docentes, los códigos temporales y la evidencia de aceptación. En el backend se ejecuta:

```powershell
npx prisma migrate deploy
```

Flutter nunca debe conectarse directamente a PostgreSQL o Supabase. Las reglas de cupo, permisos, códigos y auditoría pertenecen al backend NestJS.
