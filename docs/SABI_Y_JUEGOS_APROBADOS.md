# Sabi y ampliaciones aprobadas

Acuerdos del 18 de septiembre de 2026. **Cambio de prioridad: funciones primero;
arte y animaciones al final**, por decisión del usuario. No borrar el prototipo de
Sabi ni interpretar la pausa como cancelación de su diseño.

**JN-1A tiene implementación funcional demo y JN-1B backend local probado**
de Salto a la cima, sin despliegue; JN-1C cliente remoto ya está implementado.
JN-2A reglas/demo de Rescate de estrellas implementada el 19 de septiembre;
JN-2B backend implementado localmente el 23 de septiembre y JN-2C Flutter remoto el 24.
Falta despliegue/ensayo real. JN-4A demo de Escudo implementada el 24 de septiembre;
siguen JN-4B backend y JN-4C cliente remoto. Las tres mejoras académicas siguen pendientes. G-SABI-1B conserva
su muestra vectorial, sin aprobación artística ni integración en partidas reales.
P5 y la conexión real D3 quedan pendientes y pausadas por decisión del usuario;
estas ampliaciones no las sustituyen. [Duelo fantasma animado](SABI_DUELO_FANTASMA.md)
se retoma al final, no es la siguiente tarea.

## Orden funcional propuesto para continuar por entregas

Perfiles e insignias por juego tienen una ampliación propia PR-I1–PR-I7 en
[PERFILES_RANKINGS_INSIGNIAS.md](PERFILES_RANKINGS_INSIGNIAS.md), con prompts
distintos por familia. Preparación de insignias estáticas no reabre las animaciones.
Integrar PR-I1–6 antes del arte final; su ensayo real se coordina con P5/D3.

1. **JN-1 — Salto a la cima:** A demo funcional y B backend local listos;
   C cliente remoto implementado. Migración real y ensayo en staging pendientes.
2. **JN-2 — Rescate de estrellas:** A demo, B backend y C cliente remoto locales
   listos. Migración/despliegue y ensayo real pendientes. Arte al final.
3. **JN-4 — Escudo del conocimiento:** A demo local lista; B backend y C cliente remoto pendientes.
4. **MA-1 — Cobertura del banco:** diagnóstico editorial antes de poblar más juegos.
5. **MA-2 — Mapa de aprendizaje:** relaciones entre temas, orientación sin bloqueos.
6. **MA-3 — Repaso diferido:** agenda de retención y sincronización.
7. **Arte/animación final:** Sabi compartido, Fantasma, Tira y afloja, Guardián y
   juegos nuevos; revisar accesibilidad, movimiento reducido y rendimiento.

**JN-3 — Taller de inventos fue cancelado por decisión del usuario.** Se retira
del alcance y de las tareas de audio. Se conserva el identificador JN-4 de Escudo
para mantener las referencias existentes; JN-3 no es una etapa pendiente.

No confundir implementar API/cliente con desplegarlos: P5/D3 y sus dependencias
deben retomarse antes de dar por probadas las funciones reales.

## Un protagonista compartido

- Un único personaje, provisionalmente llamado Sabi, protagonizará todos los juegos.
- El usuario entregó en la conversación referencias de un ajolote turquesa con
  branquias coral, camiseta azul marino y S⁺, además de una transformación musculosa.
  Estas son referencias visuales, no archivos articulados ni animaciones listas.
  Usar la familia visual de esas últimas referencias; antes de producir el arte
  definitivo fijar una imagen maestra y su archivo local, sin mezclar variantes.
- La camiseta debe llevar el logo elegido de SaberPlus, S con + en exponente.
- Conservar identidad y proporciones entre juegos; reutilizar animaciones y cambiar
  acciones o accesorios según el contexto, sin exigir más mascotas principales.
- Rive es una opción propuesta. La imagen por sí sola no es un archivo animado:
  faltan preparación por piezas, animación, integración y pruebas en dispositivos.
- Requisito explícito: movimiento fluido y personaje consistente. No simular la
  animación alternando imágenes generadas con caras, anatomía o proporciones distintas.
- Cada juego puede tener su propia celebración: la transformación musculosa no es
  obligatoria en todos. No se necesitan más protagonistas para variar los movimientos.

## Tres juegos nuevos confirmados

### JN-1 — Salto a la cima

- Sabi asciende por plataformas flotantes respondiendo preguntas.
- Cada acierto permite subir; cada error hace caer **un escalón**.
- Corrección expresa del usuario: no interrumpir la partida con una explicación
  al fallar; la consecuencia durante el juego es el descenso.
