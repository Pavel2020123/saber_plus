# Perfiles, rankings e insignias — ampliación acordada

Estado: planificación con catálogo visual PR-I3A integrado localmente. Taller de inventos
continúa cancelado. Sabi conserva su nombre y diseño maestro. No se generan imágenes aquí.

## Entrega PR-I3A — arte disponible

Se integran las 40 imágenes originales en Flutter: Trivia Rush, Duelo fantasma,
Salto a la cima y Tira y afloja. Acceso desde **Mi perfil académico → Insignias de
Sabi** o desde el icono de insignia del ranking. Se muestran todas las imágenes del
juego seleccionado con detalle accesible al tocar, como catálogo, no premios ganados.

Los archivos recibidos usan rangos 1, 2, 3, 4, 5, 6–10, 11–20, 21–30, 31–40 y
41–50. Esta integración respeta el arte recibido, en lugar de inventar imágenes
para rangos distintos de los recibidos. Los nombres `top6-11` de Trivia/Fantasma se
mapean a 6–10 sin superponer el puesto 11. Solo faltan las otras familias de juegos.
Decisión vigente: rankings e insignias hasta el puesto 50; se cancela el top 100.
Fuera del top 50 se puede consultar la posición propia, pero no obtener una insignia
de clasificación. Se mantienen las colecciones anuales.
Se conservan los originales (aproximadamente 85 MB); optimizar recursos antes de
publicar sigue pendiente. No se modificaron ni regeneraron las ilustraciones.

No se conceden insignias desde XP global ni se inventan posiciones/años. Siguen
pendientes PR-I1/2, la asignación real, el cierre anual persistente y los perfiles
públicos. PR-I3 completo NO queda cerrado con este catálogo visual.

## Alcance solicitado

- Perfil estudiantil sobrio y cuidado, foto/avatar, experiencia e insignias.
- Mostrar todas las insignias de ranking vigentes obtenidas, sin límite de tres.
  Si destaca en todos los juegos, todas aparecen en su perfil, organizadas por juego.
- Buscar personas por alias/nombre público y @usuario único y visitar su perfil,
  además de entrar desde rankings. Directorio separado de instituciones.
- Rankings top 50 separados por juego; abrir el perfil público desde una entrada.
- Cinco diseños individuales para puestos 1–5 y diseños por intervalos hasta 50.
- Tocar una insignia muestra juego, posición exacta, ámbito, período y actualización.
  En web, hover/foco muestra ayuda; en móvil, toque abre detalle y pulsación larga
  puede mostrar tooltip. No depender del cursor, del color ni de texto diminuto.
- Perfil institucional con logo/foto, descripción, ubicación y experiencia colectiva.
  Solo el propietario actual modifica su identidad visual (incluida transferencia de propiedad).
- Profesor con foto y perfil funcional; no incluirlo como jugador.
- Buscar instituciones aprobadas y activas; solicitar ingreso y recibir una decisión.
- Entrada rápida por código privado controlado por el propietario, con confirmación
  del estudiante, sin esperar aprobación individual si el código sigue válido.
- Mantener seis certificados de finalización; las insignias de ranking no generan PDF.
- Insignias anuales acumulables: reutilizar el mismo arte por juego/rango y mostrar
  el año. Una distinción de 2026 permanece al obtener otra de 2027. Esta decisión
  sustituye la propuesta anterior de colección mensual.

## Lo existente y lo que debemos extender

El ranking actual es global/institucional, por semana/mes/total, hasta 50 entradas,
con alias y XP; no expone perfiles públicos ni identifica cuentas ajenas. Su contrato
Flutter rechaza campos extra. Se necesita un contrato nuevo/versionado, no añadir
datos públicos a ese contrato silenciosamente.

Los códigos existentes son de grupo, temporales, revocables y con cupos. Hoy también
los generan profesores asignados/administradores. Las solicitudes institucionales
existentes son del equipo docente; no equivalen a las nuevas solicitudes de alumnos.
Ya hay API de logo institucional: auditarla y reutilizar lo válido con Storage y
permisos del propietario, sin crear otra carga paralela.

## Reglas propuestas para cerrar antes de implementar

Estas decisiones son propuestas técnicas, no funcionalidades terminadas:

