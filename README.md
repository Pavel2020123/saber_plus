# SaberPlus

Aplicación móvil de preparación para las pruebas Saber 11, con estudio por áreas,
práctica, seguimiento del aprendizaje y juegos educativos. Incluye herramientas
para profesores e instituciones y un panel web para administrar contenido.

**Última revisión documental: 21 de octubre de 2026.**
Este README resume el estado de la copia local revisada; no certifica despliegue
productivo ni vuelve a ejecutar las pruebas de las actas.

## Estado actual y siguiente paso

**Nuevo compañero de C2 (no OV-1):** empezar por
[relevo operativo completo](docs/RELEVO_C5_C2.md) y
[acta C2-D](docs/C5C2D_VALIDACION_LOCAL.md). Incluye arranque de ambos repos,
cuentas/clave temporal, Docker/USB, auditoría y pruebas pendientes paso a paso.
Puede corregir Flutter/API/panel de C2; quedan0/8 bloques humanos y D8a–e.

El propietario trabaja en **C5 — archivos y recursos** desde la rama
`feat/c5-archivos-base`. La entrega funcional A/B/C1 quedó guardada en los commits
app `af73039` y backend `0bfaaba`; no está integrada en `main`. El push posterior
app `c69a5e9` y backend `e1c4d18` ya publicó esa entrega y C2-A/B en la rama.
C2-C está validada automáticamente, todavía sin commit/push. No hay merge ni
despliegue. OV-1 sigue en el frente del compañero.

**C5-C1 completada localmente: cinco de cinco comprobaciones Android aprobadas.**
Ya avanzó [C5-C2, imágenes en opciones](docs/C5C2_OPCIONES.md): base, panel y
consumidores C2-A/B/C validados automáticamente. Sigue C2-D Android, sin
confirmaciones humanas todavía. Carga apagada por defecto; opt-in solo en la
sesión desechable de ensayo. No está terminada toda C5.
Consultar el [guion y checkpoint C5-C1](docs/C5C_FLUTTER.md); no asumir que los
servicios o las credenciales de una sesión anterior siguen activos.

| Bloque | Qué está hecho | Qué falta / límite |
| --- | --- | --- |
| Instituciones PR-I5 | Directorio, departamento/municipio, aprobación, presentación, logo, solicitudes de estudiantes y código privado; cierre técnico local e integración en `main`. | Despliegue y validación productiva, observaciones del acta y ranking institucional separado. [Cierre](docs/CIERRE_INSTITUCIONES_LOCAL.md). |
| Cobertura y reportes MA-1/MA-1R | Cobertura del banco, formulario, Mis reportes y gestión ADMIN; R1–R4 validadas localmente e integradas en `main`. | Operación real y ensayo autorizado de staging. Ocultar/Deshacer es una propuesta separada, no está implementada por cerrar R4. [Acta](docs/MA1R_R4_VALIDACION_LOCAL.md). |
| C5-A y C5-B | Base de imágenes editoriales privadas, carga desde el panel y asociación segura a preguntas, casos y lecciones; pruebas locales aprobadas. | Proveedor persistente y operación externa no configurados por esta entrega. [Contrato](docs/C5_ARCHIVOS.md) y [panel](docs/C5B_PANEL.md). |
| C5-C1 / C2 | C1: **5/5 Android aprobadas** el21. C2-A/B/C: base, panel y consumidores;44/44 PostgreSQL/HTTP,128 suites/1.675 backend y969 Flutter aprobadas/16 omitidas. | C2-D Android pendiente; carga por opción apagada por defecto. PDF/offline, autorización histórica, fotos/evidencias y C5-D pendientes. [C1](docs/C5C_FLUTTER.md), [C2-C](docs/C5C2C_CONSUMIDORES.md). |
| Cima, Guardián y Rescate | Bloque competitivo inicial validado localmente en Android/API/SQL según sus actas. | Activación productiva y cierres operativos separados; no repetir su implementación. [Cima](docs/IC1_CIMA.md), [Guardián](docs/IC1_GUARDIAN.md), [Rescate](docs/IC1_RESCATE.md). |
| Mapa y repaso diferido MA-2/MA-3 | API, persistencia, panel/agenda y consumidores Flutter implementados localmente. | Ensayos integrados y físicos pendientes según cada contrato. [Mapa](docs/MAPA_APRENDIZAJE.md), [repaso](docs/REPASO_DIFERIDO.md). |
| Certificados | Seis tipos con implementación local HTML/PDF: cinco áreas y curso completo. | Prueba real, nombres largos y áreas incompletas/vacías. No hay certificados por juego o logro. [Guía](docs/GUIA_TRABAJO_COMPANEROS.md). |
| Insignias y perfiles | Catálogo visual de 90 imágenes, top hasta el puesto 50. | Concesión verificada, colección anual permanente, búsqueda y perfiles mejorados. Tener el diseño no equivale a haber ganado una insignia. [Plan](docs/PERFILES_RANKINGS_INSIGNIAS.md). |
| OV-1 | Frente asignado al compañero; existe orientación previa en la app. | La nueva entrega del cuestionario por intereses no está verificada en este clon. No confundir la orientación existente con OV-1 terminado. [Checkpoint](docs/CHECKPOINT_OV1.md). |

