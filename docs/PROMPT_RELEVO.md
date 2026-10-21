# Relevo general — elegir responsable antes de continuar

## Entrada vigente — 21 de octubre: nuevo compañero para terminar C5-C2

El propietario delega C2 en **otro compañero**, distinto del responsable de OV-1.
Leer primero [relevo completo de C2](RELEVO_C5_C2.md) y después el
[acta C2-D](C5C2D_VALIDACION_LOCAL.md): C2-A/B/C implementadas y validadas
automáticamente; C2-D sigue0/8 bloques humanos, con D8a–e pendientes.
La guía incluye ambos repos, auditoría, Docker, cuentas ficticias/contraseña local,
USB/APK, pruebas, correcciones Flutter/backend/panel, actas y entrega mediante PR.
No cambiar el frente OV-1. Las órdenes inferiores fechadas son antecedentes,
no instrucciones para reiniciar instituciones/reportes/juegos ya cerrados.

Prompt para esta persona:

```text
Te corresponde terminar C5-C2 de SaberPlus en sustitución del propietario;
NO eres el compañero de OV-1. Ten ambos repositorios actualizados y lee
docs/RELEVO_C5_C2.md (backend: backend/docs/RELEVO_C5_C2.md), sus documentos
de arquitectura/estado y el acta C5C2D_VALIDACION_LOCAL.md. Primero audita las
dependencias, estado Git y código/pruebas del módulo, registra lo realmente
revisado y continúa desde el último checkpoint, no desde un chat antiguo.
C2-A/B/C ya están implementadas; faltan C2-D y los fallos que aparezcan.
Prepara una sesión Docker propia, panel real local y Android USB desbloqueado.
Usuarios y forma segura de encontrar la contraseña están en la guía; no subas
secretos ni uses producción. Explica cada paso al compañero humano y pide su
confirmación visual; actualiza ambas actas tras cada prueba. Ejecuta los ocho
bloques, incluidos D8a–e; consigue segundo cliente para Tira online o deja ese
subcaso pendiente, nunca inventes aprobación. Puedes corregir Flutter, API y
panel dentro de C2 con regresiones, sin reconstruir arquitectura ni tocar OV-1.
Trabaja en ramas propias, conserva cambios ajenos y entrega rutas, evidencia,
comentarios de commit y comandos de push. No push/merge/despliegue sin permiso.
Cierra C2 local solo con los criterios de la guía; el resto de C5 sigue abierto.
Al entregar, avisa a Pavel que debe auditar y verificar ambos repositorios,
documentación y evidencias antes de aceptar el cierre y elegir otra etapa.
Incluye commits, pruebas y pendientes; si faltan pruebas, declara entrega parcial.
Espera su decisión y no interfieras con OV-1.
```

## Antecedentes anteriores a este relevo

**19 de octubre, continuación del propietario:** leer [R4](MA1R_R4_VALIDACION_LOCAL.md)
y [checkpoint](MA1R_REPORTES_PREGUNTAS.md).12/12 humanos y45/45 integradas aprobadas;
regresiones backend121/1567 tras fix de concurrencia, Flutter920/13 opt-in omitidas, ADMIN109/build/análisis.
APK reinstalada y remate confirmado por propietario: R4 cerrada localmente.
Integrado en main por PR app #6/API #9 (21757a1/eef0d40), CI backend del PR aprobado.
QA-1 Flutter remoto pendiente. Siguiente bloque recomendado: preparación local C5;
no implementar ni activar storage real sin revisar permisos/alcance. No repetir12 ni preparar APK
otra vez por estas notas. Sesiones anteriores limpiadas, remate en otra temporal:
no asumir servicios activos/credenciales válidas. Sin push/merge/despliegue automático.
OV-1 sigue siendo el frente independiente del compañero. Prompts inferiores históricos.

