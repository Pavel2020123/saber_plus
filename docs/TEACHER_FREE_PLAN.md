# Profesor gratuito e indicadores básicos

La etapa 7D aplica en el backend los límites del espacio institucional gratuito y agrega una vista móvil de indicadores agregados. Los límites no dependen de botones deshabilitados en Flutter: NestJS vuelve a comprobarlos dentro de transacciones serializables.

## Límites

| Capacidad | Plan gratuito | Plan sin anuncios |
| --- | ---: | ---: |
| Grupos | 1 | 5 |
| Estudiantes institucionales | 40 | 200 |
| Analítica | Básica y agregada | Detallada, en una etapa posterior |
| Publicidad | Moderada | Sin anuncios |

`Institucion.limiteGrupos` y `Institucion.limiteEstudiantes` permiten que el backend cambie un límite concreto sin publicar otra versión móvil. Una migración inicializa las instituciones gratuitas con un grupo y las demás con cinco.

El cupo estudiantil cuenta todas las cuentas `ESTUDIANTE` vinculadas a la institución, aunque todavía no tengan un grupo. Mover a una persona entre grupos propios no consume otro cupo. La creación manual, importación y aceptación de códigos temporales validan nuevamente el cupo dentro de su transacción.

## Indicadores básicos

`GET /instituciones/me/analiticas-basicas` devuelve los últimos treinta días:

- estudiantes vinculados y estudiantes con actividad;
- simulacros completados;
- promedio de puntaje sobre 100;
- avance promedio de subtemas;
- última fecha de actividad;
- el mismo resumen por cada grupo autorizado.

Un profesor recibe únicamente sus grupos asignados. Propietarios y administradores reciben los grupos de la institución. El contrato no incluye nombres, correos, identificadores de estudiantes ni listas individuales. Flutter también rechaza una respuesta básica que contenga campos de identidad.

La analítica detallada, las alertas, las prioridades y las exportaciones rechazan el plan gratuito. Su implementación se documenta en [TEACHER_NO_ADS_PLAN.md](TEACHER_NO_ADS_PLAN.md).

## Publicidad moderada

Esta etapa define la política y la frontera técnica, pero mantiene desactivado el cliente publicitario hasta configurar las aplicaciones y unidades reales de AdMob:

- banners únicamente en navegación del profesor: panel, grupos o analítica;
- ningún banner en preguntas, lecciones, simulacros, juegos o Pomodoro;
- intersticiales solo en una pausa natural y después de al menos dos acciones completadas;
- tope local del profesor: tres intersticiales por ventana de treinta minutos;
- el límite local deberá complementarse con el límite remoto de la aplicación y la unidad en AdMob;
- el plan sin anuncios no solicita banners ni intersticiales;
- nunca se envían a publicidad grupos, institución, puntajes, falencias o actividad académica.

Google exige usar anuncios de prueba durante el desarrollo y ubicar intersticiales en interrupciones lógicas, no después de cada acción. La integración real y el consentimiento aplicable se completarán en la etapa 8.

Documentación oficial de referencia:

- [Limitación de frecuencia en AdMob](https://support.google.com/admob/answer/6244508)
- [Implementaciones intersticiales no permitidas](https://support.google.com/admob/answer/6201362)
- [Anuncios de prueba para Flutter](https://developers.google.com/admob/flutter/test-ads)

## Despliegue

La migración `20260901193000_teacher_free_plan_limits` agrega `limiteGrupos` y las restricciones de valores positivos.

```powershell
npx prisma migrate deploy
```