1. Temporada de insignias anual, con ranking del año y consulta histórica. Las vistas
   semanal/mensual pueden mantenerse como filtros informativos sin generar otra
   colección permanente. Cada insignia indica el año y ámbito; no mezclar un puesto
   global con uno dentro de una institución.
2. XP competitivo propio por juego, concedido por servidor una sola vez por partida
   válida. No convertir XP total de la cuenta en XP de todos los juegos. Definir por
   juego dificultad, duración, repetición de preguntas y modos comparables. Las demos,
   partidas locales no verificables y partidas con ayudas que alteran la competencia
   no entran al ranking competitivo; pueden conservar progreso recreativo separado.
3. Publicar el ranking de cada juego solo cuando tenga resultados verificables.
   Memoria, Fantasma y juegos nuevos requieren revisar su evidencia; no inventar XP
   histórico ni prometer nueve rankings operativos desde el primer despliegue.
4. Orden determinista: XP descendente y, en empate, primero quien alcanzó ese XP;
   desempate técnico estable final. Mostrar esta regla. Se diferencia del ranking
   actual, que comparte posiciones. Consultas paginadas y agregados, no cargar todos
   los estudiantes para ordenar en memoria.
5. La posición del año en curso cambia al moverse de rango y se identifica como
   provisional. Al terminar la temporada anual, guardar una insignia permanente
   por juego, ámbito y año con el puesto final exacto. Se reutiliza el mismo diseño
   del rango y se añade el año mediante texto de la app. Una insignia de 2026 no
   se reemplaza, borra ni degrada por los resultados de 2027; ambas se muestran.
   Propuesta operativa: cerrar el año calendario en America/Bogota, conceder según
   el puesto al cierre (no por haberlo ocupado un instante) y empezar el XP competitivo
   del nuevo año en cero, conservando XP total e historial. Esta regla de cierre debe
   confirmarse en PR-I1. El cierre debe ser idempotente, con registro único por
   participante/juego/ámbito/año y snapshot de reglas, XP, puesto y rango; un reintento
   no duplica insignias. Definir correcciones auditadas ante resultados invalidados.
6. Perfil: avatar, alias público, @usuario único y XP de juegos. Mostrar todas las
   insignias vigentes en una cuadrícula adaptable, agrupadas por juego y con su período
   visible, sin límite de tres ni carrusel que esconda el resto. Las insignias anuales
   obtenidas también aparecen en el perfil, agrupadas por año y juego, con filtro
   opcional; no quedan relegadas a una pantalla oculta. Distinguir «Temporada actual»
   de «Insignias conseguidas». El alumno
   puede ordenar sus juegos favoritos sin inventar ni duplicar reconocimientos.
   Estadísticas académicas, nombre del
   certificado, correo, diagnósticos y falencias permanecen privados. El usuario
   controla visibilidad; institución/membresía no se publica automáticamente.
   Usar identificador público opaco, sin exponer el ID interno o listas de alumnos.
7. Ranking institucional principal por suma de XP elegible ganado mientras el alumno
   pertenece a esa institución. Vincular cada aporte a su institución al obtenerlo;
   entrar/salir no mueve XP histórico ni permite duplicarlo. Mostrar período y
   cantidad de participantes activos. Como vista complementaria, promedio por alumno
   activo con mínimo de muestra para comparar instituciones de tamaños distintos.
8. Solicitud estudiantil: pendiente, aceptada, rechazada o cancelada. Una activa por
   estudiante; aprobación transaccional con revisión de membresía y capacidad.
   Rechazar no crea vínculo; notificación privada en la app, sin push obligatorio.
   El propietario revisa; delegación a administradores queda pendiente de decisión.
9. Código institucional separado del código de grupo: solo el propietario lo genera
   o revoca. Puede compartirlo con varias personas según vigencia/capacidad definida;
   nunca aparece en búsqueda, ranking o perfil público. Guardar hash, limitar intentos
   y consumir usos atómicamente. No tratarlo como contraseña del propietario.
   Revisar explícitamente si se restringen también los códigos de grupo existentes;
   no cambiar esos permisos sin migración y comunicación.
10. Buscar por nombre (sin distinguir tildes), ciudad/departamento y tipo de entidad;
    resultados paginados con logo, ubicación y estado verificado para distinguir
    homónimos. Ver perfil antes de solicitar. Solo instituciones aprobadas/activas.
    Una institución suspendida no recibe nuevos ingresos. Definir cambio/salida de
    institución y asignación de grupo sin mover al alumno de forma silenciosa.
