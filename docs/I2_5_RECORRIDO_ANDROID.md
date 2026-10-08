# I2-5 — recorrido Android y acta de cierre

## Resultado del recorrido

### Revisión de criterios funcionales — 8 de octubre de 2026

La revisión separa aceptación funcional del lector de rankings de producción
y de la integración de los juegos. No se repitió la regresión PostgreSQL del
compañero ni se presenta como una ejecución nueva en este PC.

| Criterio | Evidencia y disposición |
| --- | --- |
| Integración local AppModule/auth/SQL/Flutter | Regresión PostgreSQL e integración HTTP registradas; recorrido Android confirmado por el propietario. Cumplido para el entorno local. |
| TOP 50, total y posición propia fuera del TOP | Android y contrato/lector documentados; 61 participantes y propio 51, después 1 tras corrección del fixture. Cumplido sin afirmar partidas reales. |
| Estados y filtros coherentes | Android, tests de respuestas tardías, vacíos y NO_DISPONIBLE. Cumplido; latencia física deliberada no ejecutada. |
| Roles, errores y privacidad | Android teacher/red y pruebas HTTP de guards reales, tokens y ADMIN. Cumplido por evidencia combinada; no prueba toda la seguridad productiva. |
| Compatibilidad legacy y admisión OFF | Regresión de ranking general dirigida; Android solo vacío. Harness sin admisión competitiva. Cumplido para lectura, no activación de juegos. |
| Regresión dirigida del 8 de octubre | Flutter ranking 66/66; backend ranking 43/43, dos suites. Pruebas unitarias/widgets y HTTP con dependencias dobles, no nueva regresión SQL. |

Criterios funcionales revisados y recorrido físico completado. El cierre operativo
mantiene seguimiento de limpieza de sesiones antiguas y de la sesión académica
actual; QA-1 conserva lint/intermitencias y versión de herramientas. Estos
pendientes no se dan por resueltos ni se convierten en una repetición del recorrido.
El propietario autorizó continuar: empieza [IC-1A, cliente Cima](IC1_CIMA.md)
localmente, sin cerrar IC-1 ni desplegar/activar competición.

El ensayo académico del 8 también confirmó edición manual en navegador y
versiones de preguntas: ver [acta separada](ENSAYO_ACADEMICO_LOCAL.md). Esa
comprobación no equivale a acceso visual de ADMIN al ranking competitivo.

### Resultado registrado el 7 de octubre (antecedente de la revisión superior)

Recorrido funcional local confirmado por el propietario en Android 15. No se
encontraron defectos funcionales en los casos observados. No equivale a aprobar
producción ni toda la seguridad. ADMIN se verificó por HTTP, no por pantalla;
ranking general solo vacío; token anterior rechazado por nueva clave de ensayo,
no revocación individual ni expiración por reloj. No se inyectó latencia manual.
Quedan deuda QA-1 y revisión final de criterios de I2-5; no declarar todo el
proyecto aprobado. Los registros iniciales inferiores son antecedentes.

## Reanudación posterior del 7 de octubre

Android 15, modelo 24117RN76L, detectado por USB. API temporal preparada con
61 migraciones; auth/ranking Flutter contra API real 6/6 y panel HTTP 2/2.
APK debug generada (381.365.759 bytes); paquete inspeccionado con aapt:
`com.example.saber_plus.i2validation`, separado de la instalación habitual.
El sufijo Gradle temporal se retiró después; sin diferencias funcionales retenidas.

Tras reiniciar/reanudar el PC, la API anterior ya no estaba activa. Se preparó
otra instancia aislada con 61 migraciones y se repitió auth/ranking: 6/6.
La instalación USB terminó con exit 1 y ADB pasó a no detectar dispositivos.
No hubo Success ni prueba física; no atribuirlo a la app o dar por instalada.
Pendiente reconectar Android y reintentar solo la instalación, sin recompilar.
API de ensayo con límite de dos horas; verificar su disponibilidad antes de
retomar. La instancia detenida anterior requiere verificar propiedad y limpieza.
No se imprimieron secretos ni se alteró la app habitual deliberadamente.

La matriz manual inferior registra el progreso posterior. Los resultados HTTP
no sustituyen la observación física del propietario.

Reintento tras reconectar USB: `adb install --no-streaming -r` terminó con
`Success`, transferencia de 381.365.759 bytes en 12,105 s. Se lanzó la actividad
`com.example.saber_plus.i2validation/com.example.saber_plus.MainActivity`.
Instalación confirmada; observaciones posteriores registradas en la matriz.

## Antecedente: preparación inicial del 7 de octubre de 2026

Base Flutter `c2b9b54`, backend `b122d91`, main y árboles limpios al iniciar.
`adb devices -l` no encontró dispositivos. No había listener local en 43187.
**Recorrido físico NO EJECUTADO; I2-5 permanece abierto.** No se inició una API,
no se compiló/instaló una APK ni se usaron servicios o credenciales remotas.

Backend: tres ejecuciones normales consecutivas del panel pasaron 88/88 cada
una (1,568 s, 1,463 s y 1,388 s aproximadamente). No se cambió concurrencia,
timeouts ni aserciones. No reproduce el fallo del otro PC ni demuestra su causa.
Lint sin fix confirmó 603 errores/150 avisos; clasificación en el otro repo:
`backend/docs/I2_5_SEGUIMIENTO_2026_10_07.md`.

