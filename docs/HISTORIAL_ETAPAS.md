# Historial completo de etapas de SaberPlus

Actualizado: 23 de septiembre de 2026.

## Cómo leer este documento

Este es el índice histórico desde la primera entrega hasta la última registrada.
Se apoya en el [roadmap detallado](ROADMAP_MOVIL.md), las guías de cada módulo y
el historial Git de ambos repositorios, incluido al final sin omitir commits.
Una entrega local no demuestra despliegue ni pruebas en celulares. Un commit de
documentación tampoco demuestra por sí solo una implementación del backend.
Los mensajes ambiguos del historial se conservan sin inventarles una etapa.

Para retomar trabajo usar [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md).
Para entender el código usar [ARQUITECTURA_Y_ESTRUCTURA.md](ARQUITECTURA_Y_ESTRUCTURA.md).
Las secciones siguientes agrupan entregas; no renumeran las subetapas originales.

## 1 — Cimientos móviles

Entregado: proyecto Flutter, organización modular, Riverpod, Dio, navegación por
rol, bienvenida, acceso demostrativo, tema y configuración de entornos.
Primer commit móvil: `a1f1b6a`. Se conservaron Android e iOS como plataformas.

## 2 — Autenticación y sesión

Entregado: registro, verificación, login, perfil, almacenamiento seguro,
restauración de sesión, recuperación/cambio de contraseña, cierre de sesión,
adaptación al contrato existente y prueba contra API en ejecución.
Guía: [AUTH_CONTRACT.md](AUTH_CONTRACT.md).
Pendientes de cierre: refresh/rotación, revocación y sesión única en servidor,
consentimiento y enlaces HTTPS definitivos. No confundir la frontera cliente con
esas garantías completas del backend.

## 3 — Diagnóstico y aprendizaje

Entregado: inicio académico, diagnóstico de 15 preguntas, borrador/finalización,
resultados por área, falencias por tema/subtema, árbol académico y lecciones con
Markdown, imágenes, video, actividad y PDF.
Guías: [ACADEMIC_CONTRACT.md](ACADEMIC_CONTRACT.md), [STUDY_CONTRACT.md](STUDY_CONTRACT.md).
La ampliación posterior de evidencia evita llamar falencia a un único error.

## 4 — Práctica y simulacros

Entregado: pregunta/opciones/contexto, práctica protegida por subtema, selección
aleatoria por área/cantidad/dificultad, simulacro por área, tiempos, borradores
cifrados, reanudación, resultado, explicación e historial con filtros.
Guía: [PRACTICE_CONTRACT.md](PRACTICE_CONTRACT.md).
Pendiente: recuperación idempotente completa desde API y pruebas reales integrales.

## 5 — Progreso y funcionamiento local

Entregado: progreso por área, cuaderno de errores, notas/repaso adaptativo,
biblioteca de fórmulas/glosario/estrategia, Drift/SQLite, descargas, espacio,
cola de sincronización segura, preferencias y recordatorios locales.
Guías: [PROGRESS_CONTRACT.md](PROGRESS_CONTRACT.md), [OFFLINE_SYNC.md](OFFLINE_SYNC.md),
[OFFLINE_CONTENT.md](OFFLINE_CONTENT.md), [PREFERENCES_NOTIFICATIONS.md](PREFERENCES_NOTIFICATIONS.md).
No implica que toda operación funcione offline ni que todos los datos se sincronicen.

## 6 — Hábitos, orientación, comunidad y juegos

### Gamificación, certificados y herramientas personales

Entregado por pasos: XP/rachas/logros, certificados iniciales, favoritos,
búsqueda académica, transiciones accesibles, continuar lección, Pomodoro,
flashcards, contador de examen, sonido/vibración de aciertos, niveles de llama,
preguntas difíciles, repaso diario, tema automático y tiempo estudiado.
Los certificados iniciales por logros fueron sustituidos: ahora son solo cinco
de área y uno de curso completo. No volver a habilitar los anteriores.

### Simulacros avanzados y bienestar

