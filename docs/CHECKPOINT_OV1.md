# Checkpoint OV-1 — responsable: compañero

13 de octubre de 2026. **Asignado, sin evidencia nueva de implementación recibida.**
Siguiente: auditar orientación existente y preparar OV-1A según
[TRABAJO_PARALELO](TRABAJO_PARALELO.md). No esperar a C2C.

El compañero actualiza este archivo después de cada prueba/avance y el acta
OV1_ORIENTACION.md cuando la cree. Registrar fecha, HEAD y rama de ambos repos,
archivos/contratos, decisiones propuestas o aprobadas, resultados automáticos,
HTTP/SQL y humanos por separado, límites y siguiente paso exacto. Nunca secretos.
El propietario consolida el roadmap al recibir/integrar un bloque o acordar
un cambio de alcance. No editar el checkpoint de instituciones.
Crear este documento no acredita pruebas ni implementación OV-1.

---

## Avance 2026-10-14 — OV-1A

### Estado

**Propuesta preparada; pendiente de revisión y aprobación del propietario.**

No existe todavía implementación funcional nueva de OV-1 en Flutter ni Backend.

### Base de trabajo

Flutter:

- rama: `feat/orientacion-vocacional`
- HEAD inicial: `64ef962`
- base: `origin/main`

Backend:

- no modificado durante OV-1A;
- la copia local existente permanece preservada;
- no se creó todavía rama Backend para OV-1 porque esta entrega documental no requiere API, persistencia ni migraciones.

### Auditoría realizada

Se revisó la orientación existente de Flutter:

- `lib/features/profile/domain/career_orientation.dart`
- `lib/features/profile/presentation/career_orientation_providers.dart`
- `lib/features/profile/presentation/career_orientation_page.dart`
- `test/career_orientation_test.dart`

Conclusión:

La funcionalidad existente corresponde a **orientación académica basada en desempeño** y debe conservarse.

OV-1 será una orientación **por intereses declarados** y no sustituirá ni mezclará silenciosamente esos resultados.

La búsqueda dirigida en Backend no identificó una implementación existente de API o persistencia específica de cuestionario vocacional que deba reutilizarse en OV-1A.

### Artefacto creado

- `docs/OV1_ORIENTACION.md`

Contiene una propuesta inicial de:

- 30 preguntas;
- 6 familias de intereses;
- escala 0–4 más `No sé`;
- tratamiento diferenciado de `No sé`;
- cálculo normalizado por familia;
- cobertura de respuestas;
- tratamiento de intentos incompletos;
- empates sin desempate artificial;
- presentación explicable de resultados;
- ejemplos reproducibles;
- versión propuesta `ov1RulesVersion = 1`;
- decisiones que requieren aprobación del propietario.

### Límites conservados

OV-1 se mantiene como herramienta exploratoria.

No se implementó ni autorizó:

- diagnóstico psicológico;
- afirmación de validación científica;
- XP;
- ranking;
- certificados;
- recompensas según respuesta;
- publicidad segmentada;
- exposición automática a docentes o instituciones;
- recomendaciones deterministas de carrera.

### Pruebas ejecutadas en este avance

No se ejecutaron pruebas Flutter, Backend, HTTP, PostgreSQL ni Android.

Motivo: OV-1A en este punto es exclusivamente una propuesta documental y todavía no modifica código ejecutable.

Sí se ejecutó:

- `git diff --check`

Resultado:

- PASS, sin errores reportados.

No se reutilizan resultados históricos de otros checkpoints como evidencia de OV-1.

### Riesgos y decisiones pendientes

Requieren revisión del propietario antes de considerar OV-1A aprobado:

1. cantidad final de preguntas;
2. familias propuestas y nombres;
3. redacción de las preguntas;
4. escala 0–4;
5. tratamiento de `No sé`;
6. umbral global de respuestas;
7. cobertura mínima por familia;
8. cantidad de familias a mostrar;
9. tratamiento de empates en el límite del tercer lugar;
10. versión inicial de reglas;
11. revisión de contenido previa a publicación.

El CI conocido del Backend PR #7 continúa fuera del alcance de OV-1A y no se modificaron locks ni dependencias.

### Siguiente paso exacto

Revisar el diff documental completo de OV-1A y entregar la propuesta al propietario para decisión.

No iniciar OV-1B automáticamente antes de registrar cuáles reglas fueron aprobadas, modificadas o rechazadas.
