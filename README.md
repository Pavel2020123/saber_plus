# SaberPlus

**Trabajo actual 3/nov:** [LIC-4: retorno personal y solicitudes de privacidad](docs/LIC_4_CUENTA_Y_PRIVACIDAD.md).
Implementación y auditoría local verificadas; no implica publicación ni despliegue.
Validación física de los recorridos institucionales aprobada:
[acta Android LIC](docs/LIC_ANDROID_VALIDACION.md).

**Estado 3/nov:** [LIC-3: identidad y estados de acceso institucional](docs/LIC_3_ACCESO_INSTITUCIONAL.md),
sobre LIC-1/2 locales. Portal y evidencia consolidada en el repositorio backend.
Las prioridades fechadas inferiores son antecedentes; no hay despliegue ni release
Android por estas verificaciones.

**Retoma revisada, 31/oct:** leer [estado y ruta después de la presentación](docs/RETOMA_DESARROLLO_2026_10_31.md) y [pruebas H3 Android USB](docs/H3_PRUEBAS_USB_2026_10_31.md). H3 tiene cobertura local automatizada de los escenarios USB; aceptación humana y despliegue separados. ESLint sigue abierto; propuesta #14 solo documentada. Google Play Billing previsto. Las prioridades fechadas inferiores son antecedentes.

[Actividades tipo cuadernillo de Inglés](docs/ACTIVIDADES_CUADERNILLO.md): editor,
formatos, uso en la lección y alcance de la corrección de entrenamiento local.

**Prioridad vigente desde 26/oct hasta la presentación del 28/oct:**
[recorrido y alcance para el cliente](docs/PRESENTACION_CLIENTE_2026_10_28.md). Pavel pausó la limpieza
ESLint y el recorrido técnico de etapas para preparar la experiencia educativa.
Conservar sus cambios y evidencias; no declararlos terminados. OV-1 sigue con
su responsable. Las notas técnicas inferiores son antecedentes durante esta pausa.

**Trabajo vigente del 25/oct:** [limpieza de ESLint backend por bloques](docs/LIMPIEZA_ESLINT_BACKEND.md),
autorizada por Pavel. H3 queda en espera con 1/4 guiones aprobado; H3-2 pendiente
de regresar a la primera cuenta. No dar H3 ni la limpieza global por terminadas.
OV-1 continúa independiente; conservar todos los cambios locales anteriores.
Actualización 26/oct: bloque competitivo L2-B/L3 verificado con 103 pruebas
dirigidas y ambos proyectos TypeScript aprobados.
Limpieza parcial: quedan 229 errores/116 advertencias de lint; sigue L2-B/L3.

**Checkpoint vigente — 25/oct:** [H3 preparada y pausa antes de USB](docs/C5_H3_INTEGRACION.md).
Panel 144/144, sintaxis 29 módulos y Flutter dirigido 39/39. Integración H3
PostgreSQL/HTTP/Chromium aprobada: 92/92, 78 migraciones solo temporales.
Sesión humana y APK debug preparadas; Flutter completo: 1.020 aprobadas,
16 omitidas, cero fallos. APK de pruebas instalada; H3-1 aprobada en Android:
originales en historial/cuaderno tras edición y archivo, sin XP adicional.
Humanos 1/4: sigue H3-2, cambio de cuenta. H3 abierta; quedan 6 entregas C5.
Las entradas fechadas anteriores son antecedentes; OV-1 continúa independiente.

Aplicación móvil de preparación para las pruebas Saber 11, con estudio por áreas,
práctica, seguimiento del aprendizaje y juegos educativos. Incluye herramientas
para profesores e instituciones y un panel web para administrar contenido.

**Última revisión documental: 24 de octubre de 2026.**
Este README resume el estado de la copia local revisada; no certifica despliegue
productivo ni vuelve a ejecutar las pruebas de las actas.

## Estado actual y siguiente paso

**24/oct: [H2 cerrada en su alcance backend local](docs/C5_H2B4_FUENTES_MUTABLES.md).**
92/92 SQL/HTTP con78 migraciones temporales y178 unitarias editoriales aprobadas.
Se verificó la denegación para lecciones/casos sin prueba de versión; no se inventó
un historial de esos registros. Sigue **H3: integración visual y después Android**,
con4 guiones humanos pendientes. Quedan6 entregas C5. Sin despliegue ni cambios OV-1.

**24/oct: [H2B3 validada localmente](docs/C5_H2B3_BATALLAS.md)**: Batallas conserva
sus preguntas y opciones originales, con acceso a imágenes por avance propio.
87/87 SQL/HTTP,78 migraciones temporales y133 suites/1.755 unitarias backend.
Ese antecedente continuó en H2B4; entonces quedaba1 parte H2 y7 entregas C5.

**24/oct: [H2B2 validada localmente](docs/C5_H2B2_TIRA_ONLINE.md)**: imágenes
originales de Tira online por participante y ronda habilitada/certificada.
80/80 SQL/HTTP,77 migraciones solo temporales y132 suites/1.744 unitarias backend.
Este antecedente continuó en H2B3; entonces quedaban2 partes H2 y7 entregas C5.

**24/oct: [H2B1 validada localmente](docs/C5_H2B1_TRIVIA_LOCAL.md)**: imágenes
originales propias en Trivia/Fantasma y nuevas partidas CPU de Tira local.
75/75 SQL/HTTP,76 migraciones solo temporales y131 suites/1.735 unitarias backend.
Este antecedente continuó en H2B2; entonces quedaban3 partes H2 y7 entregas C5.
Sin prueba Android ni despliegue; OV-1 mantiene su frente independiente.