Entregado en cliente: 150 preguntas AM/PM, integridad/sesión, descanso opcional de
tres minutos tras actividad prolongada, catálogo histórico por año, contrarreloj,
comparación de resultados y countdown del temario. Los contratos históricos,
historial unificado y vencimiento autoritativo conservan pendientes de servidor.
Guías: [SIMULACRO_150.md](SIMULACRO_150.md), [TIME_TRIALS.md](TIME_TRIALS.md),
[SESSION_SECURITY_WELLBEING.md](SESSION_SECURITY_WELLBEING.md).

### Perfil académico y orientación

Entregado: perfil central, fortalezas/debilidades, objetivo personal, resumen
semanal/comparación mensual, proyección orientativa, carreras/universidades,
becas/oportunidades y comparación nacional. Las fuentes requieren mantenimiento;
no se garantiza admisión ni se presenta la proyección como resultado oficial.
Guías: [ACADEMIC_PROFILE.md](ACADEMIC_PROFILE.md), [OFFICIAL_OPPORTUNITIES.md](OFFICIAL_OPPORTUNITIES.md).

### Juegos e integración 6F/6G

- Trivia Rush: juego local, sonidos, motor autoritativo y cliente remoto (6G-A/B).
- Memoria: parejas de fórmulas/glosario, niveles, pistas y sonidos.
- Fantasma: récord local y luego récord limpio respaldado por servidor (6G-C).
- Tira y afloja: prototipo CPU, arte/animación, motor protegido, Socket.IO y
  cliente multijugador (6F-D-C-A/B/C).
- Ranking global/institucional con alias y privacidad (6G-D).
- Batallas asíncronas con invitación, bloqueo y reporte (6G-E).
- Anuncios informativos, referidos, soporte y calculadora (6G-F).
- Mejora 6F-P: animaciones de juegos/racha y Desafío del Guardián con API,
  cliente y migración local. Falta despliegue/ensayo real de lo pendiente.

Guías: [GAMES_PRODUCTION_CHECKLIST.md](GAMES_PRODUCTION_CHECKLIST.md),
[TRIVIA_RUSH.md](TRIVIA_RUSH.md), [TUG_OF_WAR.md](TUG_OF_WAR.md),
[ASYNC_BATTLES.md](ASYNC_BATTLES.md), [GAME_POLISH_GUARDIAN.md](GAME_POLISH_GUARDIAN.md).
Audios integrados no equivale a audios escuchados correctamente en cada celular:
se mantiene el reporte del usuario de reproducción fallida fuera de Tira y afloja.

## 7A–7E — Profesor e institución

Entregado: cuenta personal docente y vinculación, propiedad/administradores,
invitaciones y transferencia, grupos/códigos temporales, plan gratuito e indicadores,
analítica detallada, alertas y exportaciones por alcance autorizado.
La creación institucional directa fue reemplazada después por aprobación ADMIN.
Guías: [TEACHER_INSTITUTION_FOUNDATION.md](TEACHER_INSTITUTION_FOUNDATION.md),
[INSTITUTION_ADMINISTRATION.md](INSTITUTION_ADMINISTRATION.md), [GROUP_LINKING.md](GROUP_LINKING.md).

## 7F — Infraestructura y administración de contenido

- Supabase: proyecto de desarrollo, usuario Prisma, conexiones y migraciones iniciales.
- Backend separado de Icfes_Vida en `SaberPlus-Backend`.
- Render: instalación reproducible, entorno, HTTPS y despliegue inicial exitoso.
- B3-A: configuración/verificación pública Flutter staging; B3-B integral pendiente.
- C1: jerarquía, estados de contenido, validaciones y borrado protegido.
- C2-A: vista previa Excel/ZIP y detección de duplicados, sin importación masiva final.
- C2-B1: catálogo administrativo por área/tema/subtema.
- C2-B2: evidencia académica acumulada y pantalla por tema/subtema.
- C3-A: acceso ADMIN, catálogo y demo aislada del panel.
- C3-B: editor de lecciones y referencias HTTPS.
- C3-C: editor de preguntas, opciones, casos y explicaciones.
- C3-D1: primer flujo de revisión/publicación de contenido.
- D2-A: retiro de escrituras antiguas y bloqueo compartido.
- D2-B: indexación de huellas y coincidencias del banco antiguo.
- D2-C: reclasificación protegida sin alterar historial.
- D2-D: edición/retiro protegido de CLOZE.
- D2-E: herramientas anteriores integradas en panel/demo.
- D2-F: pruebas PostgreSQL desechable, concurrencia/rollback y borrado de
  temas/subtemas vacíos. Operación del legado y revisión real siguen pendientes.
