# Proyección orientativa de puntaje

La etapa 6E-D agrega `Más > Mi perfil > Puntaje proyectado`. El resultado se presenta siempre como una estimación educativa de SaberPlus y nunca como un puntaje oficial o garantizado.

## Referencia oficial

La [Resolución 268 de 2020 del ICFES](https://normograma.icfes.gov.co/compilacion/docs/resolucion_icfes_0268_2020.htm) define puntajes de prueba entre 0 y 100 y un puntaje global entre 0 y 500. El índice global asigna peso 3 a Lectura Crítica, Matemáticas, Ciencias Naturales y Sociales y Ciudadanas, y peso 1 a Inglés; después se multiplica por 5.

El mismo documento establece que los puntajes oficiales por prueba se obtienen mediante un modelo logístico de tres parámetros. Por eso, la app no trata un porcentaje de respuestas correctas como una reproducción de la calificación oficial. La página de [resultados Saber 11 del ICFES](https://www.icfes.gov.co/evaluaciones-icfes/saber-11/resultados-examen-saber-11/) continúa siendo la fuente del resultado real.

## Evidencia usada por SaberPlus

Para cada materia se selecciona la mejor evidencia disponible en este orden:

1. hasta los tres simulacros por materia más recientes, dando mayor peso al más nuevo;
2. rendimiento acumulado de respuestas confirmadas;
3. resultado del diagnóstico, cuando las fuentes anteriores no tienen datos.

La estimación solo aparece cuando existen datos para las cinco materias. Después aplica la estructura de ponderación oficial sobre esos indicadores internos. Esto es una inferencia de estudio, no el modelo 3PL del ICFES.

## Confianza y rango

- Alta: las cinco materias tienen simulacros y estos reúnen al menos 100 preguntas.
- Media: al menos tres materias y 60 preguntas proceden de simulacros.
- Baja: las cinco materias tienen evidencia, pero todavía faltan simulacros suficientes.

El rango orientativo se amplía cuando la confianza es menor. No representa un intervalo estadístico oficial. El perfil también compara la estimación central con el objetivo personal elegido por el estudiante.