**17 de octubre, checkpoint que prevalece:** [C4-C10/10 guiones integrados locales
cubiertos](PR_I5_C4_CODIGO.md), Android+19 HTTP/SQL; no10 pruebas solo manuales.
APK corregida instalada, regresión893 aprobadas/13 opt-in omitidas y análisis limpio.
Leer [cierre local consolidado y commits creados](CIERRE_INSTITUCIONES_LOCAL.md):
app6bab6be/API7ba93d7/lockbfce42e integrados a main por PR app #5/API #8.
Merges e679c50/388bb18; CI backend PR/main aprobado y análisis Flutter/102 dirigidas
aprobados. Sin workflow Flutter remoto. Documentación posterior separada en
`docs/estado-post-instituciones`; publicar/revisar mediante PR, no directamente en main.
[Orden posterior](ESTADO_Y_ORDEN_2026_10_17.md): MA-1R/R1 autorizada y
[R2 backend local implementada](MA1R_REPORTES_PREGUNTAS.md),121 suites/1.560 aprobadas;
[R3 app/panel local](MA1R_R3_APP_PANEL.md):32 dirigidas Flutter/109 ADMIN aprobadas.
Sigue R4 PostgreSQL/Nest y después Android; SQL escrito no aplicado, sin despliegue.
No rehacer C3/C4 ni repetir fixtures. Solo si se necesita un nuevo ensayo verificar
sesión/USB/credenciales actuales, nunca reutilizar caducadas. OV-1 del compañero
en curso, sin entrega nueva verificada aquí; no desplegar ni migrar por este prompt.
Entradas y prompts inferiores fechados son antecedentes, no el paso siguiente.

**15 de octubre: propietario en C3C**, no repetir C2C por defecto.
[Checkpoint de solicitudes](PR_I5_C3_SOLICITUDES.md): C3A backend y C3B app
implementadas y probadas automáticamente; faltan integración Flutter/API y Android.
No hacer commit todavía. El compañero mantiene OV-1, no recibe este trabajo.
Los prompts inferiores C2C son históricos: prevalece este checkpoint.
No asumir que servicios/USB siguen activos.

**Actualización del14 de octubre:** C2C validada localmente (6/6 HTTP/SQL y8/8
humanos). Próximo trabajo del propietario: solicitudes estudiantiles/avisos/código
institucional. Leer cierre y observaciones en [acta C2](PR_I5_C2_LOGO.md).
Las instrucciones específicas C2C inferiores se conservan como guion histórico;
no repetirlo por defecto. El compañero mantiene su frente OV-1.

Actualizado: 13 de octubre de 2026. Leer [reparto](TRABAJO_PARALELO.md).
Ambos repositorios públicos según API GitHub hoy; lectura no otorga escritura.
No cambiar visibilidad ni publicar secretos.

## Elegir el prompt correcto

- Propietario: [cierre institucional](CIERRE_INSTITUCIONES_LOCAL.md) y
  [siguiente bloque propuesto](ESTADO_Y_ORDEN_2026_10_17.md); el prompt de pruebas
  institucionales es histórico salvo regresión concreta.
