# Prompt para continuar SaberPlus con otro chat

Actualizado: 5 de octubre de 2026, tras recepción de PR-I2 hasta I2-4.
Copiar el bloque siguiente al asistente que tenga acceso local a **ambos repositorios**.
Cambiar las rutas de ejemplo por las del computador del compañero. Este prompt
no habilita despliegues ni hace falta compartir contraseñas. Dar acceso GitHub
privado a cada compañero; no volver públicos los repositorios para usarlo.

```text
Vas a continuar SaberPlus, no crear otra app ni reescribir el proyecto.
Trabajo en estos dos repositorios independientes:
- Flutter Android/iOS: C:\Proyectos\saber_plus
- API NestJS/Prisma y panel web: C:\Proyectos\SaberPlus-Backend
Confirma las rutas reales antes de ejecutar comandos. Si falta el backend o no
tienes acceso, avisa; no inventes endpoints ni trabajes en Icfes_Vida.

Antes de editar:
1. Lee AGENTS.md si existe. Revisa git status, rama, HEAD y diferencias locales
   en ambos repositorios. Conserva cambios ajenos; no reset, force push ni borrados.
2. Lee README.md y docs/RELEVO_EQUIPO.md. La fuente del orden actual es la sección
   superior “Estado vigente” de docs/ETAPAS_PENDIENTES.md. Usa
   docs/INDICE_DOCUMENTACION.md para localizar contratos. Lee arquitectura,
   HISTORIAL_ETAPAS, PERFILES_RANKINGS_INSIGNIAS, INSIGNIAS_Y_JUEGOS_VIGENTES,
   MAPA_APRENDIZAJE y REPASO_DIFERIDO. En backend lee sus README, admin/README,
   package.json, módulos relevantes y esquema/migraciones antes de proponer cambios.
3. Audita el flujo de la entrega (UI → proveedor/controlador → repositorio → API
   → autorización → servicio → Prisma → respuesta/caché), busca pruebas existentes
   y registra una línea base. Distingue demo, código local, despliegue y prueba real.
   Una lectura de documentos no es una auditoría completa de todo el código.

Punto de partida verificado: Flutter 1921ba9 (PR #3) y backend 66b5aa2 (PR #6)
fusionados; pueden existir commits posteriores. No volver a esos hashes ni asumir
despliegue. MA-2A/B/C y MA-3A/B/C locales no se rehacen. PR-I1 integrado por
5216383; I2-1/2/3 y la consulta Flutter I2-4 están implementados. Sigue I2-5.
MA-1 mantiene reportes académicos y ensayo real pendientes.

I2-5: validar app/API/PostgreSQL juntos en entorno local aislado. Leer también
backend/docs/PR_I2_RANKINGS.md y el runner PostgreSQL antes de usarlo. Probar sesión
real, TOP 50, puesto propio fuera del TOP, vacío, no disponible, correcciones de
balances, errores de acceso, privacidad y ranking legacy. Ejecutar regresión global
Flutter/backend y PostgreSQL completo; prueba física aparte. Si falta Docker o el
entorno seguro, documentar el límite, no sustituirlo por Supabase ni inventar datos.
No declarar cierre por pruebas con mocks ni activar flags productivos.

No reabrir reglas aprobadas: Trivia usa resultado definitivo para combo; Duelo solo
compara puntuación (empate por igualdad, sin fantasma solo XP base); Tira conserva
precedencia de resultado normal/plazo global/gracia, UNKNOWN no equivale a abandono
y gracias simultáneas cancelan sin XP/penalización. Memoria/Batallas NO_DISPONIBLE
no son un defecto de I2-4 ni su implementación pertenece a PR-I2. La conexión de
admisión/presencia de clientes de juegos requiere alcance propio antes de activar
competición; consultar ranking no demuestra que las partidas ya generen ese XP.

Acuerdos que debes conservar:
- Ocho juegos vigentes y 90 imágenes: consulta el inventario. Taller de inventos
  y Escudo del conocimiento están cancelados/retirados; no los reconstruyas.
- Top 50 por juego. Puestos 1–5 individuales; rangos 6–10, 11–20, 21–30, 31–40,
  41–50. Mostrar TODAS las insignias ganadas por juego/año, nunca máximo tres.
  Mismo arte con año dinámico; una insignia anual obtenida no desaparece en el
  año siguiente. El catálogo visual PR-I3A no equivale a premios concedidos.
- Perfil sobrio, alias/identidad pública y búsqueda respetando visibilidad.
  No publicar automáticamente nombres privados, correos, falencias ni alumnos
  de una institución. Profesor no participa como jugador.
- Instituciones requieren aprobación ADMIN P4-C. Reutilizar roles/grupos actuales.
  Las futuras solicitudes de estudiantes y el código institucional no son los
  códigos de grupo existentes; no cambiar permisos silenciosamente.
- Solo seis certificados: cinco áreas y uno por las cinco. Todas las lecciones
  publicadas del área; área vacía no concede certificado. Nombre registrado.
  Ya hay HTML/PDF integrado: revisar/probar, no crear otro sistema por logros.
- Panel sencillo área → tema → subtema → contenido/preguntas. Guardar válido
  publica directamente con permisos; conservar duplicados, concurrencia y uso
  histórico. No añadir revisión editorial obligatoria ni exigir Excel.
- Estudio estudiantil gratuito; pago elimina anuncios y añade cosméticos.
  Google Play Billing pendiente; no ePayco/Wompi, tutores ni chat.
- Fotos persistentes dependen de C5. Acabado azul S+, botones y animaciones
  profesionales de Sabi al final, antes de 8G y publicación. No hacerlo ahora.
- P5/D3, Render/Supabase y operaciones reales siguen pausadas. No migrar,
  desplegar, crear cuentas reales ni activar pagos/anuncios sin autorización.
  Android e iOS se conservan; publicación comercial inicial solo Google Play.

Forma de trabajo:
- Coordina responsable y archivos con el equipo; una rama por entrega y por repo,
  no main. Si hay cambios locales, consérvalos antes de cambiar de rama/actualizar.
- Una entrega acotada por vez; contratos antes de UI, permisos siempre en servidor,
  reintentos idempotentes, sin fallback demo silencioso. No ampliar el alcance.
- Usa pruebas locales y, cuando corresponda, PostgreSQL temporal según el runner
  documentado; jamás sustituyas su conexión por Supabase. No pidas secretos.
- Corrige fallos relacionados y añade regresión; registra fallos previos y
  limitaciones. No afirmes pruebas en iOS/Android físicos si no se hicieron.
- Actualiza README, ruta de ETAPAS_PENDIENTES, RELEVO_EQUIPO, HISTORIAL_ETAPAS,
  contrato de la entrega y este prompt si cambió el punto de reanudación.
- Al finalizar indica etapa/alcance, archivos, pruebas/resultados, qué no está
  desplegado, decisiones pendientes y siguiente etapa. Entrega por cada repo
  afectado la ruta real y comandos git add con archivos precisos, git diff --cached
  y git commit con mensaje. No hagas commit/push/merge automáticamente.

Empieza por informar el estado encontrado y los requisitos locales de I2-5. No intentes
resolver todas las etapas en una sola entrega.
```

## Entrega al compañero

Publicar primero los commits documentales y comprobar que el compañero puede
descargar los dos repositorios. Para código local no necesita claves de Supabase.
La demo del panel se inicia con `npm run demo` desde `SaberPlus-Backend/admin`;
sus datos no llegan a la base real. Las instrucciones detalladas de instalación,
ramas, pruebas y cierre están en RELEVO_EQUIPO.
