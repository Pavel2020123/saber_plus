# Prompt para continuar SaberPlus con otro chat

Actualizado: 9 de octubre de 2026. Copiar el bloque completo; adaptar rutas.
Fuente única del orden: [ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md).
Evidencia y límites: [conciliación](CONCILIACION_2026_10_07.md).
Se necesitan los dos repositorios y permisos de acceso si corresponde; no cambiar
su visibilidad para usar este prompt ni compartir contraseñas.

Para continuar **pruebas Android/API/Docker**, entregar además
[guía y prompt operativo](RELEVO_PRUEBAS_LOCALES.md). El siguiente paso exacto
se lee del [checkpoint vivo](ETAPAS_PENDIENTES.md#checkpoint-de-relevo-de-pruebas),
que debe actualizarse después de cada prueba, incluso si se interrumpe el chat.

```text
Vas a continuar SaberPlus, no crear otra app ni reescribir el proyecto.

Repositorios independientes en el PC del propietario:
- Flutter: C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus
- NestJS/Prisma y ADMIN: C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend
En otro PC confirma rutas; no trabajes en Icfes_Vida ni inventes un backend.

Antes de editar:
1. Lee AGENTS.md aplicables; verifica git status, rama, HEAD y diferencias en
   ambos repositorios. Preserva cambios ajenos; no reset ni force-push.
2. Lee README, docs/ALCANCE_V1_NOVIEMBRE_2026, docs/ETAPAS_PENDIENTES (estado superior y tabla activa),
   checkpoint de relevo, RELEVO_PRUEBAS_LOCALES, IC1_CIMA, IC1_GUARDIAN,
   I2_5_RECORRIDO_ANDROID, ENSAYO_ACADEMICO_LOCAL,
   CONCILIACION_2026_10_07, RELEVO_EQUIPO, INDICE_DOCUMENTACION y arquitectura.
   Usa HISTORIAL_ETAPAS como historia, no como instrucciones actuales.
   En backend lee README, backend/docs/README, PR_I2_RANKINGS, admin/README,
   contratos afectados, package.json y migraciones.
3. Audita el flujo concreto UI → controlador → repositorio → API → permisos →
   servicio → Prisma → respuesta. Leer documentación no equivale a auditar todo.
4. Trabaja en main por decisión del propietario, coordinando archivos con el
   equipo. Rama/PR solo si se acuerda. No commit/push/merge automático.

Estado:
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
  para cierre operativo/commits y seguir con instituciones, no repetir pruebas.
  Propietario ahora pide un commit por juego tras pruebas/documentación; revisar
  cambios acumulados antes de agruparlos. No push ni cambios ajenos automáticos.
- El conflicto editorial EDITOR_STALE se resolvió recargando; incluir contadores
  de uso en la revisión sigue como hallazgo a evaluar, no como defecto corregido.
- No usar fixtures de ranking como prueba de partidas competitivas verificadas.
- No confundir flags apagados por defecto con estado remoto inspeccionado.

Ruta:
IC-1C Rescate → instituciones PR-I5/P4-C/PR-I5-T → académico/profesor/panel →
insignias/perfiles → ranking institucional/ensayo social → OV-1 → cierre funcional
y comercial → UI-F → validación/sustentación → lanzamiento/operación.
Solo competición Cima/Guardián/Rescate para V1. Trivia/Duelo/Tira/IC-2/IC-3
competitivos después; preservar código y modos normales. No seguir con Trivia
al cerrar Rescate. No aplazar OV-1, perfiles ni otras funciones sin nueva decisión.
Meta académica 15 de noviembre: no garantiza cierre ni publicación en Play.
QA-1 (CI Flutter/deuda) y DOC-1 (higiene/acceso) son entregas de apoyo.
IC son integraciones locales, no activación productiva. PR-I3 puede prepararse
contra contratos, pero premios reales exigen integración validada por juego.
C5 antes de fotos persistentes. P5 → D3 solo al autorizarse.
Territorio PR-I5-T/6-T y orientación OV-1 siguen planificados.
UI-F azul/Sabi al final de funciones/integraciones, antes de beta y tienda.

Conservar:
- Ocho juegos, 90 imágenes: ocho familias de juego y una institucional.
  Taller de inventos y Escudo retirados; no reconstruirlos.
- TOP 50. Puestos 1–5 y rangos 6–10, 11–20, 21–30, 31–40, 41–50.
  Todas las insignias ganadas por juego/año; años anteriores permanecen.
  Arte integrado no es premio concedido.
- Reglas competitivas aprobadas: no cambiar fórmulas por cerrar una integración.
  Memoria/Batallas NO_DISPONIBLE hasta sus entregas. XP autoritativo en servidor.
- Perfil sobrio, alias, búsqueda y privacidad. No exponer correos, falencias
  ni alumnos privados. Profesor no jugador.
- Institución requiere ADMIN P4-C. Solicitud/código institucional no son el
  código de grupo actual. No cambiar permisos silenciosamente.
- Seis certificados: cinco áreas + curso; todas las lecciones publicadas,
  área vacía no certifica. Nombre registrado. HTML/PDF ya existe.
- ADMIN: área → tema → subtema → contenido/preguntas; guardar válido publica
  directamente. Conservar duplicados, versiones, concurrencia e historial.
  No imponer Excel ni revisión editorial obligatoria.
- MA-2/3 locales no se rehacen; faltan ensayos reales. MA-1 conserva reportes pendientes.
- Estudio estudiantil gratuito; pago quita anuncios y añade cosméticos.
  Billing/Ads pendientes; no Wompi/ePayco, chat ni tutores.
- Android/iOS conservados; lanzamiento comercial inicial solo Google Play.

Entrega:
- Un alcance acotado con pruebas de regresión. No cambiar servicios remotos,
  aplicar migraciones reales, usar secretos ni activar pagos/anuncios/competición.
- No repetir pruebas pesadas sin necesidad y sin entorno seguro disponible.
  No sustituir una prueba local por Supabase. Explicar qué sí se ejecutó.
- npm run lint puede modificar código: para diagnóstico usar ESLint sin --fix.
  No ocultar fallos ni omisiones para conseguir checks verdes.
- Actualizar estado superior del roadmap, accesos README/relevo e historial;
  preservar informes originales. No dejar dos rutas vigentes.
- Después de CADA prueba, actualizar acta del juego y checkpoint vivo con resultado
  humano/HTTP/SQL por separado, límites y siguiente acción. Docker local, USB de
  datos, depuración/autorización y pantalla encendida según RELEVO_PRUEBAS_LOCALES.
  Unidades no requieren contraseña; integración usa archivo ficticio privado nuevo,
  jamás credenciales de otro PC ni ese archivo en APK. Nueva base cambia JWT/login.
- Entregar etapa, cambios, validaciones y pendientes. Por cada repo afectado,
  dar ruta real, git add de archivos precisos, git diff --cached y mensaje de
  commit. GitHub visibilidad/protección no verificadas: no asumirlas ni cambiarlas.

Empieza por comprobar el checkpoint VIGENTE del roadmap; al escribir este prompt
era IC-1C Rescate, pero respeta avances posteriores registrados. Usa su contrato existente.
Consulta IC1_GUARDIAN para lo ya validado; conserva
los pendientes operativos de I2-5; no los ocultes al avanzar. En el PC del
propietario la API/panel de ensayo solo duran dos horas: verifica disponibilidad
y propiedad antes de usar o cerrar esos recursos.
No intentes ejecutar todo el roadmap ni publicar automáticamente.
```