- D3, C4, C5 y C6: conexión real, sincronización de catálogo, archivos y versiones
  permanecen pendientes; no se dan por terminados por existir demo.

Guías: [ADMIN_PANEL.md](ADMIN_PANEL.md), [LEARNING_EVIDENCE.md](LEARNING_EVIDENCE.md),
[SUPABASE_DEPLOYMENT.md](SUPABASE_DEPLOYMENT.md), [RENDER_STAGING_DEPLOYMENT.md](RENDER_STAGING_DEPLOYMENT.md).

## Auditorías y simplificaciones posteriores

Entregas locales de seguridad, persistencia, sesión y accesibilidad, con informes
de datos/UX. Retiro de ePayco/Wompi manteniendo historial y rutas retiradas.
Documentación de funcionalidades, colaboración y arquitectura.
Guía: [AUDITORIA_PROYECTO_2026-09-09.md](AUDITORIA_PROYECTO_2026-09-09.md).

Panel actual: diseño simplificado usando la web antigua como referencia, guardado
con publicación directa sin envío obligatorio a revisión, editor por bloques,
vista previa y creación de subtema sin salto automático a preguntas. Se conservan
validaciones de permisos, duplicados e historial. Es evolución del panel, no otro
backend. Falta el ensayo real D3 del flujo actual.

## P1–P5 — Cierre y ampliación docente

| Etapa | Entrega | Estado |
| --- | --- | --- |
| P1 | Métricas, textos y navegación docente | Local |
| P2 | Ficha del alumno con evidencia por tema/subtema | Local |
| P3-A | API/persistencia de prioridades docentes | Local |
| P3-B | Pantallas y práctica dirigida del estudiante | Local |
| P4-A | Persistencia Pomodoro y API de tiempo/evolución | Local |
| P4-B | Cola por cuenta, reintentos y evolución móvil | Local |
| P4-C | Solicitud institucional y aprobación/rechazo ADMIN | Local |
| P5 | Ensayo real completo con cuentas, base y teléfonos | Pendiente/pausado |

Los documentos `PROFESOR_P1.md` a `PROFESOR_P4_C.md` conservan sus pruebas y límites.
Las aprobaciones aún no incluyen carga completa de adjuntos privados; coordinar C5.

## Ampliación de Sabi, juegos y aprendizaje

- Logo S+ incorporado a la app.
- Personaje Sabi y dirección artística acordados.
- G-SABI-1B: prototipo de carrera; no es animación final aprobada.
- JN-1A/B/C: Salto a la cima demo, backend y cliente remoto locales.
- JN-2A: Rescate de estrellas demo local; B/C pendientes.
- JN-3: Taller de inventos cancelado, no pendiente.
- JN-4: Escudo del conocimiento aprobado, pendiente de implementar.
- MA-1/2/3: cobertura del banco, mapa y repaso diferido aprobados, pendientes.
- Animaciones profesionales y renovación de Sabi: al final, por decisión del usuario.

Guía: [SABI_Y_JUEGOS_APROBADOS.md](SABI_Y_JUEGOS_APROBADOS.md).

## Certificados definitivos y PR-I — última ampliación

Certificados HTML/PDF locales: cinco áreas y curso, nombre del usuario y validación
del servidor de todas las lecciones publicadas. Falta despliegue/ensayo real.

