# SaberPlus: estructura y arquitectura para el equipo

Documento de incorporación al proyecto. Revisión: 23 de septiembre de 2026.
Describe la organización del código local, no certifica que todas las funciones
estén desplegadas o aprobadas para producción.

## 1. ¿Qué arquitectura usamos?

**Flutter usa una arquitectura por funcionalidades y capas, inspirada en Clean
Architecture. No es Clean Architecture estricta.** El backend es un monolito
modular NestJS y el panel administrativo es una aplicación web de JavaScript modular.

| Componente | Organización real | Tecnologías principales |
| --- | --- | --- |
| App Android/iOS | Feature-first con capas de presentación, dominio y datos | Flutter, Dart, Riverpod, Dio, GoRouter |
| API | Monolito modular: controladores, servicios, DTO y acceso a datos | NestJS sobre Express, TypeScript, Prisma |
| Panel administrador | HTML/CSS y módulos JavaScript; servidor Node para servirlo y ejecutar la demo | JavaScript ES modules, Node.js |
| Base remota | PostgreSQL alojado en Supabase | Prisma y migraciones SQL |
| Persistencia del dispositivo | Almacenamiento local según el tipo de dato | Drift/SQLite, almacenamiento seguro y preferencias |

Aplicamos separación de responsabilidades, interfaces de repositorios e inyección
de dependencias. Sin embargo, no todas las acciones pasan por clases de casos de
uso: hay proveedores de presentación que importan proveedores definidos en datos,
y servicios del backend que usan Prisma directamente. Por eso no debemos presentar
el proyecto como una arquitectura Clean pura ni como microservicios.

## 2. Cómo se conectan las piezas

```text
App Flutter ───────── HTTPS / API ────────┐
    │                                   │
    └─ SQLite, preferencias             ▼
       y sesión local              Backend NestJS ── Prisma ── PostgreSQL
                                        ▲                       en Supabase
Panel administrador ─ HTTPS / API ───────┘

Algunos juegos también utilizan Socket.IO para comunicación en tiempo real.
```

Render aloja el servicio del backend; Supabase aloja la base de datos. Son piezas
distintas. Flutter y el panel no necesitan la contraseña de PostgreSQL: consultan
la API, que valida identidad, permisos y reglas de negocio.

La demo del panel es una excepción deliberada: utiliza datos en memoria de su
servidor local y no escribe en Supabase. Sus cambios se pierden al reiniciarlo.

## 3. Repositorios y carpetas

### Aplicación móvil: `saber_plus`

```text
saber_plus/
├── lib/
│   ├── main.dart             Entrada de la aplicación
│   ├── bootstrap.dart        Inicialización y ProviderScope
│   ├── app/                  Aplicación, rutas y tema visual
│   ├── core/                 Infraestructura y componentes compartidos
│   └── features/             Funcionalidades organizadas por módulo
├── assets/                   Imágenes, audios y otros recursos
├── android/                  Configuración nativa Android
├── ios/                      Configuración nativa iOS
├── test/                     Pruebas automatizadas
├── tool/                     Herramientas auxiliares
├── config/                   Configuración por entorno
├── docs/                     Contratos, guías y etapas
└── pubspec.yaml              Dependencias y declaración de recursos
```

`build/` y `.dart_tool/` son resultados/herramientas de compilación: no contienen
la lógica que debemos editar ni deben subirse como parte de una funcionalidad.

### Backend y panel: `SaberPlus-Backend`

