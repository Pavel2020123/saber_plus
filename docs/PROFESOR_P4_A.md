# Profesor P4-A — base del tiempo y evolución

Nota posterior: [P4-B](PROFESOR_P4_B.md) ya integra Flutter localmente. El contenido
de esta entrega conserva su contexto histórico; sigue P5, no otra implementación
de P4-B. Para el estado actual de `git add -p`, consultar la guía P4-B y el diff.

Entrega local del 14 de septiembre de 2026. **P4-A implementada en el backend;
sigue P4-B: sincronización y pantallas Flutter**. P5 y D3 permanecen pendientes.
No se modificó código Dart: la app aún muestra su contador local anterior.

## Qué quedó preparado

- Persistencia privada de Pomodoros completados de 25 minutos.
- Subida de lotes con identidad de sesión, IDs estables, confirmación, atomicidad,
  protección ante reintentos y bloques superpuestos (también concurrentes).
- Resumen propio y docente por 7/30/90 días, con permisos y plan del alcance P2.
- Tiempo de evaluaciones reutilizado desde historial confirmado, sin subirlo otra
  vez desde Flutter. Pomodoro separado: puede funcionar mientras se responde.
- Días colombianos, aciertos/errores descriptivos, tiempo ausente distinguido de
  cero y muestra parcial explícita. No se infiere dominio ni se concede XP.

El contrato detallado, migración y límites están en
`C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend\PROFESOR_P4_A.md`.

## Decisiones obligatorias para P4-B

1. Conservar `StudyTimeRepository`/Drift y sus registros locales. Añadir cola y
   confirmaciones por usuario; no borrar el historial local al sincronizar.
2. Subir solo Pomodoros. No reenviar tiempos de prácticas, simulacros o diagnóstico:
   su historial ya existe en el servidor. Los IDs actuales `pomodoro:<timestamp>`
   son admitidos; para nuevos bloques se puede adoptar UUID v4 estable.
3. Retener el mismo ID, fecha UTC/milisegundos y cuerpo tras timeout/desconexión.
   Confirmar exactamente los eventos que reconozca la API; no marcar todo como
   enviado cuando un lote devuelve error. Cancelar/aislar por cambio de cuenta.
4. Mostrar pendientes/conflictos, fechas futuras y bloques anteriores a 90 días
   como situaciones distintas. No regenerar IDs o ajustar fechas para forzar una
   subida. Ante conflicto atómico, aislar los eventos y permitir revisar la causa.
5. No subir automáticamente datos demo. No importar indiscriminadamente todo el
   contador histórico local. La demo conserva su repositorio aislado en memoria.
6. Adaptar Tiempo estudiado y la ficha docente al resumen remoto: mostrar fuentes
   separadas, sin sumarlas como tiempo único. Indicar «tiempo registrado», no
   atención verificada. El contador actual puede incluir pausas de preguntas o
   Pomodoro en segundo plano; no prometer medición de atención que no existe.
7. Navegación desde la ficha P2, fechas 7/30/90 y evolución con cantidad de datos.
   Cero registros no prueba inactividad; porcentaje null no se convierte en 0 %.
   `parcial:true` exige aviso y no permite conclusiones a partir de días vacíos.
8. Pruebas de repositorio/modelos/cola, cambio de cuenta, reintentos, reconexión,
   permisos, gráficos/tabla accesibles, pantalla estrecha y texto ampliado.

No rehacer diagnóstico, grupos, prioridades o calificación. Lecturas/pantallas
abiertas y juegos todavía no aportan tiempo en este contrato. No añade tutores.

## Verificación

Pruebas PostgreSQL temporal: 11 aprobadas. La instancia desechable fue cerrada
y eliminada por su ejecutor, sin tocar Supabase ni PostgreSQL habitual.
Backend completo: 769 pruebas aprobadas en 74 suites. Las 58 pruebas enfocadas
en tiempo/evolución y alcance P2 también pasaron. Compilación y lint sin errores.
No se ejecutó Flutter: en este repositorio solo cambió documentación.

Las pruebas usan el árbol local, con cambios previos de Guardián conservados.
El HEAD del backend referencia `IntentoGuardian`, mientras su modelo completo y
otros archivos todavía están sin commit: revisar esa entrega por separado antes
de desplegar. No se afirma reproducibilidad de un checkout limpio en este turno.

## Commits y rutas

Backend: seleccionar solo los dos bloques de Pomodoro del esquema. En
`git add -p`, responder `y` para `pomodorosRegistrados` y `model PomodoroRegistrado`;
responder `n` para `model IntentoGuardian`. Revisar lo preparado antes del commit.
No usar `git add .` ni añadir todas las migraciones indiscriminadamente.

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add -p backend/prisma/schema.prisma
git add backend/PROFESOR_P4_A.md backend/prisma/migrations/20260914090000_study_time_pomodoros backend/src/institucion/study-time*.ts backend/src/institucion/institucion.module.ts backend/src/institucion/student-evidence.service.ts backend/test/study-time-postgres.test.cjs backend/tool/test_editorial_postgres.mjs
git diff --cached --stat
git commit -m "feat: preparar API de tiempo estudiado y evolucion P4-A"
```

Flutter (solo documentación):

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ETAPAS_PENDIENTES.md docs/ROADMAP_MOVIL.md docs/PROFESOR_P4_A.md
git commit -m "docs: registrar entrega P4-A y siguiente integracion Flutter"
```

No se hicieron commits, push, despliegues o migraciones reales automáticamente.
