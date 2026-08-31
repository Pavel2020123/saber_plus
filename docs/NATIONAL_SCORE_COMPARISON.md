# Comparación con referencias nacionales

La etapa 6E-G agrega `Más > Mi perfil > Referencia nacional`. La pantalla compara la estimación educativa de SaberPlus con el promedio global nacional publicado por el ICFES para Saber 11.

## Referencias incorporadas

La fuente es la página de [Estadísticas oficiales del ICFES](https://www.icfes.gov.co/estadisticas-oficiales/), verificada el 30 de agosto de 2026. La serie histórica publicada separa las aplicaciones por calendario. La versión actual registra para 2025:

- calendario A: 263,5 puntos sobre 500;
- calendario B: 318,6 puntos sobre 500.

El estudiante selecciona el calendario correspondiente. No se mezclan ambas poblaciones ni se construye un promedio nuevo.

## Límites de interpretación

La estimación de SaberPlus proviene de simulacros y actividades internas; no utiliza el modelo estadístico del examen oficial. La diferencia presentada:

- no es un percentil;
- no representa un puesto nacional;
- no modifica el puntaje proyectado;
- no determina admisión, becas ni Distinción Andrés Bello;
- no compara al estudiante con una persona identificable.

El ICFES define metodológicamente la población incluida en sus agregados. La app enlaza la fuente para que el estudiante pueda revisar ese contexto.

## Actualización futura

Los valores están aislados en un catálogo versionable con año, calendario, fuente y fecha de verificación. Antes de producción, el backend podrá publicar el referente vigente mediante un contrato firmado o versionado. Flutter no debe obtener promedios raspando páginas en tiempo de ejecución ni mostrar una referencia sin trazabilidad.
