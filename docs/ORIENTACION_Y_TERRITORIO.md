# Orientación por intereses y filtros territoriales

Plan acordado el 5 de octubre de 2026. Solo planificación, no implementado.
No desplaza I2-5 ni modifica reglas de XP, insignias o admisión competitiva.

## PR-I5-T — Ubicación y directorio institucional

Extiende PR-I5, que ya contemplaba buscar por ciudad/departamento.
- Ubicación institucional: departamento y municipio/distrito mediante catálogo
  oficial DIVIPOLA del DANE, con códigos como texto, fuente y versión. No texto
  libre como identificador; tratar Bogotá D.C. y territorios especiales según el
  catálogo, sin inventar correspondencias.
- Selectores dependientes: departamento → municipio. Ejemplo de recorrido:
  Amazonas → Leticia. Cambiar departamento limpia el municipio incompatible.
- Buscar por nombre y filtrar por departamento, municipio y tipo; filtros
  opcionales, opción Todos, paginación, resultados vacíos y selección visible.
- Solo instituciones aprobadas/activas en el directorio. Ubicación no equivale
  a aprobación; el propietario declara y ADMIN verifica/corrige con auditoría.
- Migrar registros anteriores sin adivinar ubicación desde nombres ambiguos:
  conservar texto previo y marcar pendiente de clasificación.
- Definir sede representada por cada institución antes de abordar multisede;
  no duplicar instituciones automáticamente. No pedir GPS ni domicilio estudiantil.

## PR-I6-T — Filtros del ranking institucional

Depende de PR-I5-T y PR-I6. Vistas nacional, departamento y municipio con
temporada, filtros y cantidad de participantes visibles. El servidor aplica
filtros antes de ordenar/paginar y calcular la posición en ese ámbito.
Filtrar no cambia XP ni traslada aportes históricos. Distinguir posición nacional
y territorial; no convertir una insignia nacional en regional ni crear premios
territoriales sin aprobación. Probar reinicio de paginación y respuestas tardías.

Alcance inicial: instituciones, no geolocalización pública de estudiantes.
Antes de implementar: cerrar cómo se fija la ubicación de una temporada cuando
una institución cambia de sede (propuesta: instantánea anual auditada), además
del tratamiento de instituciones multisede y sin ubicación validada.

## OV-1 — Explora tus intereses con Sabi

Nueva ampliación del módulo de orientación académica existente. Ese módulo hoy
relaciona desempeño con familias de carrera; no es un test de intereses.
Se presentan ambos resultados separados: dificultad académica no implica falta
de vocación, y preferencia no demuestra competencia ni garantiza admisión.

### OV-1A — Contenido y reglas

Propuesta inicial por validar: 24–30 preguntas sobre actividades e intereses,
5–8 minutos, respuestas graduadas más opción No sé. Introducción opcional:
¿Ya tienes pensado qué estudiar? No condicionar resultado a popularidad,
capacidad de pago, género o una sola respuesta.

Diseñar preguntas propias y reglas transparentes/versionadas por familias.
No copiar instrumentos protegidos ni llamar validado científicamente al test
sin evidencia. Revisión de contenido por alguien cualificado antes de publicar;
esto no añade tutores ni asesoría en vivo a la app. No diagnosticar personalidad.

### OV-1B — Contrato y persistencia privada

Cuestionario y versión de reglas, respuestas y resultado vinculados a la cuenta;
autorización, recuperación, eliminación y retención definida. Resultados sin XP,
sin ranking, sin certificado ni recompensa por responder de cierta forma.
No publicar ni compartir automáticamente con profesores/instituciones y nunca
usar intereses/resultados para segmentación publicitaria. Permitir repetir y
entender cambios sin sobrescribir silenciosamente el historial.

### OV-1C — Experiencia móvil

Progreso, volver/corregir respuestas, guardar y continuar. Al terminar, mostrar
2–3 familias afines, motivos basados en respuestas, varias carreras para explorar
y siguientes pasos; no «debes estudiar medicina» ni porcentajes de certeza.
Si faltan respuestas o no hay una tendencia clara, decirlo y permitir explorar
sin forzar una carrera. Incluir vías técnicas, tecnológicas y universitarias.
Catálogo de programas y enlaces oficiales separados de la puntuación del test.

### OV-1D — Sabi, accesibilidad y validación

Ilustraciones estáticas primero; animaciones quedan en UI-F/Sabi. Conservar
ajolote turquesa, branquias coral, proporciones y emblema S+ visible en camiseta,
bata o prenda exterior. Sin logos ajenos, texto incrustado ni estereotipos.
Pruebas de empates, respuesta incompleta, reanudación, permisos, texto grande y
explicaciones. Piloto antes de publicar; no certificar validez por pasar tests de código.

Colección artística propuesta (no ranking estadístico de matrículas):

| ID | Carrera / familia | Sabi |
|---|---|---|
| sabi_medicina | Medicina | Bata, estetoscopio, S+ visible |
| sabi_enfermeria | Enfermería | Uniforme clínico y libreta de cuidados |
| sabi_psicologia | Psicología | Cuaderno y gesto de escucha |
| sabi_derecho | Derecho | Traje y libro jurídico, sin mazo de juez |
| sabi_sistemas | Ingeniería de sistemas/software | Portátil y símbolos de código |
| sabi_industrial | Ingeniería industrial | Casco y esquema de procesos |
| sabi_civil | Ingeniería civil | Casco, plano y maqueta de puente |
| sabi_administracion | Administración | Tablero de organización de un proyecto |
| sabi_contaduria | Contaduría | Calculadora y libro de cuentas |
| sabi_educacion | Educación/licenciaturas | Libro y pizarra |
| sabi_diseno | Diseño/comunicación visual | Tableta gráfica y lápiz |
| sabi_ambiental_agro | Ambiental/agropecuaria | Planta y libreta de campo |

Empezar por estas 12 ilustraciones; son una propuesta equilibrada, no un límite
para carreras del catálogo. Ampliar después a arquitectura, veterinaria,
comunicación y otras según contenido revisado. Priorizar por matrícula solo tras
analizar SNIES con año, nivel y métrica explícitos; no confundir matriculados,
nuevos ingresos, graduados o demanda laboral.

## Orden y fuentes

- I2-5 mantiene prioridad. PR-I5-T se integra en PR-I5; PR-I6-T en PR-I6.
- OV-1 puede desarrollarse como entrega independiente después del bloque
  competitivo/social, antes de UI-F y de la beta. No exige terminar ilustraciones
  para diseñar el contenido, pero sí revisión antes de publicar recomendaciones.
- [DANE — DIVIPOLA](https://www.dane.gov.co/index.php/component/content/article/488-division-polistico-administrativa?Itemid=5039&catid=72): catálogo territorial.
- [MEN — Descubre Tú](https://www.mineducacion.gov.co/1759/w3-printer-358122.html): antecedente de orientación basada en intereses, expectativas y aptitudes; no es validación de nuestro cuestionario.
- [SNIES — bases consolidadas](https://snies.mineducacion.gov.co/portal/ESTADISTICAS/Bases-consolidadas/): fuente para verificar oferta/matrícula antes de afirmar qué carreras son las más estudiadas.

Fuentes consultadas el 5 de octubre de 2026. Sus catálogos deberán actualizarse
antes de la implementación; no se descargaron ni importaron bases en esta entrega.
