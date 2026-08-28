# Biblioteca académica móvil

Este documento registra la migración de fórmulas, glosario y estrategia de examen realizada en la Etapa 5C.

## Fuente de verdad actual

El backend NestJS no expone endpoints ni tablas para estos tres catálogos. El proyecto web sí conserva contenido académico versionado en:

- `frontend/src/lib/formularios-icfes.ts`
- `frontend/src/lib/glosario-icfes.ts`
- `frontend/src/lib/estrategia-examen.ts`

Flutter no consume páginas web. El script `tool/generate_reference_library.mjs` transforma esos catálogos en `assets/data/reference_library.json`, que queda empaquetado dentro de Android y iOS.

Para volver a sincronizar el contenido desde una copia local del frontend:

```powershell
node tool/generate_reference_library.mjs `
  "C:/ruta/Icfes_Vida/frontend/src/lib" `
  "assets/data/reference_library.json"
```

La versión actual contiene:

- 80 referencias organizadas por área y sección;
- 50 términos con definición, ejemplo y conceptos relacionados;
- cuatro fases de examen, cinco tácticas por área, cuatro distractores y ocho puntos de checklist.

## Funcionamiento móvil

- La biblioteca se carga desde un recurso local y no necesita conexión ni plan vigente para volver a leer contenido ya instalado.
- El repositorio valida la versión del archivo y conserva una sola copia decodificada en memoria.
- Fórmulas y glosario ofrecen búsqueda local y filtros por área.
- La estrategia incluye un planificador que calcula tiempo útil, segundos por pregunta y controles al 25 %, 50 % y 75 %.
- El checklist es temporal para la sesión actual de la pantalla; no representa progreso académico ni se envía al backend.

Si en el futuro el contenido pasa a ser administrable desde el backend, deberá añadirse versionado, descarga firmada e invalidación de caché antes de reemplazar este recurso empaquetado.
