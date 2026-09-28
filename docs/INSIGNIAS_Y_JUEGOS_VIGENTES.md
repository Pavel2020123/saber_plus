# Insignias y juegos vigentes — 27 de septiembre de 2026

Decisión del propietario: integrar las insignias entregadas y retirar los juegos
para los que no preparó insignias. Inventario: 90 PNG, diez por familia.

| Familia | Imágenes | Estado |
|---|---:|---|
| Trivia Rush | 10 | Se conserva |
| Duelo fantasma | 10 | Se conserva |
| Salto a la cima | 10 | Se conserva |
| Tira y afloja | 10 | Se conserva |
| Guardián | 10 | Se conserva, catálogo añadido |
| Memoria | 10 | Se conserva, catálogo añadido |
| Batallas | 10 | Se conserva, catálogo añadido |
| Rescate de estrellas | 10 | Se conserva, catálogo añadido |
| Instituciones | 10 | Colección institucional añadida; no es otro juego |

Total: **ocho juegos y una colección institucional**. Las cinco familias nuevas se
declaran en pubspec y en el catálogo. No se mueven ni regeneran los originales;
se respeta el prefijo recibido `intituciones`. Los archivos heredados `top6-11`
siguen correspondiendo al rango 6–10. Puestos 1–5 individuales, después 6–10,
11–20, 21–30, 31–40, 41–50, sin solapamientos.

Acceso: Mi perfil académico → Insignias de Sabi (también desde ranking).
Son diseños disponibles, NO insignias ganadas. Asignación verificada, ranking
por juego y colección anual permanente siguen pendientes de PR-I1–4. No se
inventan premios ni se entrega una insignia institucional a un jugador.

## JN-4 — Escudo del conocimiento retirado

Único juego activo sin una familia de insignias. Se elimina su código Flutter,
ruta, acceso desde Practicar y pruebas exclusivas del motor. Se retira módulo,
controlador y servicio del juego en backend, junto con pruebas/runner exclusivos.
Las cinco rutas antiguas responden HTTP 410 mediante un controlador mínimo sin
servicios ni acceso a base. Así las apps antiguas no crean ni continúan partidas.

La migración histórica y el modelo Prisma se conservan como historial legado;
no se borra una tabla ni se reescribe una migración ya versionada. No hubo limpieza
de partidas reales ni de almacenamiento de dispositivos. El código eliminado se
puede recuperar desde Git; no debe reactivarse sin nueva decisión del propietario.
Retiro operativo en Render requiere desplegar esta versión, aún pendiente.

JN-3 Taller de inventos también sigue cancelado. No confundir Escudo del
conocimiento con el potenciador escudo de combo de Trivia o las mecánicas de Guardián:
esas funciones pertenecen a juegos conservados y no se retiran.

Las descripciones previas de JN-4 son historia, no tareas futuras. La siguiente
entrega funcional es **PR-I1 — Reglas y contratos competitivos**;
MA-2A/B/C y MA-3A/B/C implementadas localmente al 28 de septiembre.
P5/D3, despliegue, asignación anual y animaciones finales siguen pendientes.

## Verificación

Se comprueba existencia, empaquetado y decodificación de los 90 assets, cobertura
de posiciones 1–50, cambio de familia/detalle y ausencia de ruta/entrada de Escudo.
Backend verifica por HTTP que todas las rutas retiradas rechacen GET/POST con 410
sin necesitar Prisma. Pruebas retiradas de Escudo ya no forman parte del total:
comparar resultados por alcance, no esperar el mismo contador de pruebas anterior.
Falta revisión en celular; se conservan imágenes originales sin optimizar todavía.

Resultado local: Flutter analyze sin incidencias; 43 pruebas Flutter seleccionadas
(catálogo y navegación) aprobadas; backend build aprobado, ESLint del controlador
de retiro sin avisos y 837 pruebas en 83 suites aprobadas. No hubo despliegue.