PR-I1–7 planifican reglas, ranking por juego, premios, perfiles/búsqueda,
instituciones/solicitudes, ranking colectivo y ensayo integral.
**PR-I3A entregada:** catálogo visual de 40 imágenes de cuatro juegos desde perfil
y ranking. No acredita posiciones ni premios obtenidos. **Última decisión: top 50**,
10 diseños por familia, premios anuales acumulables sin reemplazar años anteriores.
Commits móviles: `d391df5` y `40f7d64`.
Guía: [PERFILES_RANKINGS_INSIGNIAS.md](PERFILES_RANKINGS_INSIGNIAS.md).

## Plataforma web temporal

Se regeneró Flutter web para una demostración al profesor y compiló en modo debug.
Después el usuario pidió retirarla: `web/` se quitó del proyecto con respaldo
temporal fuera del repositorio. Android/iOS continúan; **el panel web administrativo
de `SaberPlus-Backend/admin` no se eliminó**. La demostración no cierra la beta móvil.

## Etapas futuras 8 y 9

Nueva decisión de diseño: **UI-F**, pendiente. Renovar la app con identidad azul
SaberPlus, botones y componentes cuidados, conservando claro/oscuro y accesibilidad.
Se hará tras las funciones, coordinada con las animaciones finales y antes de las
pruebas integrales/beta 8G y publicación. No se cambiaron colores con esta decisión.

8A/B: Billing y derechos; 8C/D: anuncios y recompensas reales; 8E: privacidad y
licencias; 8F: seguridad/rendimiento; 8G: pruebas/beta; 8H: entrega iOS;
8I: publicación Google Play; 9A: operación posterior.
No están completadas por haber preparado pantallas o contratos.

## Registro Git verificable

Los anexos siguientes conservan todos los commits alcanzables desde HEAD al crear
este documento, en orden inverso al habitual (inicio → actualidad). Son una
fotografía, no una lista que se actualice sola. Incluyen documentación/correcciones,
no solo etapas. Para el historial posterior ejecutar en cada repositorio:

```powershell
git log --reverse --oneline
```

No se asignan fechas de finalización ni se deduce despliegue a partir de un mensaje.


### Anexo A — repositorio móvil