## Antes de comenzar

1. Conectar/desbloquear Android, activar depuración USB y aceptar autorización.
2. Acordar el PC que alojará la API aislada. El entorno anterior del compañero
   fue temporal; no asumir que siga disponible ni reutilizar credenciales antiguas.
3. Usar el procedimiento existente `backend/tool/LOCAL_RANKING_VALIDATION.md`
   solo cuando el entorno esté disponible y su preparación acordada. No apuntar
   el ensayo a Supabase/producción ni habilitar flags competitivos reales.
4. Confirmar API sana, cuentas ficticias y dataset de temporada del ensayo.
   No basta ejecutar Flutter en demo para cerrar esta integración.
5. Registrar modelo, Android, versiones de herramientas, commits y defines no
   secretos. Preferir paquete debug separado para preservar instalación/datos.
   No compilar credenciales de login dentro de la APK.

## Matriz manual — resultados confirmados por el propietario

| Caso | Resultado esperado | Estado/evidencia |
| --- | --- | --- |
| Login estudiante | Sesión real contra API local, sin fallback demo | CONFIRMADO por el propietario el 7 de octubre; sin captura independiente |
| Trivia de temporada del ensayo | TOP 50, total 61, propio 51/100 XP antes de corrección del fixture | Propietario confirma 61 participantes, última fila TOP 50 y propio 51/100 XP aparte |
| Juego/año | Filtros conservan ámbito; respuesta tardía no sustituye selección actual | Propietario confirma años y cambios rápidos entre Trivia/Cima/Memoria sin mezcla visible; no se inyectó latencia deliberada |
| Sin resultados | Cima/año vacío muestran estado vacío, no error ni personas ficticias | Cima y Trivia 2025 vacíos confirmados por propietario |
| No disponible | Memoria/Batallas identificadas como no disponibles, no como ranking vacío | Ambos confirmados por propietario |
| Cero XP/sin balance | Sin posición propia inventada; lista sigue accesible | Propietario confirma zero y absent: 61 participantes, sin posición propia ni XP de la cuenta previa |
| Privacidad | Alias público y datos permitidos; sin correo, nombre privado o IDs internos | Propietario confirma presentación esperada de alias/posición/XP sin datos privados; contrato HTTP probado por separado |
| Cuenta no elegible | No exponer ranking a profesor/ADMIN; respetar restricciones de navegación/API | Propietario confirma teacher: pantalla institucional sin ranking competitivo; retorno a student con ranking correcto. ADMIN cubierto por HTTP, no recorrido físico |
| Sesión inválida | Tratamiento de acceso expirado sin reutilizar datos de otra cuenta | Nueva API aislada con nueva clave JWT: propietario confirma cierre de sesión anterior y nuevo login student correcto (61 participantes, propio 51/100 XP). Verifica rechazo de token anterior, no expiración por reloj ni revocación individual |
| Red/reintento | Error comprensible; recuperar conexión y reintentar sin duplicación | Propietario confirma error al retirar reverse USB y recuperación posterior al restaurarlo |
| Corrección interna del fixture | Tras corrección autorizada en el ensayo y recarga: propio 1/2100 XP; no desde Flutter | Supervisor y propietario confirman puesto 1/2100 XP, total 61; persiste al volver de 2025 a 2026 |
| Pantalla/teclado | Texto grande, teclado y desplazamiento sin desbordar u ocultar controles | Propietario confirma texto grande, filtros, teclado del año, cierre y uso posterior sin controles inaccesibles |
| Ciclo de vida | Fondo/retorno y navegación conservan coherencia; sin sesión ajena | Propietario confirma salir al inicio sin cerrar proceso, volver y usar filtros/actualización |
| Ranking general | Sigue funcionando separado del competitivo | Propietario confirma 0 participantes y «Todavía no hay XP confirmado en este periodo»; estado vacío, lista poblada no ensayada físicamente |

Por cada caso: observador, pasos, resultado, evidencia sin datos privados y fallo
si lo hubo. No reemplazar esta columna por resultados unitarios/HTTP existentes.
No alterar fecha del teléfono/producción para simular temporada.

## Cierre y límites

Supervisor confirmó cierre de API y retirada de PostgreSQL/directorio de la
última sesión; enlace USB 43187 retirado. Se conserva APK/instalación de prueba:
ya no dispone de API y sus credenciales eran temporales; app habitual intacta.
No se borraron imágenes o cachés globales. Limpieza adicional de carpetas antiguas
`saberplus-i2-local-C7O8Jo` y `saberplus-i2-local-fR2dnQ` en TEMP bloqueada por
política de ejecución: permanecen pendientes, con credenciales ficticias locales.
No se intentó eludir la restricción. No publicar esos directorios.

Restaurar tamaño de texto y ajustes cambiados, retirar solo conexión USB de ensayo
y recursos propios según procedimiento, preservar datos personales. Registrar
limpieza y pendientes. Revisión de todos los criterios antes de declarar I2-5 cerrado.
No cierra audio/juegos físicos, iOS, IC-1/2/3, P5/D3 ni despliegue productivo.