11. Fotos: carga con tipo/tamaño permitidos, normalización, eliminación de metadatos,
    almacenamiento persistente y autorización. Avatar de Sabi como alternativa.
    No permitir HTML ni enlaces arbitrarios ejecutables como imagen.

## Descubrimiento y presentación social

Alcance confirmado: buscador con pestañas **Personas** e **Instituciones**, resultados
paginados y acceso a perfiles. Personas por @usuario y nombre público (no por correo,
nombre privado del certificado ni datos académicos). Distinguir homónimos por @usuario
y avatar; normalizar búsqueda y definir unicidad/cambio de identificador en servidor.
Respetar visibilidad y exclusión del directorio; no convertir automáticamente las
cuentas existentes en perfiles públicos. Un perfil privado o no disponible muestra
un estado claro, sin filtrar sus datos desde resultados, rankings o enlaces.

Perfil estudiantil: cabecera compacta con avatar y nombre público, experiencia,
cuadrícula de sus posiciones actuales y colección de todas sus insignias anuales. Cada insignia
abre juego, puesto exacto, período y XP. Tamaños legibles, espacios consistentes,
contraste y navegación accesible; las medallas aportan el color sin recargar el fondo.
Perfil institucional: logo, nombre, ubicación, descripción, posición colectiva y
acciones de solicitar ingreso/consultar estado. No publicar un directorio de alumnos
ni contactos privados por el hecho de visitar una institución.

Propuestas para alcance orgánico, por priorizar (no implementadas ni garantía de viralidad):
- Enlace compartible al perfil público y a la institución, coordinado con App Links.
- Tarjeta para compartir una insignia con juego, puesto y temporada; el usuario decide
  compartir y el enlace comprueba el reconocimiento vigente/histórico en el servidor.
- Reportar suplantación/contenido del perfil y bloquear visibilidad/interacciones con
  otra cuenta; definir estas reglas junto al directorio antes de su lanzamiento.
- Estado de institución verificada separado de sus insignias competitivas.

No se incorporan por esta decisión chat, seguidores, comentarios ni feed. Esas
funciones necesitan una decisión de producto independiente.

## Etapas nuevas PR-I

| Etapa | Entrega y criterio de cierre |
| --- | --- |
| PR-I1 — Reglas y contratos | Cerrar períodos, XP por juego, ayudas, empates, privacidad, rangos y permisos/códigos. Diseñar migraciones y contrato versionado con pruebas de autorización. |
| PR-I2 — Rankings por juego | Registro idempotente de XP, agregados, top 50 paginado y posición propia fuera del top, sin insignia fuera de los primeros 50. Integrar por juego conforme exista motor seguro; prueba de empate/reintento/cierre de período. |
| PR-I3 — Insignias | Catálogo por juego/rango, posición actual y colección anual permanente. Mismo arte con año dinámico; cierre idempotente y coexistencia 2026/2027 sin duplicados. Mostrar todas las obtenidas agrupadas por año/juego. |
| PR-I4 — Perfiles y búsqueda de personas | Diseño sobrio, avatar, @usuario, vista propia/pública, buscador paginado por identidad pública, navegación desde rankings, todas las insignias vigentes y detalle accesible; preferencias de visibilidad y estados privados. Priorizar después compartir/reportar/bloquear antes del lanzamiento social. |
| PR-I5 — Instituciones y solicitudes | Directorio/búsqueda, perfil, logo editado solo por propietario, solicitudes de alumnos, bandeja/avisos y código institucional privado. Reutilizar aprobación P4-C, cuentas y grupos. Foto del profesor sin ranking de jugador. |
| PR-I6 — Ranking institucional | Aportes históricos por institución, suma por período, participantes activos y detalle público agregado. Probar cambios de institución y ausencia de doble conteo. |
| PR-I7 — Ensayo integral | Migraciones/despliegue coordinados con P5/D3, dos cuentas/dispositivos, imágenes, permisos, accesibilidad, red, clasificación y cierre anual. Simular cambio de año/reintentos conservando insignias anteriores. Solo cerrar con resultados reales. |