```text
a1f1b6a "feat: implementar base Flutter y navegación inicial de SaberPlus"
8b1906e "feat: implementar autenticacion movil y manejo seguro de sesion"
cd580ad "feat: integrar autenticacion Flutter con API existente"
a58c985  "feat: validar autenticacion movil contra API real"
71e67d6 "feat: conectar inicio academico y diagnostico real"
641fefb "feat: completar diagnostico movil y falencias por tema"
17dce9b "feat: implementar arbol academico y lecciones moviles"
0909c8c "chore: limitar proyecto a android e ios"
ccaa55e feat: implementar practica protegida por subtema
5cd4fb8 feat: agregar preguntas aleatorias y reanudacion de intentos
685b4a8 feat: completar simulacros e historial movil
7c41efa feat: implementar panel de progreso y cuaderno de errores
63ec6f6 feat: implementar repaso adaptativo
6ce4637 feat: agregar biblioteca academica sin conexion
351438a feat: agregar almacenamiento y descargas offline
2b4986b feat: agregar sincronizacion offline segura
ddd9dec feat: agregar preferencias y recordatorios locales
769e362 feat: agregar gamificacion xp y rachas
ea7b7d7 feat: agregar certificados de logros
d774c58 feat: agregar favoritos de lecciones
7927ebd feat: agregar busqueda academica
f68543b feat: agregar transiciones accesibles
24e9a56 feat: agregar continuar donde quedaste
4b131f9 feat: agregar temporizador pomodoro
c5af75e feat: agregar flashcards academicas
d44204f feat: agregar contador global del examen
6edaac0 feat: agregar sonido y vibracion para rachas de aciertos
ad472f3 feat: agregar niveles y vista previa de rachas
e93995c feat: agregar preguntas difíciles
8b54250 feat: agregar repaso de errores del dia
e2f7e7b feat: agregar modo oscuro automatico
355ad77 feat: agregar tiempo total estudiado
3731a26 feat: agregar simulacro de 150 preguntas AM PM
0f02cbe feat: agregar seguridad de sesion y descansos saludables
20f66a6 feat: agregar catalogo de simulacros por año
51ce94c feat: agregar pruebas contrarreloj
6730de0 feat: agregar comparacion entre simulacros
f54ef55 feat: agregar countdown del temario por materia
f45dcb5 feat: agregar perfil academico central
6c53cd0 feat: agregar fortalezas y objetivo academico
b610b98 feat: agregar resumen semanal y comparativo mensual
fa254a4 feat: agregar proyeccion orientativa de puntaje
3bacd1e feat: agregar orientacion de carreras y universidades
aa6a521 feat: agregar becas y oportunidades oficiales
71f3112 feat: agregar referencia nacional y modelo de negocio
7d19d21 feat: agregar Trivia Rush
ca33a0d feat: agregar juego de memoria academica
7939606 feat: agregar duelo fantasma y checklist de juegos
02775ab feat: integrar sonidos en los juegos
58fe64d feat: agregar maqueta de tira y afloja
3f92688 feat: agregar animaciones detalladas a tira y afloja
e327475 feat: agregar motor autoritativo de tira y afloja
5cf4648 docs: definir contrato multijugador de tira y afloja
83e5259 docs: completar transporte en tiempo real de tira y afloja
254a415 feat: conectar tira y afloja multijugador
095bf79 feat: conectar trivia rush con el backend
b085fee feat: conectar duelo fantasma con record en la nube
144f4c6 feat: agregar ranking privado en flutter
7cd23a7 feat: agregar batallas asincronas seguras
613d93d feat: agregar anuncios referidos soporte y calculadora
eca0ebd feat: agregar vinculacion institucional de profesores
6ff90b4 feat: agregar panel de administracion institucional
f65b0c3 feat: agregar grupos y codigos temporales
fa4eada hh
92f7a89 feat: agregar plan gratuito e indicadores docentes
c53f022 feat: agregar analitica institucional detallada
38debd0 docs: documentar despliegue con Supabase
d55211e chore: preparar conexion HTTPS de staging
99f393a se quitaron unas cosas
bd7d2a5 docs: definir administracion segura de contenido
abbc122 docs: documentar importacion y deteccion de duplicados
7beab35 docs: registrar backend oficial de SaberPlus
c097d5c mejoras de los juegos
d2abd31 feat: configurar y verificar conexion Flutter staging
0c6930f docs: registrar etapa 7F-C2-B1 y siguientes entregas
d0c527f feat: mostrar diagnostico por temas con evidencia suficiente
6ed426f docs: registrar panel editorial y etapas 7F-C3
a637506 docs: completar etapa 7F-C3-B de lecciones
b93d221 docs: completar etapa 7F-C3-C de preguntas y casos
1bba19b docs: registrar C3-D1 y consolidar etapas pendientes
fc53afe docs: conciliar etapas anteriores y completar pendientes
31a99e0 docs: registrar avance C3-D2-A y pendientes editoriales
33d97db docs: registrar indexacion del legado C3-D2-B
db18b21 docs: registrar reclasificacion segura C3-D2-C
bce6397 test: verificar contrato cloze y registrar etapa D2-D
855880e docs: registrar panel editorial D2-E y pendientes
44a20b2 docs: registrar verificacion postgres D2-F y pendientes
d33de77 docs: registrar eliminacion segura de borradores
e45193e fix: reforzar seguridad persistencia y accesibilidad movil
31f5a47 docs: registrar retiro de pasarelas heredadas
72df7f9 explicacion de la clase
fc6e223 docs: documentar reanudacion de conexion editorial D3
c96d850 feat: mejorar seguimiento y navegacion docente P1
2898853 feat: agregar ficha docente por temas y subtemas P2
619d555 docs: registrar prioridades docentes P3-A y continuacion P3-B
d7ac04d feat: integrar prioridades del profesor y estudiante P3-B
bb07068 docs: registrar entrega P4-A y siguiente integracion Flutter
f5df67c feat: sincronizar Pomodoro y mostrar evolucion docente P4-B
76ade27 16/09
0da8996 style: colocar logo SaberPlus como icono de la app
7c0ff4f docs: planear aprobacion de instituciones por ADMIN
40011d4 feat: solicitar aprobacion institucional desde Flutter
f15c334 docs: registrar personaje Sabi y nuevos juegos aprobados
6f9e70b docs: planear animaciones de Sabi y renovar duelo fantasma
12b6723 feat: agregar prototipo de carrera de Sabi
5c0d877 feat: agregar Salto a la cima en modo demo
422f55d docs: registrar backend de Salto a la cima y siguiente etapa
9753942 feat: conectar Salto a la cima con recuperacion segura
359d921 feat: agregar demo de Rescate de estrellas
d0ee46b docs: organizar certificados y audios para el equipo
ef0441f feat: integrar seis certificados de areas y curso en Flutter
b872f44 docs: retirar Taller de inventos del roadmap
b0ab713 docs: documentar arquitectura y estructura de SaberPlus
d391df5 feat: integrar catalogo visual de insignias de Sabi
40f7d64 feat: limitar insignias y plan de rankings al top 50
```

