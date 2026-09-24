# JN-4 — Escudo del conocimiento

Actualizado: 24 de septiembre de 2026.

## Estado y alcance

**JN-4A: reglas y demo Flutter implementadas localmente. JN-4B: backend local probado.**
Flutter aún no está conectado al backend ni habilitado para cuentas reales. No concede XP, insignias, certificados,
progreso académico ni cambios de diagnóstico. No sustituye al Guardián: aquí se
resisten rondas para proteger una biblioteca, no se reduce la vida de un enemigo.

## Reglas provisionales v1

Son parámetros de prueba para evaluar dificultad, no reglas finales aprobadas.

- Tres rondas de cuatro preguntas (máximo doce). Sin reloj ni daño por esperar.
- Escudo inicial y máximo: tres puntos. No se reinicia entre rondas.
- Acierto: repara un punto hasta el máximo. Error: pierde un punto.
- Tras calificar la cuarta pregunta de cada ronda, si aún queda escudo, el ataque
  de tinta quita otro punto. Solo si sobrevive recupera una página.
- Cero puntos termina inmediatamente la partida. Una ronda fallida no da página.
- Victoria: sobrevivir a las tres rondas, incluido el último ataque. Se conservan
  las páginas de las rondas anteriores al perder o abandonar, solo como resultado demo.
- Ejemplo: cuatro aciertos dejan dos puntos y una página. Desde tres puntos,
  acierto/acierto/error/error termina en cero por el ataque y no entrega página.
- El mensaje entre preguntas requiere continuar; no hay ataques en segundo plano.

## Implementación

- `lib/features/games/knowledge_shield/domain`: progreso inmutable, reglas,
  intento y contrato de repositorio.
- `data`: repositorio demo con preguntas de las cinco áreas del catálogo de ejemplo.
  Identificadores diferentes no significan enunciados distintos: los ejemplos se repiten.
- `presentation`: selección de área, resistencia, rondas, feedback, victoria,
  derrota, abandono confirmado y nueva partida. Interfaz estática y desplazable.
- Provider por identidad/rol/demo: un cambio de XP no reinicia el juego; cambiar de
  usuario descarta el repositorio, incluidas operaciones que aún estaban pendientes.
- Validación de intento, pregunta actual y opción; reintentar la misma clave y
  respuesta devuelve el estado sin volver a aplicar daño/reparación. Cambiar el
  contenido de una clave usada o enviar una pregunta anterior se rechaza.
- Operaciones simultáneas rechazadas. La UI bloquea selección durante el envío
  y mantiene la clave al reintentar. No inicia una demo como respaldo de una cuenta real.
- Persistencia solo en memoria: salir de la pantalla conserva la partida;
  cerrar el proceso o cambiar de cuenta la pierde. No hay sincronización ni guardado durable.

## Cómo probar

Desde la raíz de Flutter ejecutar `flutter run`. Entrar como estudiante demo y abrir
**Practicar → Juegos individuales → Escudo del conocimiento**.

1. Elegir un área e iniciar. Verificar escudo 3 y páginas 0.
2. Responder una pregunta y continuar tras el mensaje.
3. Superar cuatro preguntas con escudo suficiente: comprobar ataque, página y ronda siguiente.
4. Probar derrota, victoria, salir/volver, cancelar abandono y confirmar abandono.
5. Revisar también texto grande, modo oscuro y teléfono pequeño.

Verificación local: **70 pruebas seleccionadas aprobadas**, incluidas 18 del
módulo y una nueva de navegación completa desde Practicar. No se ejecutó toda
la suite del proyecto ni se compiló para distribución.

Pruebas automatizadas:

```powershell
flutter analyze
flutter test test/knowledge_shield_test.dart test/star_rescue_test.dart test/widget_test.dart
```

Cubren límites del escudo, última ronda fallida, reparación, páginas, cinco áreas,
duplicados, concurrencia, identidad, abandono, reintentos, navegación y texto grande.
No sustituyen la prueba visual en un teléfono real.

## JN-4B — Backend local (24 de septiembre)

Implementado en el repositorio SaberPlus-Backend, módulo `backend/src/knowledge-shield`.
Rutas bajo `/escudo-conocimiento`: iniciar, activo, recuperar por ID, responder y abandonar.
El servidor calcula escudo/páginas y solo expone la pregunta actual. Valida propietario,
rol estudiante, JWT/correo verificado, publicación de preguntas y filtros académicos.
Requiere doce preguntas válidas; no rellena bancos pequeños con repeticiones.
Incluye snapshots privados, reintentos idempotentes, control de concurrencia,
caducidad de 24 horas y migración con RLS/revocación de acceso de clientes.
No otorga XP ni modifica diagnóstico. Contrato detallado: `backend/KNOWLEDGE_SHIELD.md`.

Build correcto; **824 pruebas Jest (82 suites) y 21 pruebas PostgreSQL temporal**
aprobadas. La instancia temporal se cerró y eliminó, sin tocar bases existentes.
No se desplegó ni se aplicó la migración en Supabase/Render.

## Entregas pendientes

1. **JN-4C — Cliente remoto:** conectar API, imágenes/contextos completos, filtros,
   recuperación persistente y errores de conexión. Nunca calificar respuestas reales localmente.
2. Migración/despliegue y ensayo real cuando se retomen esas tareas. P5/D3 siguen pausadas.
3. Arte/animaciones y audio finales: Sabi defendiendo, criaturas de tinta, reparación,
   ataque y páginas; revisar audios existentes antes de pedir archivos nuevos.

Después de JN-4C siguen MA-1 cobertura del banco, MA-2 mapa de aprendizaje y
MA-3 repaso diferido. El rediseño azul UI-F y las animaciones siguen antes de las
pruebas finales/publicación, no se incluyen en esta demo funcional.
