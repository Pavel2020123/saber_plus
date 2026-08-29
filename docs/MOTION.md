# Movimiento y transiciones

SaberPlus utiliza una transición común al abrir pantallas secundarias: un desplazamiento horizontal corto acompañado por un fundido suave.

## Parámetros

- Entrada: 260 milisegundos con curva de desaceleración.
- Regreso: 210 milisegundos con curva de aceleración.
- Desplazamiento inicial: 4,5 % del ancho de la pantalla.
- Opacidad inicial: 65 %.

Estos valores hacen visible el cambio de contexto sin retrasar el acceso al contenido ni usar movimientos llamativos durante una sesión académica.

## Dónde se aplica

La transición se usa en autenticación y en las rutas secundarias de diagnóstico, estudio, práctica, progreso, favoritos, gamificación, sincronización y preferencias.

Los cambios entre las cinco secciones de la barra inferior no se animan. Mantener esas raíces con `NoTransitionPage` evita desplazar toda la aplicación cuando el estudiante cambia de sección.

## Accesibilidad

`SaberPageTransition` consulta `MediaQuery.disableAnimationsOf`. Si Android o iOS indican que el usuario prefiere reducir movimiento, se entrega la pantalla directamente, sin fundido ni desplazamiento.

El sistema está centralizado en `lib/app/page_transitions.dart`; las nuevas rutas secundarias deben usar el constructor `_animatedRoute` del enrutador para conservar el mismo comportamiento.

## Sonido y vibración

La Etapa 6C-G incorpora un sonido de éxito y una vibración corta al confirmar una racha de tres o más aciertos. Ambos pueden configurarse por separado; el detalle está en `ANSWER_STREAK_FEEDBACK.md`.
