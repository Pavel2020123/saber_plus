# Plan institucional sin anuncios

La etapa 7E completa las capacidades del espacio de profesor sin anuncios sin activar todavía cobros reales. Google Play Billing entregará el derecho comercial en la etapa 8; el backend ya conserva la decisión final sobre el plan y sus límites.

## Capacidades

| Capacidad | Gratis | Sin anuncios |
| --- | ---: | ---: |
| Grupos | 1 | 5 |
| Estudiantes | 40 | 200 |
| Analítica | Agregada | Detallada por estudiante |
| Alertas y prioridades | No | Sí |
| Exportación CSV/PDF | No | Sí |
| Publicidad | Moderada | Ninguna |

Un valor de plan desconocido se interpreta como `GRATIS`. Si `fechaVencimientoPlan` ya pasó, el backend revierte inmediatamente a las capacidades gratuitas aunque el dispositivo conserve datos antiguos.

La activación administrativa provisional utiliza:

```http
PATCH /admin/instituciones/:id/plan
```

Acepta exclusivamente `GRATIS` o `SIN_ANUNCIOS`, actualiza juntos el plan y los límites, y registra `PLAN_INSTITUCIONAL_ACTUALIZADO` en la auditoría. Esta ruta no sustituye Google Play Billing.

## Alcance docente

Las rutas protegidas son:

```text
GET /instituciones/me/analiticas
GET /instituciones/me/alertas-riesgo
GET /instituciones/me/exportaciones/analitica.csv
GET /instituciones/me/exportaciones/analitica.pdf
```

Un profesor regular recibe solamente estudiantes pertenecientes a sus grupos asignados. Propietarios y administradores pueden consultar toda la institución. El filtrado se repite en PostgreSQL; no depende de ocultar elementos en Flutter.

La analítica detallada incluye:

- promedio, simulacros, XP, avance y última actividad por estudiante;
- resultados por área y prioridad académica sugerida;
- resumen institucional o de grupos asignados;
- agrupación de las áreas que requieren mayor acompañamiento.

Las alertas consideran inactividad, diagnóstico pendiente o bajo y rendimiento reciente. Son señales orientativas: el profesor debe revisar el contexto antes de tomar decisiones.

## Exportaciones

El CSV incluye BOM UTF-8 para conservar caracteres y neutraliza valores que una hoja de cálculo podría interpretar como fórmulas. El PDF genera un resumen legible con prioridades y detalle estudiantil.

Cada exportación:

- exige nuevamente el plan sin anuncios;
- respeta los grupos autorizados;
- se entrega con `Cache-Control: private, no-store`;
- registra `ANALITICA_EXPORTADA` con actor, formato y cantidad;
- se guarda en el directorio privado de la aplicación;
- requiere confirmación porque contiene datos académicos personales.

## Experiencia móvil

La pantalla contiene tres secciones: resumen y prioridades, alertas y estudiantes. Las cuentas demostrativas pueden abrir una vista previa desde el panel del profesor. Una institución real solamente llega a esta pantalla cuando el backend devuelve `nivelAnalitica: DETALLADA`.

No se agregó una migración nueva en 7E: utiliza `planActual`, `fechaVencimientoPlan`, `limiteGrupos` y `limiteEstudiantes`, ya presentes en PostgreSQL.
