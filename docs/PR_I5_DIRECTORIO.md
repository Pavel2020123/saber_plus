# PR-I5 — Instituciones: checkpoint de implementación

Actualizado: 11 de octubre de 2026. **Contrato vigente T4:** filtros por nombre,
departamento y municipio; lista/detalle incluyen ubicación oficial opcional.
Sigue [T5 ensayo conjunto](PR_I5_T_TERRITORIO.md). Los apartados PR-I5A/B
conservan su alcance histórico anterior a T4, no limitan el contrato actual.

Rescate IC-1C quedó validado localmente; commits `df53768` (app) y `3fdf699`
(backend). No se ha verificado el push en este checkpoint.

## PR-I5A: base del directorio en el backend

Implementadas rutas autenticadas para buscar instituciones aprobadas y consultar
su identidad pública. Listado de 20 por página, búsqueda por nombre, `hayMas`,
validación y detalle con 404 uniforme para registros ocultos o inexistentes.
En PR-I5A solo se publicaban ID y nombre; sin códigos de ingreso, contactos ni expedientes.

Validación backend: 29 pruebas dirigidas aprobadas (16 directorio, 13 aprobación),
TypeScript sin errores y formato conforme. Sin ensayo PostgreSQL/Android ni suite
global en PR-I5A. En ese primer commit Flutter solo recibió documentación;
el cliente móvil se incorpora en PR-I5B, descrito más abajo.

Código y contrato completo en el repositorio **SaberPlus-Backend**:
`backend/src/institucion/institution-directory.*` y
`backend/docs/PR_I5_DIRECTORIO.md`. No son archivos de este repositorio Flutter.

P4-C se reutiliza: no rehacer la aprobación. Las solicitudes docentes actuales
no son solicitudes estudiantiles y no deben otorgar rol PROFESOR a estudiantes.

## Lo siguiente, en orden

### PR-I5B — Cliente Flutter implementado

Entrada **Más → Buscar instituciones**, ruta
`/student/more/institution-directory`. Repositorio tipado, búsqueda por nombre,
paginación, detalle consultado de nuevo en servidor, carga/vacío/error/reintento.
La búsqueda nueva reinicia la página; respuestas antiguas no sustituyen resultados
de otra consulta. Los providers se invalidan al cambiar de cuenta. La demo usa
ejemplos explícitos y nunca sustituye una caída de la API real.

No modifica el ingreso por códigos de grupos ni ofrece una solicitud estudiantil
ficticia. En PR-I5B se veía nombre e identidad; ubicación se añadió en T4,
logo y afiliación aún esperan sus contratos. Para modo real debe ejecutarse el backend actualizado;
En la implementación inicial no se operaron servicios; el ensayo posterior con
API y APK está registrado más abajo.

Pruebas dirigidas: `flutter test test/institution_directory_test.dart`, 8 aprobadas.
Incluyen contratos HTTP, error sin fallback demo, paginación, reintento, detalle,
respuesta tardía y vacío demo. No acreditan aceptación en celular ni SQL real.

Validación final PR-I5B: `dart format` aplicado, `flutter analyze` sin incidencias
y suite completa `flutter test`: **762 aprobadas, 10 opt-in omitidas**.
La primera corrida detectó una prueba de Tiempo estudiado que pulsaba un elemento
del menú sin desplazarse; se corrigió con scroll explícito y se repitió toda la
suite satisfactoriamente. No se desactivaron pruebas para conseguir este resultado.
Commit previsto de esta entrega Flutter:
`feat: integrar directorio institucional en la app`.

### Ensayo local aprobado — 10 de octubre

Docker PostgreSQL temporal propio y 61 migraciones; API43187 y panel4173 HTTP200.
Celular Android autorizado y reverse43187 configurado. APK debug actual compilada
y paquete separado `.i2validation` comprobado; instalación USB **Success** y
actividad abierta. Inicio de sesión y recorrido físico confirmados por el usuario.
Nuevo script backend `tool/test_local_institution_directory.mjs` ejecutado con la
sesión propia: 25 instituciones aprobadas sintéticas, 4 ocultas; páginas20/5,
búsqueda, vacío, campos públicos, detalles ocultos404, consulta inválida400 y
anónimo401 aprobados contra AppModule/PostgreSQL reales. La siembra directa es
fixture de directorio, no acredita el flujo ADMIN de aprobación P4-C.
El script permite `--suspend` después de probar la ficha y exige ownership local.
No guardar contraseñas, tokens ni owner.json en Git. Credenciales efímeras nuevas.
**Checkpoint físico confirmado por el usuario:** inicio de sesión y acceso a
Más → Buscar instituciones; aparecen las instituciones de ensayo, Página1 y
Siguiente tal como se indicó. Primera pantalla aprobada en Android.
**Búsqueda y paginación físicas aprobadas:** usuario confirma `ensayo 01` con
resultado único, `inexistente` con mensaje vacío, limpiar/buscar y Página2 con
cinco instituciones (21 a25). No confundir con los checks HTTP automáticos.
**Detalle físico aprobado:** usuario confirma nombre de ensayo01, texto que
consultar no vincula a la institución y ausencia de botón de Solicitar ingreso.
**Error de red físico aprobado:** reverse43187 retirado; API del PC sigue HTTP200.
Usuario confirma que Actualizar muestra error del directorio y Reintentar.
**Recuperación de red física aprobada:** reverse43187 restaurado y API HTTP200;
usuario confirma que Reintentar recupera el listado de instituciones de ensayo.
**Suspensión aplicada al fixture:** ensayo01 SUSPENDIDA en la base propia.
Comprobación HTTP real con ADMIN de ensayo: detalle404, búsqueda ensayo01 vacía,
24 aprobadas restantes (Página2 cuatro). No reemplaza observación Android.
**Suspensión física aprobada:** usuario confirma ambos pasos indicados: reabrir
ensayo01 muestra institución no disponible; actualizar listado/buscar ensayo01
no devuelve resultados. La ficha abierta conserva su lectura anterior hasta
una nueva consulta; no se implementó actualización en tiempo real.

**PR-I5A/B cerrada en este alcance local:** backend, cliente, HTTP/PostgreSQL y
recorrido Android documentados. No acredita despliegue remoto, iOS, aprobación
ADMIN P4-C, flujo docente/grupos físico ni etapas posteriores de institución.
Servicios de sesión efímera: comprobar estado y vigencia antes de reutilizarlos.
Continuación actual: [PR-I5-T1/T2/T3/T4 implementadas](PR_I5_T_TERRITORIO.md);
sigue T5 ensayo territorial conjunto. No repetir automáticamente toda esta batería.

### Continuación

1. Cliente mínimo PR-I5B y ensayo local conjunto con PR-I5A aprobados.
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
Las pruebas Jest usan dobles de base de datos; el script local posterior usa
PostgreSQL real y el recorrido físico tiene confirmación del usuario. Mantener
esas evidencias separadas. Siguiente entrega: PR-I5-T5 (ensayo conjunto).