Orden propuesto: JN-2B/C y JN-4A demo implementados localmente; seguir JN-4B/C → MA-1/2/3 y añadir PR-I1–6 antes
del arte final de Sabi. PR-I1 y preparación de imágenes pueden adelantarse; PR-I2
depende de los motores seguros de los juegos y PR-I4/5 de archivos persistentes C5.
PR-I7 se coordina con P5, D3 y la prueba móvil. No sustituye seguridad, publicidad,
Billing, contenido ni publicación. El usuario puede priorizar PR-I1 como próxima
entrega; hasta esa decisión JN-4B sigue siendo el punto de reanudación.

## Rangos gráficos comunes (10 por familia, hasta el puesto 50)

| ID | Posiciones | Texto mostrado por la app | Acabado propuesto |
| --- | --- | --- | --- |
| top_01 | 1 | TOP 1 | Oro, corona grande y gema ámbar |
| top_02 | 2 | TOP 2 | Plata, corona y gema azul |
| top_03 | 3 | TOP 3 | Bronce, corona y gema coral |
| top_04 | 4 | TOP 4 | Amatista, rombo superior y laurel |
| top_05 | 5 | TOP 5 | Zafiro, estrella superior y laurel |
| top_06_10 | 6–10 | TOP 6–10 | Turquesa, doble borde |
| top_11_20 | 11–20 | TOP 11–20 | Conservar el diseño recibido de cada familia |
| top_21_30 | 21–30 | TOP 21–30 | Azul acero, borde facetado |
| top_31_40 | 31–40 | TOP 31–40 | Verde jade, borde simple |
| top_41_50 | 41–50 | TOP 41–50 | Violeta suave, borde simple |

La referencia agrupa 4–5; la petición nueva exige separarlos. No usar intervalos
superpuestos como 6–10 y 10–15. Ejemplo: top 43 usa top_41_50 y el detalle dice
«Puesto 43 de Tira y afloja · Global · temporada 2026 · XP confirmado».
Los colores son propuesta artística. Texto/forma identifican la categoría también.

## Prompts de imágenes

Uso: adjuntar la imagen maestra de Sabi y la referencia de medallas. Combinar el
prompt base + una ficha de juego + una variante de rango. Generar UNA insignia por
archivo, no un collage. Primero aprobar una muestra por juego; después producir
los otros rangos manteniendo composición/personaje. No hacen falta todas las imágenes
para comenzar: empezar por Trivia Rush y preparar las otras familias por etapas.
Nombres propuestos, no assets existentes: `badge_<familia>_<rango>.png`.
No generar un archivo nuevo por año: la app añadirá «2026», «2027», etc. sobre una
zona reservada. Mantener los mismos diseños entre temporadas. Preparar espacio
para TOP y año sin dibujar esos textos dentro de la imagen.

### BASE — pegar en cada solicitud

Diseña una única insignia de videojuego educativo SaberPlus, ilustración 2D pulida,
formas claras y volumen moderado. Usa las imágenes adjuntas como referencia: conserva
exactamente la identidad de Sabi, ajolote turquesa con branquias coral, ojos azul oscuro
y camiseta azul marino con el logo blanco S⁺. No cambies especie, proporciones ni
rostro entre versiones. Sigue la ficha de juego y el rango indicados abajo. Composición
centrada, silueta compacta, legible a 64–96 píxeles, contorno limpio y margen exterior
del 10 %. Exporta PNG cuadrado 1024×1024 con transparencia real. No fondo negro ni
tablero de transparencia dibujado, no escenario, no collage, no marcas de agua ni
efectos fuera del margen. Deja una placa inferior vacía y uniforme: la app añadirá
el TOP, el año y el nombre del juego con tipografía nítida. El único texto dibujado es S⁺
en la camiseta. Mantén el motivo del juego reconocible aun sin colores. Evita detalles
microscópicos, exceso de destellos y aspecto agresivo. Entrega solo la insignia.

### TR — Trivia Rush (`badge_trivia_rush_<rango>.png`)

Identidad TR: Sabi sujetando un cronómetro con una mano y un rayo luminoso con la
otra, gesto de concentración alegre. Medallón circular con dos aletas de rayo
laterales; pequeño símbolo de pregunta integrado arriba. Evoca rapidez de respuestas.
No cuerda, montañas, escudos ni estrellas atrapadas. Aplicar BASE y variante de rango.