### Anexo B — repositorio backend/panel

```text
82a2ad5 feat: crear backend oficial de SaberPlus
2b838ca fix: validar migraciones actuales de staging
5e55b79 fix: hacer reproducible la instalacion en Render
3cea360 feat: organizar catalogo academico por area tema y subtema
5bc001b feat: diagnosticar temas con evidencia acumulada
7365320 feat: crear panel editorial con acceso y catalogo privado
b3d561f feat: agregar editor seguro de lecciones en borrador
dc0cd4b feat: agregar editor de preguntas y casos con control de duplicados
13422c9 feat: agregar revision editorial y publicacion controlada
fc7317c fix: cerrar escrituras editoriales heredadas y unificar bloqueos
3e8bb82 feat: indexar preguntas heredadas por lotes con revision
a5f7cc7 feat: reclasificar preguntas sin uso con revision protegida
8937683 feat: agregar editor y revision protegida de cloze
51e9b06 feat: integrar cloze y herramientas de legado en el panel
122a0c5 test: verificar concurrencia editorial en postgres aislado
916ad61 fix: corregir conexion y mensajes de acceso del panel
b9c8b43 feat: eliminar temas y subtemas vacios con protecciones
f2a5f00 fix: auditar seguridad del backend y proteger el panel editorial
4968c30 refactor: retirar epayco y referencias operativas a wompi
9123ce6 fix: corregir metricas publicadas del profesor P1
641dd94 feat: agregar evidencia individual protegida para profesores P2
ee484e1 feat: guardar prioridades docentes y cumplimiento seguro P3-A
56e2471 feat: iniciar practica dirigida de prioridades docentes P3-B
7dd9cac feat: preparar API de tiempo estudiado y evolucion P4-A
828a8ee fix: completar modelo PomodoroRegistrado de P4-A
fc7f1b0 feat: aprobar instituciones desde el panel admin
b826967 feat: incorporar Guardian, Salto a la cima y privacidad institucional
2c24723 feat: crear plantilla de certificados por area y curso
de66bf7 fix: excluir scripts de la compilacion para conservar dist/main.js
5f7612c feat: agregar API de certificados por area y curso completo
7813d88 feat: emitir seis certificados de areas y curso con HTML
78b4efa Merge pull request #1 from Pavel2020123/feat/certificados-descarga
59b0d45 Merge pull request #2 from Pavel2020123/feat/certificados-curso
a36c463 fix: unificar certificados de areas y curso
24d99eb feat: simplificar panel y publicar contenido al guardar
248ee06 feat: simplificar panel administrativo y agregar editor de contenido por bloques
```