**24/oct: [H2A validada localmente](docs/C5_H2_SNAPSHOTS.md)**: acceso a imágenes
originales de partidas propias en Cima/Guardián/Rescate.68/68 SQL/HTTP con75
migraciones solo temporales,159 dirigidas y build aprobados. Continuó H2B1 (otros
formatos); entonces H2 no estaba cerrada y quedaban7 entregas C5. Sin Android/producción.

**24/oct: [C5-H1 cerrada en su alcance backend local](docs/C5_H1_HISTORIAL_REVOCACION.md).**
58/58 PostgreSQL/HTTP y74 migraciones exclusivamente temporales con Docker;
150 dirigidas y build repetidos. Panel Chromium escritorio/390px aprobado.
Sin Flutter nuevo, Android ni despliegue en H1; entonces seguía H2 y quedaban7 entregas C5.

**23 de octubre: [C5-C2 cerrada localmente y auditada](docs/C5C2_CIERRE_LOCAL.md).**
D1–D8 con D8a–e cubiertos según las actas y sus límites. C2 no cierra toda C5
ni acredita despliegue, nuevos modos competitivos, iOS o Play Store.

Entrega funcional publicada e integrada: Flutter PR #10/`44635ae`, backend
PR #12/`9c225cb`. Remates TypeScript/documentales en `fix/c5-c2-cierre-local`,
sin commit/push nuevos todavía; no confundirlos con la integración funcional.

Auditoría repetida aquí el23:1.016 Flutter aprobadas/16 opt-in omitidas y análisis
limpio; build backend/128 suites/1.675 pruebas;132 panel/28 módulos de sintaxis.
PostgreSQL/HTTP50/73 migraciones y Android son evidencia previa del compañero,
no una repetición con Docker/celular en este cierre.

**Bloque actual del propietario: [C5-H, imágenes históricas](docs/C5_HISTORICOS.md).**
Pavel confirmó conservar la imagen original del historial propio tras archivar
la pregunta, salvo revocación por seguridad/derechos. H1 pasó la validación real
de PostgreSQL/HTTP en una base propia temporal ya eliminada. H2 también está
cerrada localmente; sigue preparar H3. No ampliar permisos por evitar404 ni guardar bytes
para PDF/offline todavía. Se avisará antes de necesitar Docker o celular.
Fotos/evidencias privadas, proveedor persistente y C5-D siguen abiertos.
OV-1 conserva compañero, ramas y checkpoint independientes.

Fuentes: [cierre vigente](docs/C5C2_CIERRE_LOCAL.md),
[pruebas y límites](docs/C5C2D_VALIDACION_LOCAL.md),
[entrega revisada](docs/C5C2_REVISION_TIMEOUT_D8B.md),
[contrato de Tira local](docs/C5C2_TIMEOUT_LOCAL.md).

| Bloque | Qué está hecho | Qué falta / límite |
| --- | --- | --- |
| Instituciones PR-I5 | Directorio, departamento/municipio, aprobación, presentación, logo, solicitudes de estudiantes y código privado; cierre técnico local e integración en `main`. | Despliegue y validación productiva, observaciones del acta y ranking institucional separado. [Cierre](docs/CIERRE_INSTITUCIONES_LOCAL.md). |
| Cobertura y reportes MA-1/MA-1R | Cobertura del banco, formulario, Mis reportes y gestión ADMIN; R1–R4 validadas localmente e integradas en `main`. | Operación real y ensayo autorizado de staging. Ocultar/Deshacer es una propuesta separada, no está implementada por cerrar R4. [Acta](docs/MA1R_R4_VALIDACION_LOCAL.md). |
| C5-A y C5-B | Base de imágenes editoriales privadas, carga desde el panel y asociación segura a preguntas, casos y lecciones; pruebas locales aprobadas. | Proveedor persistente y operación externa no configurados por esta entrega. [Contrato](docs/C5_ARCHIVOS.md) y [panel](docs/C5B_PANEL.md). |
| C5-C1 / C2 | C1: **5/5 Android aprobadas** el21. [C2 cerrada localmente tras auditoría](docs/C5C2_CIERRE_LOCAL.md): D1–D8/D8a–e cubiertos en su alcance. | Siguiente contrato de autorización histórica antes de PDF/offline; resto C5 pendiente. Carga por opción apagada por defecto, sin certificación productiva. |
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
incidencias ESLint preexistentes del control dirigido aprobado. Estado histórico
del22: C2-D7/8 por D8b. El23 se aprueban D8b y la regresión de timeout D8a;
la auditoría posterior [cierra C2 en su alcance local](docs/C5C2_CIERRE_LOCAL.md).

No sumar los contadores como si fueran pruebas diferentes ni considerar aprobadas
las omitidas. Compilar una APK no acredita instalación, prueba física, firma de
tienda, despliegue o funcionamiento productivo.
[Acta C5-C1](docs/C5C_FLUTTER.md) y [acta panel](docs/C5B_PANEL.md).

QA-1 sigue pendiente: no hay workflow Flutter en esta copia. Las pruebas locales
no sustituyen CI remoto. Las integraciones opt-in requieren su propio entorno
aislado; no ejecutarlas contra una base real por copiar un comando histórico.

## Trabajo del equipo y etapas restantes

- **Propietario:** C2 cerrada localmente tras auditoría; retoma resto C5 con el contrato de autorización histórica. Funcional en main app44635ae/backend9c225cb; remates en fix/c5-c2-cierre-local sin commit/push nuevos. [Cierre y límites](docs/C5C2_CIERRE_LOCAL.md).
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