### CI — Salto a la cima (`badge_summit_<rango>.png`)

Identidad CI: Sabi sobre tres plataformas escalonadas flotantes, alzando una pequeña
bandera de llegada. Marco triangular de cumbre redondeada, líneas ascendentes.
Evoca ascenso y progreso. No cronómetro ni rayo. Aplicar BASE y variante de rango.

### TA — Tira y afloja (`badge_tug_of_war_<rango>.png`)

Identidad TA: Sabi inclinándose hacia atrás y tirando de una cuerda gruesa con ambas
manos; al otro extremo una silueta rival pequeña y simplificada, sin crear otra
mascota principal. Cuerda tensa, nudo central y marco ovalado horizontal compacto.
Las manos sujetan realmente la cuerda; anatomía coherente y sin brazos adicionales.
Aplicar BASE y variante de rango.

### FA — Duelo fantasma (`badge_ghost_duel_<rango>.png`)

Identidad FA: Sabi abraza un pequeño fantasma blanco sonriente; el fantasma tiene
dos ojos oscuros y mejillas coral. Marco ovalado con una estela curva de persecución.
Evoca superar el récord personal, amistoso, sin terror. Aplicar BASE y variante.

### ME — Memoria (`badge_memory_<rango>.png`)

Identidad ME: Sabi muestra dos tarjetas iguales, cada una con un símbolo geométrico
simple idéntico. Marco cuadrado de esquinas redondeadas con dos tarjetas superpuestas.
Evoca encontrar parejas; no fórmulas ilegibles ni cronómetro. Aplicar BASE y variante.

### GU — Desafío del Guardián (`badge_guardian_<rango>.png`)

Identidad GU: Sabi sonriente junto a un pequeño guardián de piedra caricaturesco ya
vencido, postura de triunfo amistoso; guardián sentado con ojos espirales simples.
Marco de arco de piedra y gema central; sin heridas ni biblioteca/escudo protagonista.
Aplicar BASE y variante de rango.

### BA — Batallas asíncronas (`badge_async_battle_<rango>.png`)

Identidad BA: Sabi sostiene dos banderines cruzados con un símbolo VS geométrico
sin letras; dos destellos enfrentados completan el motivo de duelo estratégico.
Marco hexagonal y dos caminos convergentes. No cuerda ni fantasma. Aplicar BASE y variante.

### RE — Rescate de estrellas (`badge_star_rescue_<rango>.png`)

Identidad RE: Sabi libera con su mano una estrella dorada de una burbuja transparente;
otras dos estrellas unidas por una línea forman una pequeña constelación. Marco
circular con tres puntas estelares suaves. Aplicar BASE y variante de rango.

### ES — Escudo del conocimiento (`badge_knowledge_shield_<rango>.png`)

Identidad ES: Sabi sostiene un escudo azul frente a un libro abierto; dos pequeñas
gotas de tinta rebotan hacia afuera. Marco con forma de escudo, libro claramente
visible, actitud protectora. No guardián de piedra. Aplicar BASE y variante de rango.

### IN — Instituciones (`badge_institution_<rango>.png`)

Identidad IN: Sabi frente a un edificio educativo estilizado de tres columnas y un
libro abierto; tres pequeñas luces representan colaboración de estudiantes. Marco
de sello académico circular. No logo de una institución real ni nombres propios.
Es una insignia de clasificación colectiva, no un sello de verificación oficial.
Aplicar BASE y variante de rango.

### VARIANTE — añadir a cada combinación

Rango solicitado: [ID de la tabla]. Usa el acabado [copiar acabado de la tabla].
Conserva la pose, motivo y silueta de la muestra aprobada de esta familia. Los puestos
1, 2, 3, 4 y 5 son imágenes independientes. Reduce gradualmente ornamentos en rangos
inferiores, sin cambiar a Sabi. Placa inferior vacía; no dibujar cifras ni intervalos.
Nombre de entrega: [badge_familia_rango.png]. No generar los demás rangos en esta imagen.

Ejemplo completo de selección: BASE + TA + VARIANTE `top_41_50`, violeta suave
con borde simple, archivo `badge_tug_of_war_top_41_50.png`. La app compone «TOP 41–50»;
la posición 43 procede del servidor, nunca del dibujo. Transparencia y legibilidad
se verifican al importar: una imagen generada puede necesitar preparación adicional.
