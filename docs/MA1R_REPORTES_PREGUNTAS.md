# MA-1R — Reportes de preguntas: checkpoint R1–R4

19 de octubre de 2026. Propietario. **R1 autorizada; R2 backend y
[R3 app/panel](MA1R_R3_APP_PANEL.md) implementados/probados localmente.
R4 cerrada localmente, incluido el remate visual.**
Acta técnica actual: `backend/docs/MA1R_R2_BACKEND.md` en SaberPlus-Backend.
Regresión backend R2 histórica:121 suites/1.560; final R4 del19:121/1567 tras fix.
R3:32 dirigidas Flutter y109 ADMIN aprobadas al cierre de esa fase.
R4 cerrada localmente, sin despliegue; evidencia vigente en el acta inferior.

**Resultado automático del19:**45/45 PostgreSQL/HTTP reales en base aislada propia;
backend121 suites/1567, ADMIN109/sintaxis26, controles locales12, build/TypeScript
y análisis Flutter aprobados. Regresión Flutter920/13 opt-in omitidas.
Pérdida de respuesta tras commit, rollback, carreras y RLS efectivos probados.
La repetición detectó y corrigió P2010/40001 en carrera ADMIN:7 unitarias nuevas,
100 dirigidas y dos45/45 posteriores al fix; no dar por estable un solo pase inicial.
Incidencias EPERM de build y timeout inicial de certificado, recuperación y límites
en [acta R4](MA1R_R4_VALIDACION_LOCAL.md). Sin cambio de código de certificados.
API/base/credenciales humanas ya cerradas/limpiadas; no reutilizar su archivo
privado. Bases automáticas también limpiadas. La sesión posterior de remate se
describe abajo; APK reinstalada/retirada del botón confirmadas. Código guardado
e integrado según entrega Git inferior; siguen preparación C5 y controles de
staging/operación separados, no repetir12.

**Remate posterior del19:** por petición del propietario se levantó una sesión
temporal nueva de API/panel/Docker y se instaló por USB la APK corregida (Success,
paquete separado verificado). Propietario confirmó ausencia del botón y borrador
conservado tras flecha/reapertura. **Cierre local R4 confirmado**, no por instalar
solamente. Acta R4 registra la nueva sesión; claves anteriores caducadas. No repetir12.

**Continuación R4 del18:** [preparación local](MA1R_R4_VALIDACION_LOCAL.md): API/panel
y base temporal levantados,67 migraciones solo allí y3 smoke HTTP/DB aprobados.
No acredita suite integrada completa: casos1–12 Android confirmados (12/12),
creación/límite500/duplicado/reintento tras corte previo verificados por SQL de
solo lectura dentro de sus límites; caso7 error/recuperación del listado aprobado
el19; caso8 borrador/motivo conservados con flecha superior/reapertura confirmados.
Caso9: lista vacía en zero, tres reportes al regresar a student y borrador vacío
tras logout confirmados; sin escenario humano de recibo tardío abierto. Caso10,
moderación ADMIN ya confirmada: dos pendientes/uno En revisión, SQL revisión1,
recibo DECIDIR y auditoría/motivo/actor correctos. Caso11: cierre RESUELTO y cobertura
de3 a2 abiertos/distintas1/publicadas2 confirmados; hash basal banco/XP inalterado,
auditoría/recibo revisión2 coherentes en SQL. Caso12 letra grande/listado y teclado/
edición/desplazamiento/acceso a botones confirmados, no auditoría de accesibilidad
completa. Suite técnica específica PostgreSQL/HTTP y regresiones posteriores
aprobadas según el resumen del19 superior.
Se retiró botón inferior redundante;
corrección reinstalada/confirmada después, sin cambiar la persistencia en sesión.
Propuesta posterior [MA-1R-UX1: ocultar y Deshacer](MA1R_UX1_OCULTAR_DESHACER.md),
sin implementación ni eliminación de reportes durante R4.
Reanudación del19: sesión temporal nueva y tres reportes preparados automáticamente
por las API reales para continuar7; no se repiten ni se suman casos humanos.
Acceso Más → Mis reportes implementado, análisis y80 dirigidas aprobados el18;
APK instalado por USB el19 con Success; propietario confirmó acceso y tres
pendientes. Error sin red y recuperación de los tres confirmados por propietario;
reverse43187 restaurado. Con caso12 confirmado, **12/12 humanos aprobados dentro
de sus límites**; retirada del botón inferior reinstalada/confirmada después,
con cierre local R4. Los hitos previos conservan su alcance/fecha originales.

El trabajo original de R1 fue lectura de código/documentación, sin implementación, migraciones, servicios,
Docker, instalación Android, pruebas funcionales, commit, push ni merge en R1.
No se tocó OV-1 ni CHECKPOINT_OV1; el compañero conserva ese frente.

Contrato técnico propuesto y evidencia backend: `backend/docs/MA1R_REPORTES_PREGUNTAS.md`
en SaberPlus-Backend. Este archivo define UX/checkpoint; no duplicar otro contrato
API independiente. R2 es el contrato efectivo y R3 registra su consumo compatible.

