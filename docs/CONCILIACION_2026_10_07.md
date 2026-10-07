# Conciliación documental — 7 de octubre de 2026

## Autoridad y alcance

La fuente única del orden de trabajo es [ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md).
Este documento registra evidencia y decisiones de la conciliación, no otra ruta.
Los contratos técnicos conservan autoridad sobre su módulo; una discrepancia con
el código requiere revisión, no cambiar reglas silenciosamente. Los informes
fechados conservan sus resultados originales, incluso fallos y pruebas omitidas.

Repositorios locales comprobados: Flutter `main` en `64ade5a`, backend `main` en
`cb14338`, antes de esta edición documental. Son referencias de auditoría, no
instrucciones para volver a esos commits. Ambos árboles estaban limpios.

## Evidencia y pendientes reales

| Evidencia | Resultado y alcance |
| --- | --- |
| Informe del compañero, 6 de octubre | PostgreSQL competitivo 347/347, otros nueve modos 102; Jest 1.258; Flutter 694 aprobadas y 9 opt-in omitidas. Se revisó el informe y su evidencia, no se repitieron todas esas suites el día 7. |
| Integración local del compañero | Auth/ranking HTTP 6/6 y repetición corregida 5/5; panel HTTP 2/2. Cuentas, rivales y resultados sintéticos; no partidas físicas completas. |
| Android | APK debug compilada e instalada; recorrido humano incompleto. No certifica audio, juegos, red ni iOS. |
| Panel reejecutado en el PC de Pavel, día 7 | `npm run check`: 22 módulos; `npm test`: 88/88 con concurrencia normal. El fallo del otro PC no se reprodujo; su causa no está confirmada ni se declara corregida. |
| Producción reejecutada, día 7 | `npm audit --omit=dev`: 0 vulnerabilidades. `cb14338` actualizó proxy-addr 2.0.7 a 2.0.8. No equivale a una auditoría completa de seguridad ni acredita CI remoto. |
| Lint sin modificación, día 7 | ESLint sobre `{src,apps,libs,test}/**/*.ts`: 603 errores y 150 avisos. Incluye formato y tipado; no son 603 fallos funcionales demostrados. El informe del día 6 tenía 567 errores. No se atribuye la diferencia al compañero sin diagnóstico. |
| Certificados | Siete muestras PDF: cinco áreas, curso y nombre largo. Solo seis tipos; no se inspeccionaron visualmente todos los PDF ni se completó descarga física. |

Host de Pavel: Node 24.11.1/npm 11.6.2 frente a 24.14.1/11.11.0 fijados por
el backend. Registrar/alinear herramientas antes de comparar resultados entre
equipos. El informe anterior no se modifica para fingir una nueva ejecución.
No se fija un porcentaje de finalización ni una fecha de lanzamiento sin una
estimación por entregas, dependencias, responsables y disponibilidad.

## Cierre de I2-5

- Aprovechar la regresión ya documentada; repetir suites cuando cambie su código
  o falte evidencia, no declarar pendiente toda la regresión PostgreSQL.
- Completar en Android sesión, TOP 50, puesto propio, filtros rápidos, vacío/no
  disponible, privacidad, errores/reintento, teclado, texto grande y fondo/retorno.
- Registrar entorno, commit y resultados; conservar fallos aunque una repetición pase.
- Diagnosticar la intermitencia del panel y clasificar lint/dependencias de desarrollo.
  Si se propone una línea base de deuda, debe ser explícita, revisada y no esconder
  nuevos errores ni desactivar comprobaciones. No arreglar cientos de archivos en lote.
- Revisar cada criterio de `backend/docs/PR_I2_RANKINGS.md` en el otro repositorio.
  I2-5 valida consulta/integración de ranking, no concede autorización productiva.

## Organización posterior

Se asignan identificadores **IC-1, IC-2 e IC-3** a los pendientes ya reconocidos:
clientes Flutter de los seis juegos, Memoria competitiva y Batallas competitivas.
Su alcance y aceptación están en la tabla del roadmap. No reabren PR-I1 ni
renombran I2-5. Implementación y activación son etapas diferentes.
PR-I3 puede diseñarse contra el contrato común; los premios reales de cada juego
requieren integración verificada y cierre anual autorizado. Arte no es premio.

## Colaboración y mantenimiento

- El propietario ha elegido trabajar en `main`. Revisar estado y diferencias,
  coordinar archivos, preservar trabajo ajeno y entregar commits pequeños por repo.
  Rama/PR puede acordarse para trabajo simultáneo; no imponerlo como regla vigente.
- No hacer commit, push, merge, migraciones, despliegues ni activar servicios sin
  petición/autorización correspondiente. Tener commits publicados no es autorización
  permanente para publicar las entregas siguientes.
- Visibilidad y protección de GitHub: no verificadas en esta conciliación local.
  No afirmar que los repos son privados/públicos ni cambiar visibilidad. Nunca subir
  secretos; revisar historial si se decide cambiar acceso, sin reescribirlo automáticamente.
- QA-1 añade CI Flutter (dependencias con lock, analyze y pruebas); no está implementada.
- DOC-1 revisará artefactos temporales y archivo accidental de la raíz. El pitch PDF
  puede ser un entregable deliberado: no borrar ni ignorar todo `output/` sin clasificarlo.
- Cada entrega actualiza el estado superior del roadmap y los accesos de README/relevo.
  Los informes históricos se enlazan como evidencia, no se copian como estado actual.

## Entrega de esta conciliación

Solo documentación en ambos repositorios. No cambia código, dependencias,
migraciones, recursos visuales, reglas competitivas ni servicios remotos.
Verificación de esta entrega: 18 documentos modificados/nuevos entre ambos
repositorios, 470 enlaces locales a archivos comprobados, ninguno ausente;
`git diff --check` correcto en ambos. Esta comprobación no valida destinos web
ni todas las anclas internas. Los comandos funcionales arriba corresponden a
la auditoría previa del día 7, no a nuevas ejecuciones por editar Markdown.