Repositorio independiente: [SaberPlus-Backend](https://github.com/Pavel2020123/SaberPlus-Backend).

```text
SaberPlus-Backend/
├── backend/
│   ├── src/                  API NestJS por módulos
│   ├── prisma/
│   │   ├── schema.prisma     Modelos de base de datos
│   │   └── migrations/       Historial de cambios de esquema
│   ├── test/                 Pruebas de integración y otras pruebas
│   ├── tool/                 Verificación y herramientas de base
│   └── package.json          Dependencias y comandos del backend
├── admin/
│   ├── public/               HTML, CSS y módulos del panel
│   ├── test/                 Pruebas del panel
│   ├── server.mjs            Servidor local y modo demo
│   └── package.json          Comandos propios del panel
├── .github/                  Automatizaciones del repositorio
└── render.yaml               Configuración del despliegue
```

El antiguo proyecto `Icfes_Vida` sirve como referencia histórica y visual.
Su frontend Next.js no es el panel actual de SaberPlus. Los cambios del panel
actual se hacen en `SaberPlus-Backend/admin`, no en esa web antigua.

## 4. Capas de Flutter con un ejemplo real

En módulos como `features/study` encontramos:

| Capa | Responsabilidad | Ejemplo |
| --- | --- | --- |
| `presentation` | Pantallas, estado y coordinación de acciones | `study_lesson_page.dart`, `study_providers.dart` |
| `domain` | Modelos y contratos de operaciones | `study_models.dart`, `study_repository.dart` |
| `data` | Implementación de consultas remotas o almacenamiento local | `remote_study_repository.dart` |

Ejemplo de carga del catálogo:

1. La pantalla observa `studyCatalogProvider` con un área.
2. El proveedor consulta la sesión; si es demo, devuelve un catálogo de ejemplo.
3. En modo real llama a `StudyRepository.loadCatalog`.
4. `RemoteStudyRepository` usa Dio para consultar `/simulacros/temas`.
5. La respuesta se convierte en `StudyCatalog` y la presentación actualiza la vista.
6. Los errores HTTP se traducen a `ApiError` para que la interfaz los gestione.

Archivos para seguir el recorrido:

- [Proveedores de estudio](../lib/features/study/presentation/study_providers.dart).
- [Contrato del repositorio](../lib/features/study/domain/study_repository.dart).
- [Implementación remota](../lib/features/study/data/remote_study_repository.dart).
- [Controlador de sesión](../lib/features/auth/presentation/session_controller.dart).

Riverpod proporciona estado e inyección de dependencias; GoRouter organiza la
navegación. Un repositorio evita repartir peticiones HTTP por todos los widgets.
No todos los módulos tienen exactamente el mismo tamaño o las mismas carpetas.

### Qué pertenece a `core`

Red y errores HTTP, configuración, base local, almacenamiento seguro,
sincronización, preferencias, notificaciones, audio/feedback, seguridad y widgets
reutilizables. Una regla específica de un juego debe permanecer en su funcionalidad,
no trasladarse a `core` solo porque la usan dos pantallas de ese mismo juego.

### Familias de funcionalidades

- Acceso y perfil: `auth`, `profile`, `dashboard`.
- Aprendizaje: `academic`, `study`, `practice`, `library`, `progress`.
- Herramientas: `favorites`, `search`, `flashcards`, `focus`, `resume`, `study_time`.
- Experiencia lúdica: `games`, `battles`, `gamification`, `ranking`.
- Instituciones y acompañamiento: `institutions`, `announcements`, `support`.

Esta agrupación orienta la lectura; no es un inventario exhaustivo ni implica que
todos los módulos estén listos para producción.

## 5. Organización del backend

`backend/src/app.module.ts` compone los módulos en una sola aplicación.
`backend/src/main.ts` configura el arranque, CORS, validación y protecciones HTTP.

Flujo habitual:

```text
Petición → autenticación/permisos → controlador y DTO → servicio → Prisma → base
```

- **Controlador:** expone rutas y recibe solicitudes.
- **DTO:** define y valida el formato de entrada.
- **Guard:** verifica acceso según sesión y rol.
- **Servicio:** ejecuta reglas del módulo y coordina datos.
- **PrismaService:** facilita el acceso a PostgreSQL.

Ejemplos de módulos: `auth`, `admin`, `institucion`, `simulacro`, `gamificacion`,
`ranking`, `trivia-rush`, `tira-afloja`, `guardian` y `summit`.
Algunas pruebas unitarias viven junto al código en `src`; no todas están en `test`.

El servidor debe ser la autoridad sobre permisos, resultados y recompensas.
Ocultar un botón en Flutter no protege una operación. Los nuevos endpoints deben
validar también propietario, institución y demás condiciones que correspondan.

## 6. Panel y organización del contenido

El panel actual no requiere React ni Next.js. `app.mjs` coordina la interfaz;
`api.mjs` agrupa el acceso a la API. Los editores de lecciones y preguntas se
encuentran en módulos separados dentro de `admin/public`.

La estructura académica es:

```text
Área
└── Tema
    └── Subtema
        ├── Lección: explicación, ejemplos y recursos
        └── Preguntas: opciones, respuesta correcta y explicación
```

Las cinco áreas son Lectura crítica, Matemáticas, Sociales y ciudadanas,
Ciencias naturales e Inglés. Clasificar las preguntas permite relacionar los
resultados con temas y subtemas; un error aislado no demuestra por sí solo una
falencia definitiva del estudiante.

Un **contexto compartido** es un texto o recurso que puede acompañar varias
preguntas. No reemplaza la lección del subtema.

El flujo simplificado busca crear temas/subtemas, editar su contenido y guardar
preguntas directamente visibles, sin un paso editorial obligatorio de revisión.
En modo real esto depende de los permisos y de la configuración de publicación
del backend. En demo solo modifica la memoria local.

El editor de contenido por bloques produce Markdown para la app. Flutter muestra
las lecciones con `flutter_markdown_plus`; no ejecuta una página HTML arbitraria.
Actualmente los campos de medios del editor utilizan enlaces HTTPS.

La eliminación de temas y subtemas tiene restricciones cuando existe contenido
asociado: no se debe introducir borrado en cascada que destruya progreso o historial.

## 7. Persistencia, entornos y seguridad

| Dato | Lugar y criterio |
| --- | --- |
| Datos compartidos y operaciones reales | API y PostgreSQL; las reglas se validan en el servidor |
| Contenido descargado y datos locales compatibles | Drift/SQLite y archivos del dispositivo, según el módulo |
| Sesión sensible | Almacenamiento seguro; no guardar contraseñas en preferencias |
| Preferencias de interfaz | Preferencias locales |
| Catálogo demo del panel | Memoria del servidor demo; no es persistencia real |

La existencia de SQLite no significa que toda la app funcione sin internet.
Las colas de sincronización y recuperación son específicas de cada funcionalidad.
Guardar localmente no garantiza que la operación haya llegado a la nube.

Reglas para colaborar:

- No subir `.env`, contraseñas, tokens, claves privadas ni credenciales de base.
- No incluir credenciales PostgreSQL/Supabase dentro de Flutter o JavaScript público.
- No confiar en XP, roles o permisos enviados por el cliente sin validación.
- No mostrar respuestas correctas de una partida protegida antes del momento previsto.
- No registrar tokens ni información personal innecesaria en logs.
- Conservar las validaciones del servidor aunque exista validación visual.
- No ejecutar migraciones en Supabase ni desplegar a Render sin coordinarlo.

Hay validaciones y protecciones implementadas, pero esto no sustituye una auditoría
de seguridad ni permite afirmar que no existen vulnerabilidades.

## 8. Cómo trabajar sin interferir con otros

Crear una rama por tarea en el repositorio correspondiente y entregar un Pull
Request. No trabajar directamente en `main` ni mezclar cambios ajenos en el commit.

| Tarea | Punto de entrada |
| --- | --- |
| Pantalla o estado móvil | `lib/features/<funcionalidad>/presentation` |
| Contrato/modelo móvil | `domain` de esa funcionalidad |
| Consulta HTTP o persistencia | `data` y, si corresponde, infraestructura de `core` |
| Regla o endpoint del servidor | Módulo correspondiente en `backend/src` |
| Formulario administrativo | `admin/public` y sus pruebas |
| Cambio de esquema | Prisma y una migración nueva, coordinada con el equipo |
| Imágenes y sonidos | `assets`, declaración en `pubspec.yaml` e integración/pruebas |

Antes de cambiar un contrato API, revisar ambos extremos. Actualizar pruebas y
documentación junto al código. No editar manualmente archivos generados como
`app_database.g.dart`, el cliente Prisma, `dist` o `node_modules`.

Los certificados siguen la decisión de producto: **cinco certificados de área y
uno final del curso**. La regla acordada para cada área es completar todas sus
lecciones publicadas; no añadir certificados por cualquier logro sin acordarlo.

## 9. Comandos de desarrollo y comprobación

Las rutas siguientes corresponden al equipo actual; cada compañero debe usar su
propia carpeta de clonación. Los comandos reales requieren sus dependencias y,
para la API, configuración local válida que no se comparte por Git.

### App Flutter

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter pub get
flutter analyze
flutter test
flutter run
```

### Backend

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend"
npm ci --include=dev
npm run build
npm test -- --runInBand
npm run start:dev
```

Arrancar la API no crea ni migra automáticamente la base. Las pruebas con
PostgreSQL requieren su entorno de pruebas separado; no deben apuntar a producción.

### Panel en demostración

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\admin"
npm run check
npm test
npm run demo
```

Abrir `http://127.0.0.1:4173`. Para el modo real, consultar `admin/README.md`:
se configura la URL de la API y se ejecuta `npm start`. No confundir la demo con
una sesión ADMIN real ni usarla como prueba de conexión a Supabase.

## 10. Estado y documentación que debe leerse

Una función puede estar implementada localmente y tener pendiente migración,
despliegue, prueba integrada o prueba en celular. No usar la presencia de una
carpeta como evidencia de que está publicada.

La conexión y el ensayo del panel contra el backend real forman parte de **D3**;
este documento no los da por terminados. Para el estado detallado consultar:

- [Etapas pendientes y punto de reanudación](ETAPAS_PENDIENTES.md).
- [Roadmap móvil](ROADMAP_MOVIL.md).
- [Guía de trabajo para compañeros](GUIA_TRABAJO_COMPANEROS.md).
- [Funcionalidades para el equipo](FUNCIONALIDADES_PARA_EL_EQUIPO.md).

### Resumen para una sustentación

> SaberPlus tiene una app Flutter para Android e iOS, una API NestJS y un panel
> administrativo web. La app está organizada por funcionalidades y capas,
> inspiradas en Clean Architecture. El backend es un monolito modular que valida
> las operaciones y accede mediante Prisma a PostgreSQL en Supabase. La app usa
> almacenamiento local para las funciones que lo requieren. El panel administra
> contenido e instituciones mediante la misma API. Distinguimos las demostraciones
> locales de las integraciones verificadas en el entorno real.