- JN-1A usa reglas iniciales ajustables: base 0, meta 5 y máximo 12 preguntas, sin
  cronómetro ni descenso bajo cero. Ver [SALTO_A_LA_CIMA.md](SALTO_A_LA_CIMA.md).
  Estos valores requieren revisión de dificultad, no aprobación artística. Una
  revisión académica detallada al terminar sigue pendiente de decisión.

### JN-2 — Rescate de estrellas

- Las estrellas están atrapadas en burbujas.
- Cada respuesta correcta permite a Sabi liberar una estrella.
- Completar pequeños grupos reconstruye una constelación.
- JN-2A usa parámetros provisionales de prueba: 6 estrellas, grupos de 3 y
  máximo 10 preguntas; error consume pregunta sin quitar estrellas, sin cronómetro.
  Se gana al liberar las 6 o se termina con rescate parcial al agotar preguntas.
  Son hipótesis ajustables, no reglas finales aprobadas. Ver
  [RESCATE_DE_ESTRELLAS.md](RESCATE_DE_ESTRELLAS.md).

### JN-4 — Escudo del conocimiento

- Sabi protege una biblioteca de pequeñas criaturas de tinta.
- Los aciertos reparan el escudo; al final se recuperan páginas perdidas.
- Estructura de **rondas de resistencia**, para diferenciarlo del Guardián;
  no convertirlo simplemente en otro enemigo con mucha vida.
- JN-4A implementa reglas provisionales: 3 rondas de 4 preguntas, escudo de 3,
  acierto repara 1, error quita 1, ataque al cierre quita 1; sobrevivir da una página.
  Sin reloj, XP ni efectos académicos. Ver [ESCUDO_DEL_CONOCIMIENTO.md](ESCUDO_DEL_CONOCIMIENTO.md).
  Faltan backend, cliente remoto, ensayo real y arte final.

## Renovación de juegos existentes: dirección acordada

- Duelo fantasma: Sabi corre tras el fantasma de su récord, lo alcanza al superar
  ese récord o lo ve escapar si no lo consigue. Sin récord previo, establecer una
  primera referencia. Vincular el movimiento al resultado real de la partida.
  Celebración solicitada: atraparlo, levantarlo con **ambas manos** y celebrar.
  No sustituir esta escena por la transformación musculosa genérica.
- Tira y afloja: mejorar los personajes y sus movimientos con el protagonista
  compartido, conservando las reglas y validaciones del juego.
  La transformación musculosa es una propuesta para su victoria, aún por detallar.
- Guardián: representar los aciertos con proyectiles de Sabi que reducen vida o
  escudo. El usuario propuso un dado de 1 a 6 con vida/tiempo variables; su equilibrio
  y reglas definitivas siguen pendientes. No implementar multiplicadores o tiempos
  arbitrarios ni reemplazar silenciosamente las reglas actuales.
  Celebración solicitada: apoyar un pie sobre el Guardián derrotado y soltar una
  carcajada teatral de triunfo. Tratamiento propuesto caricaturesco, sin heridas.
  No generar ni contratar voces/sonidos nuevos en esta etapa sin revisar los audios.

## Tres mejoras académicas seleccionadas

- **Mapa de aprendizaje:** orientar sobre conocimientos previos y temas a reforzar,
  sin bloquear acceso al contenido. Definir relaciones entre temas y su edición.
- **Repaso diferido:** comprobar retención días después aprovechando flashcards y
  repasos existentes. Definir programación, persistencia y sincronización; evitar
  duplicar preguntas repetidas como nueva evidencia independiente de dominio.
- **Cobertura del banco en el panel:** mostrar preguntas publicadas por subtema,
  cobertura de dificultades, explicaciones faltantes y reportes. El flujo de reportes
  debe verificarse o implementarse antes de mostrar conteos como si ya existiera.

## Condiciones para las futuras entregas

- Reutilizar el catálogo área → tema → subtema y comprobar que haya contenido
  suficiente; no presentar un juego vacío como funcional.
- Definir reglas y contratos antes de recompensas, clasificaciones o animaciones
  definitivas. El backend valida resultados y XP reales, no el archivo de animación.
- Mantener preguntas legibles, reducción de movimiento y controles accesibles.
- Separar diseño, prototipo local, integración y pruebas reales en cada entrega.
- No se aprobaron otros juegos sugeridos: Camino de las pistas, Detective del error,
  Escape académico o Misión cooperativa no se incorporan por esta selección.

Estos tres juegos amplían el alcance: **no están dentro del recuento histórico
de seis juegos existentes** ni se consideran trabajo terminado de producción.