- Compañero: OV-1A/B/C/D, [checkpoint propio](CHECKPOINT_OV1.md) y
  [prompt del compañero](TRABAJO_PARALELO.md#prompt-para-el-compañero).
- El roadmap general se consolida por el propietario al entregar/integrar bloques.
  Cada equipo registra inmediatamente sus pruebas en su checkpoint, no en el ajeno.

## Instrucciones comunes copiables

```text
Continúa SaberPlus sin reconstruirlo. Primero identifica si tu responsable es el
propietario (instituciones) o el compañero (OV-1). Si no está claro, pregunta.
Lee TRABAJO_PARALELO.md y el checkpoint de ese frente; usa su prompt específico.
Verifica rutas, AGENTS aplicables, rama, status/HEAD de ambos repositorios.
Preserva trabajo ajeno. Ramas por frente, no implementar directamente en main.
No reset, force-push, push, merge, despliegue ni cambios de visibilidad automáticos.
Coordina schema.prisma, dependencias, navegación y configuración antes de editarlos.
Inspecciona contrato/código/tests del módulo antes de cambiarlo.
Cada prueba actualiza el acta/checkpoint propio con evidencia real y límites;
el propietario consolida documentación general al entregar/integrar el bloque.
No transformar unitarias en validación física ni ensayo local en despliegue.
No usar cuentas/base de producción; no imprimir ni commitear secretos.
Entrega rutas, archivos, pruebas ejecutadas, pendientes y siguiente acción.
Usa mensajes de commit específicos y comandos de push de la rama, no main.
No iniciar juegos ni repetir baterías cerradas por encontrar órdenes históricas.
```

## Evidencia histórica conservada (no es un prompt ni una orden actual)

Antecedentes (no son el siguiente trabajo):
- PR-I1 integrado (5216383); I2-1/2/3 backend (66b5aa2) y Flutter I2-4 (1921ba9)
  integrados. Son referencias, no commits a los que volver.
- Validación del compañero publicada: 9583d90 y 8bf32aa. Evidencia del día 6:
  PostgreSQL 347/347 y otros 102; Jest 1258; Flutter 694 pass/9 opt-in skip;
  auth/ranking HTTP 6/6, corrección 5/5. No repetir todo por leer una orden vieja.
- Revisión día 7: panel normal 88/88, producción audit 0 tras cb14338;
  lint backend 603 errores/150 avisos. Panel falló antes en otro equipo:
  no se reprodujo aquí, causa no resuelta. Registra entorno al comparar.
- El propietario completó el recorrido Android de rankings; criterios funcionales
  revisados el día 8. Cierre operativo/limpieza y QA-1 siguen pendientes, no repetir
  todo el recorrido ni afirmar validación productiva. Cima/Guardián físicos
  acreditados en sus actas locales; otros juegos/audio e iOS no acreditados.
  Ensayo académico local confirma edición/progreso y versiones
  de preguntas, con historial anterior preservado en PostgreSQL.
- IC-1A Cima: cliente local implementado (modo explícito, confirmación del servidor,
  recuperación, rechazo OFF sin fallback y acceso al ranking). IC-1A2 aprobada
  localmente: Android/API/ledger, una concesión real de 100 XP, recuperación,
  desconexión previa al POST/reintento, OFF y normal sin XP. No se probó pérdida
  del acuse después de guardar. Ocho tests nuevos del control IPC local aprobados.
  El pago de Cima procede de la partida, no del fixture sintético de Trivia.
  IC-1B1 Guardián implementado: recuperación cifrada/pending, modo estricto y
  34 tests dirigidos aprobados. IC-1B2 local acredita victoria/100 XP únicos,
  recuperación/red/reintento/ranking y normal sin XP, derrota +30 por 3 aciertos
  y abandono −10, saldo final 120. IC-1B validada en ese alcance local.
  IC-1C Rescate integrado localmente: 62 tests Flutter/32 backend; HTTP/SQL local
  normal sin evento y victoria competitiva100 única con cuenta zero. Acta IC1_RESCATE.
  Recorrido Android/API/SQL local aprobado el10 de octubre: victoria100 única,
  recuperación/red/reintento, ranking/reapertura, normal sin evento, agotamiento
  2 estrellas/+20 y abandono−10 por intento. Contraste nuevo100→90→80 aprobado.
  Supervisor corregido (JSON parcial no cierra sesión), 12 tests/CI y runtime.
  Otros clientes competitivos aplazados; sin activación remota. Ver checkpoint
  para cierre operativo I2-5/QA-1. Los commits de Rescate se autorizaron el10;
  instituciones posterior ya tiene cierre local. No repetir esas pruebas.
  Propietario ahora pide un commit por juego tras pruebas/documentación; revisar
  cambios acumulados antes de agruparlos. No push ni cambios ajenos automáticos.
- El conflicto editorial EDITOR_STALE se resolvió recargando; incluir contadores
  de uso en la revisión sigue como hallazgo a evaluar, no como defecto corregido.
- No usar fixtures de ranking como prueba de partidas competitivas verificadas.
- No confundir flags apagados por defecto con estado remoto inspeccionado.