**Implementado, validado localmente, integrado en `main` y desplegado son estados
distintos.** En esta revisión se comprobó que el `main` local contiene los merges
de instituciones (`e679c50`) y reportes (`21757a1`); no se consultó ni modificó
GitHub para afirmar un estado remoto nuevo.

El inventario completo y sus dependencias están en
[ETAPAS_PENDIENTES](docs/ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
El checkpoint C5-C2 concreta la continuación actual dentro de C5; C1 conserva su acta.

## Funcionalidades y alcance

- **Aprender:** cinco áreas, temas/subtemas, lecciones, recursos, mapa de aprendizaje y progreso.
- **Practicar:** diagnóstico, preguntas por subtema, simulacros, revisión de respuestas y reportes de contenido.
- **Repasar y organizarse:** flashcards, favoritos, preguntas difíciles, cuaderno de errores, repaso diferido, Pomodoro y tiempo de estudio.
- **Jugar:** Trivia Rush, Duelo fantasma, Salto a la cima, Tira y afloja, Guardián, Memoria, Batallas y Rescate de estrellas.
- **Profesor e instituciones:** roles, grupos, prioridades docentes, informes y flujos institucionales con permisos.
- **Administración:** área → tema → subtema → lección/preguntas; el guardado autorizado publica directamente, sin enviar a revisión obligatoria. El panel conserva validaciones, concurrencia y protección del historial.
- **Motivación:** XP, rachas, ranking y certificados, con límites y pendientes propios; el modo demo no acredita resultados reales.

Es un inventario funcional, **no una declaración de que todo está listo para producción**.
Para alcance y limitaciones, consultar
[funcionalidades para el equipo](docs/FUNCIONALIDADES_PARA_EL_EQUIPO.md)
y [alcance V1](docs/ALCANCE_V1_NOVIEMBRE_2026.md).

Se mantienen ocho juegos, pero la competición inicial V1 se concentra en
**Cima, Guardián y Rescate**. Las integraciones competitivas restantes están
aplazadas, sin borrar sus modos normales. Taller de inventos y Escudo del
conocimiento están cancelados; no son próximas tareas.
Los [90 diseños de insignias](docs/INSIGNIAS_Y_JUEGOS_VIGENTES.md) corresponden
a los ocho juegos y una colección institucional, no a nueve juegos.

## Arquitectura y repositorios

| Componente | Organización y tecnologías | Ubicación |
| --- | --- | --- |
| App móvil | Flutter/Dart; funcionalidades con presentación, dominio y datos; Riverpod, Dio y GoRouter. | Este repositorio, `lib/`. |
| API | Monolito modular NestJS sobre Express, TypeScript ejecutado en Node.js; acceso a PostgreSQL mediante Prisma. | [SaberPlus-Backend](https://github.com/Pavel2020123/SaberPlus-Backend), carpeta `backend/`. |
| Panel ADMIN | HTML, CSS y módulos JavaScript; servidor Node.js. No es una app Next.js. | Carpeta `admin/` del repositorio backend. |
| Datos del dispositivo | Drift/SQLite, almacenamiento seguro y preferencias según el dato. | Implementaciones en `lib/core/` y cada funcionalidad. |

La app está inspirada en Clean Architecture, **no es Clean Architecture estricta**;
el backend no se presenta como microservicios. La app consulta la API y no se
conecta directamente a PostgreSQL ni incorpora contraseñas de base de datos.

```text
lib/
  core/       Configuración, red, seguridad, persistencia y componentes comunes
  features/   Funcionalidades y sus capas
config/       Perfiles públicos de entorno, sin contraseñas
test/         Pruebas Dart/Flutter; algunas integraciones son opt-in
tool/         Herramientas de verificación
docs/         Contratos, actas, arquitectura, etapas e historial
```

Ver [arquitectura y estructura](docs/ARQUITECTURA_Y_ESTRUCTURA.md)
para una explicación con ejemplos de código.

## Ejecutar la app

### Demostración, sin backend

Se necesita Flutter compatible con el SDK Dart declarado en
[pubspec.yaml](pubspec.yaml), Android SDK y un dispositivo o emulador configurado.
Desde la raíz `saber_plus`:

```powershell
flutter pub get
flutter devices
flutter run --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=true
```

No se necesita Docker para esta demostración. No introducir credenciales reales
en modo demo: no prueba publicación, membresías, compras ni persistencia de la API.
El arranque sin defines también habilita demo según la configuración actual.

### API local y celular Android por USB

Primero preparar el backend y PostgreSQL del entorno de ensayo siguiendo
[el acta C5-C1](docs/C5C_FLUTTER.md#entorno-local-y-reproducción).
Se necesitan ambos repositorios en versiones compatibles; `flutter run` no
levanta la API ni la base de datos.

Para el ejecutor local que sirve la API en `127.0.0.1:43187`:

```powershell
adb reverse tcp:43187 tcp:43187
flutter run --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:43187 --dart-define=CONTENT_BASE_URL=http://127.0.0.1:43187
```

Mantener el celular autorizado para depuración USB y desbloqueado al instalar.
`adb reverse` conecta el loopback del celular con ese puerto del PC; no sirve
si la API está detenida. Las cuentas temporales y sus claves no se publican aquí.

### Perfil de staging

Existe el perfil [config/staging.json](config/staging.json):

```powershell
flutter run --dart-define-from-file=config/staging.json
```

Antes de usarlo, confirmar URL y entorno autorizado. Su existencia no acredita
que el servicio tenga las migraciones o funcionalidades de la rama C5.
Esta revisión no comprobó su disponibilidad ni desplegó cambios.

Configuración admitida:

| Variable | Uso |
| --- | --- |
| `APP_ENV` | `dev`, `staging` o `prod`. |
| `API_BASE_URL` | URL base de la API configurada, sin añadir un `/v1` inexistente. |
| `CONTENT_BASE_URL` | Origen opcional de imágenes públicas legadas; si se omite, se usa la API. Las imágenes privadas C5 usan su lector autenticado. |
| `DEMO_MODE` | Accesos demostrativos en desarrollo; staging/producción requieren `false`. |

Fuera de desarrollo se exige HTTPS. No incluir contraseñas, JWT, secretos
SMTP ni credenciales PostgreSQL/Supabase en assets, Git o defines de la APK.
Consultar [conexión staging](docs/FLUTTER_STAGING_CONNECTION.md) para más detalles.

## Calidad y evidencia

Comandos desde la raíz móvil:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Ejecutar `flutter pub get` antes si faltan las dependencias.

**Última evidencia registrada, 20 de octubre; no repetida en esta revisión documental:**

- Flutter: **950 pruebas aprobadas y 13 opt-in omitidas** en la regresión registrada.
- C5-C1: **30 pruebas nuevas**, incluidas en esa regresión; comprobación final dirigida **32 aprobadas/3 omitidas**.
- C5-C1 con API y PostgreSQL reales: **3/3 aprobadas**, ejecutadas por separado. La suite nueva se añadió durante el recorrido general; sin el entorno local sus tres casos se omiten expresamente.
- C5-A/B: **23/23 PostgreSQL/HTTP**, **124/124 del panel** y **126 suites/1.650 pruebas backend**, según sus actas.
- Análisis Flutter y compilación debug aprobados. Las cinco comprobaciones humanas estaban pendientes al cerrar el20; el21 se confirmaron5/5, según la actualización siguiente.

**Cierre local del21:** C5-C1 Android5/5,3/3 Flutter VM/API/PostgreSQL repetidas,
57/57 dirigidas tras el arreglo visual, análisis limpio y APK reinstalada.
No se repitió la regresión global950 ni la suite backend completa por ese arreglo.
Después, C2-A sí ejecutó backend completo:126 suites/1.657 aprobadas,31/31
PostgreSQL/HTTP y70 migraciones temporales. C2-B amplió esa evidencia a127 suites/
1.670 backend,130/130 panel y37/37 PostgreSQL/HTTP. C2-C amplía a128 suites/
1.675 backend,44/44 PostgreSQL/HTTP y969 Flutter aprobadas/16 opt-in omitidas.
Análisis Flutter y compilación backend aprobados. El acta C2-C distingue27
incidencias ESLint preexistentes del control dirigido aprobado. C2-D Android pendiente.

No sumar los contadores como si fueran pruebas diferentes ni considerar aprobadas
las omitidas. Compilar una APK no acredita instalación, prueba física, firma de
tienda, despliegue o funcionamiento productivo.
[Acta C5-C1](docs/C5C_FLUTTER.md) y [acta panel](docs/C5B_PANEL.md).

QA-1 sigue pendiente: no hay workflow Flutter en esta copia. Las pruebas locales
no sustituyen CI remoto. Las integraciones opt-in requieren su propio entorno
aislado; no ejecutarlas contra una base real por copiar un comando histórico.

## Trabajo del equipo y etapas restantes

- **Propietario:** C5-C1 cerrada, A/B/C1+C2-A/B publicadas en rama y [C2-C validada automáticamente](docs/C5C2C_CONSUMIDORES.md), sin commit/push nuevos. Sigue C2-D Android y resto C5-C/D. Sin merge ni despliegue.
- **Compañero:** OV-1 en su rama; revisar su checkpoint al recibir una entrega, sin asumir cambios no presentes en estos clones.
- Cada frente puede modificar Flutter y backend cuando lo necesite. Coordinar esquema Prisma, migraciones, módulos, contratos y archivos compartidos.
- Trabajar en ramas independientes y entregar mediante PR revisado a `main`. No descartar cambios propios para actualizar el repositorio ni hacer push, merge, migraciones o despliegues automáticos.

Después se coordinan los bloques pendientes: académico/profesor/panel
(incluidos P5/D3 cuando se autoricen), catálogo/versiones, insignias anuales y
perfiles, ranking institucional y ensayo social, certificados y seguridad,
compras/anuncios y operación. **UI-F** — diseño azul, reorganización de ventanas,
accesibilidad y animaciones finales — va antes de la beta integral y las capturas
de tienda. El orden y las dependencias exactas no se deciden en este resumen:
se consultan en [etapas pendientes](docs/ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).

No reabrir instituciones, Rescate ni reportes por encontrar una instrucción antigua
que diga «siguiente». No activar pagos, publicidad o servicios remotos por este README.

## Documentación y antecedentes

- [Índice documental](docs/INDICE_DOCUMENTACION.md): entrada al resto de contratos y actas.
- [Etapas pendientes](docs/ETAPAS_PENDIENTES.md): inventario y dependencias.
- [C5-C1](docs/C5C_FLUTTER.md): cierre local5/5. [C5-C2](docs/C5C2_OPCIONES.md): continuación del propietario.
- [Trabajo paralelo](docs/TRABAJO_PARALELO.md): responsabilidades, ramas y entregas.
- [Checkpoint OV-1](docs/CHECKPOINT_OV1.md): estado del frente del compañero.
- [Historial de etapas](docs/HISTORIAL_ETAPAS.md): decisiones y entregas previas.
- [README anterior archivado](docs/README_HISTORICO_2026_10_21.md): notas conservadas, no instrucciones vigentes.

Se reorganizó este README el 21 de octubre para separar estado actual,
uso, calidad y antecedentes. El contenido anterior se conserva en el archivo
histórico; solo se ajustaron sus enlaces relativos al moverlo. Las fechas,
contadores y secuencias antiguas describen sus entregas, no nuevas tareas.
