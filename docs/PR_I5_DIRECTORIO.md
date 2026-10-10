# PR-I5 — Instituciones: checkpoint de implementación

Actualizado: 10 de octubre de 2026.

Rescate IC-1C quedó validado localmente; commits `df53768` (app) y `3fdf699`
(backend). No se ha verificado el push en este checkpoint.

## PR-I5A: base del directorio en el backend

Implementadas rutas autenticadas para buscar instituciones aprobadas y consultar
su identidad pública. Listado de 20 por página, búsqueda por nombre, `hayMas`,
validación y detalle con 404 uniforme para registros ocultos o inexistentes.
Por ahora solo se publican ID y nombre; no códigos, contactos ni expedientes.

Validación backend: 29 pruebas dirigidas aprobadas (16 directorio, 13 aprobación),
TypeScript sin errores y formato conforme. Sin ensayo PostgreSQL/Android ni suite
global en esta entrega. Flutter solo recibió documentación, no código móvil.

Código y contrato completo en el repositorio **SaberPlus-Backend**:
`backend/src/institucion/institution-directory.*` y
`backend/docs/PR_I5_DIRECTORIO.md`. No son archivos de este repositorio Flutter.

P4-C se reutiliza: no rehacer la aprobación. Las solicitudes docentes actuales
no son solicitudes estudiantiles y no deben otorgar rol PROFESOR a estudiantes.

## Lo siguiente, en orden

1. Conectar en Flutter listado, búsqueda, paginación y detalle mínimo, con
   carga/vacío/error/reintento. **Todavía no hay pantalla nueva en esta entrega.**
2. Añadir PR-I5-T: departamento y municipio oficiales, selectores dependientes,
   persistencia/revisión y filtros; no deducir ubicación a partir del nombre.
3. Perfil institucional, edición autorizada por propietario y archivos C5.
4. Solicitudes estudiantiles con respuesta visible y código institucional privado;
   conservar separados códigos y permisos de grupos/profesores.
5. Ensayo con API/PostgreSQL y Android, documentando cada prueba.

PR-I5 completa sigue **en curso**. Ranking institucional PR-I6/PR-I6-T viene
después. OV-1, perfiles e insignias anuales permanecen en el alcance acordado.
Ver [territorio y orientación](ORIENTACION_Y_TERRITORIO.md).

## Relevo

Leer primero [ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md) y descargar ambos repos.
No reiniciar la batería de Rescate ni asumir servicios vivos desde su acta.
Las pruebas HTTP del directorio usan dobles de base de datos: no confundirlas
con SQL real o aceptación física. Continuar con el cliente Flutter del punto 1.