## Entrega Git del19 y dependencia documental

Commits funcionales locales autorizados: Flutter `418c291`, backend/panel `a747c32`.
Documentación: app `0a622e6`, API `6a74f55`. Publicadas e integradas en main por
[app PR #6](https://github.com/Pavel2020123/saber_plus/pull/6) (`21757a1`) y
[backend PR #9](https://github.com/Pavel2020123/SaberPlus-Backend/pull/9) (`eef0d40`).
CI backend del PR aprobado; QA-1 Flutter remoto pendiente. Sin despliegue ni SQL remoto.
Siguiente bloque recomendado: preparación local C5. Este checkpoint sustituye
las esperas para crear commits/publicar/integrar de las notas anteriores.

### Base histórica de R1

- App `894bcc0`, backend `56a65fb`, sobre los main institucionales e679c50/388bb18.
- Rama R1 local en ambos: `docs/ma1r-r1-reportes`, desde esos commits documentales.
  R2–R4 continúan en `feat/ma1r-reportes-preguntas`; commits actuales arriba.
  El fetch no mostró que docs/estado-post-instituciones ya estuviera en main.
  R1 puede auditar sin esperar, pero publicar/revisar la base documental y la
  propuesta en orden; no mezclar un PR funcional ni hacer merge automático.
- Guardar cualquier nuevo trabajo antes de cambiar ramas. No reset/force-push,
  no operar Supabase/Render ni reutilizar credenciales de pruebas anteriores.

## Qué existía al auditar R1 (antecedente del17)

Esta tabla conserva el punto de partida, no el estado actual. R2 agregó la API;
R3 agregó botón/formulario, lista propia y ADMIN según su acta. No repetirlos.

| Evidencia | Encontrado | Qué significa para MA-1R |
|---|---|---|
| [Cobertura](COBERTURA_DEL_BANCO.md) | Panel y conteos por subtema ya existen | Añadir reportes, no reconstruir toda la cobertura. |
| Backend/admin | No hay reporte académico; false/null explícitos y validados estrictamente | No convertirlo a cero. Nuevo backend requiere panel compatible. |
| [Modelos de práctica](../lib/features/practice/domain/practice_models.dart) | Pregunta y revisión tienen ID/contenido, sin revisión semántica común | No asumir que una revisión editorial es una versión de lo visto. |
| [Pantalla de práctica](../lib/features/practice/presentation/practice_session_page.dart) | _ReviewCard muestra pregunta, opciones y explicación después de calificar | Lugar recomendado para «Reportar un problema» inicial. No se añadió botón. |
| [Repositorio remoto](../lib/features/practice/data/remote_practice_repository.dart) | Calificación e historial autenticados ya consumidos | Reutilizar sesión/red, con repositorio propio de reportes, sin rehacer práctica. |
| [Historial](../lib/features/practice/domain/practice_history_models.dart) | IDs y origen de respuestas propias | Puede ayudar a consulta posterior; no garantiza snapshot completo antiguo. |
| [Marcar difícil](../lib/features/difficult_questions/domain/difficult_question_models.dart) | Marca personal local | No significa pregunta incorrecta ni envía reporte al ADMIN. |
| [Reportar rival](../lib/features/battles/data/remote_battle_repository.dart) | Denuncia del juego separada | No reciclar sus tablas, rutas o identidad reportada. |
| Editor backend | Edición directa archiva pregunta anterior y crea otro ID | Conservar reporte sobre ID original, no trasladarlo automáticamente. |

Detalles inspeccionados en backend: guards, schema, simulacros, editor/huella y
reclasificación, cobertura, panel/API/demo y contratos de Guardián/Cima/Rescate.
No se auditó todo el proyecto ni se certificó cada modalidad por revisar esos archivos.

## Propuesta de experiencia inicial

1. Alumno real con correo verificado, después de calificar una práctica por
   subtema, aleatoria o simulacro por área. Puede reportar incluso si acertó.
2. En revisión, pulsar «Reportar un problema» sin salir/perder el resultado.
   Seleccionar motivo y escribir detalle opcional (500 caracteres Unicode;
   OTRO requiere 10). No subir capturas ni escribir información personal.
3. Confirmar una vez; mostrar «Reporte recibido» solo con recibo validado.
   Cancelar no envía nada. Deshabilitar doble envío mientras se confirma.
4. Ante timeout: conservar texto e intento; «Consultar envío» y «Reintentar el
   mismo envío», sin crear otro UUID ni afirmar que no se guardó.
5. Consulta propia de reportes/estado; nunca mostrar identidad de otros alumnos,
   nota interna del ADMIN ni una solución no autorizada por un examen vigente.
6. ADMIN global revisa en la página y usa el editor actual si debe corregir.
   Reportar/revisar no archiva preguntas, recalifica, da XP ni altera rankings.

No se propone un paso de aprobación para subir preguntas: **Guardar y publicar
directamente sigue igual**. Revisar un reporte es una gestión de incidencias,
no vuelve al flujo editorial complejo que se retiró.

### Reglas propuestas a confirmar

- Motivos: enunciado confuso, respuesta incorrecta, explicación incorrecta,
  imagen que no carga y otro. Profesor/administrador institucional no modera;
  primera entrega de creación para ESTUDIANTE, no demo. Sin exigir plan vigente
  para reportar una pregunta ya respondida y acreditada por el servidor.
- Estados: PENDIENTE → EN_REVISION → RESUELTO/DESCARTADO. Reabrir solo ADMIN,
  a EN_REVISION con motivo y auditoría; sin borrado ni cierre automático.
- Un reporte por estudiante+ID de pregunta+motivo. Mismo motivo de la misma
  versión devuelve el propio anterior, incluso tras cerrar; no sobrescribe
  comentario ni reabre. Otro motivo u otro ID editorial puede tener reporte.
- Reintentos por operación estable y payload, con aislamiento de cuenta. Cambio
  de sesión descarta datos/respuestas tardías y nunca manda con el nuevo usuario.
- Límite propuesto: 20 reportes nuevos/cuenta/24 h; 20 solicitudes de escritura/
  minuto/cuenta y protección IP compatible con red compartida. Por aprobar.

## Cómo conservar la versión sin inventar evidencia

El ID original preservado por el editor identifica la pregunta respondida.
Servidor comprobará uso propio y capturará contenido/clasificación/medios al
recibir el reporte, incluso si el ID está archivado. No aceptará enunciados,
soluciones, usuario/rol ni clasificación arbitrarios enviados por el cliente.

**Límite importante:** snapshot recibido no prueba que todo se veía exactamente
así en el teléfono. Historial antiguo no conserva todos los campos; las URLs no
congelan bytes de imágenes. La huella de duplicados no incluye toda solución ni
explicación; la revisión del editor también depende de contadores de uso.
Si se exige evidencia exacta desde que se muestra cada pregunta, habrá que
ampliar antes R2 con evidencia inmutable emitida por el servidor por intento.
No se implementó ni aprobó esa ampliación aquí.

## Cobertura y alcance posterior

Propuesta: reportes abiertos = PENDIENTE + EN_REVISION; mostrar también número
de preguntas distintas afectadas, sin confundirlo con reportantes o total histórico.
Conservar incidencias sobre IDs archivados, bajo la clasificación capturada.
Backend viejo false/null y backend nuevo deben coexistir en el panel compatible;
no desplegar un cambio de esos valores antes de preparar el consumidor.

Juegos, diagnóstico, histórico AM/PM, cuaderno y repasos tendrán adaptadores
posteriores cuando acrediten pregunta vista/respondida y permisos sin exponer
soluciones futuras. No se eliminan ni se da por implementado su reporte ahora.
Sigue C5 para adjuntos/medios generales y C4/C6 para versionado/editorial amplio.

## Checkpoint y trabajo siguiente

| Parte | Estado verificable | Pendiente |
|---|---|---|
| R1 | Auditoría y flujo inicial autorizados | Retención/operación y ampliaciones siguen sujetas a aprobación antes de publicar |
| R2 | Backend local, build/TypeScript y121 suites/1.560; SQL aplicado solo en bases temporales por R4 | Sin SQL remoto/despliegue; contrato en acta backend MA1R_R2_BACKEND |
| R3 | App, ADMIN, demo y cobertura compatibles;32 dirigidas Flutter/109 ADMIN iniciales, recorrido real/remate visual confirmado en R4 | Integración de cambios mediante commits/PR/CI; [acta R3](MA1R_R3_APP_PANEL.md) histórica |
| R4 |Cerrada localmente:67 migraciones temporales;12/12 humanos y45/45 HTTP/PostgreSQL repetidas tras fix P2010/40001; backend121/1567, Flutter920/13 opt-in omitidas, análisis/build, ADMIN109, controles12 y remate visual confirmados | Decidir commits/PR/CI. [Acta R4](MA1R_R4_VALIDACION_LOCAL.md), sin despliegue; retención/operación son gates posteriores |

Primera entrega autorizada: práctica/simulacro después de calificar, motivos/
estados, duplicados y snapshot recibido, no evidencia histórica exacta.
R2 mantiene false/null por defecto para el panel viejo; R3 ya solicita
`reportesVersion=1` para los conteos nuevos. Recibos son del envío original;
recargar la lista propia para estado actual, no sobrescribir revisiones nuevas.
Retención y eliminación/anonimización de cuentas deben quedar acordadas
antes de publicar, no guardar reportantes indefinidamente por defecto.

R1 no necesitó celular ni servicios; R2 registra las pruebas unitarias/build
ejecutadas. R4 de PostgreSQL/HTTP/Android sigue pendiente. Antes de integrar R2,
coordinar schema/migraciones con OV-1 e integrar la base documental por PR.
P5/D3 siguen pausadas; no migraciones/despliegues por seguir este archivo.

Comprobación documental R1: destinos de enlaces locales y diff/whitespace
verificados, sin enlaces a archivos inexistentes. No verifica anchors ni páginas
externas, ni sustituye las pruebas reales de integración aún pendientes.
