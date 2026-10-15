# OV-1 — Orientación vocacional

## Alcance de esta actualización — 14 de octubre de 2026

Se registra una **decisión de UX y contenido**, pendiente de implementación.
Según el contexto aportado por el propietario, OV-1 ya cuenta con familias
vocacionales y reglas de resultado definidas. Esta entrega no modifica esas
reglas ni acredita su revisión técnica: esta copia aún no contenía el acta
OV1_ORIENTACION.md ni los cambios del frente del compañero.

Este documento inicia únicamente el registro de la decisión visual. Al integrar
el trabajo de OV-1, conservar sus contratos y reglas existentes y añadir esta
sección a su acta; no sustituirlos por una nueva lógica de orientación.
Ver [checkpoint OV-1](CHECKPOINT_OV1.md) y
[contrato y antecedentes de orientación](ORIENTACION_Y_TERRITORIO.md#ov-1--explora-tus-intereses-con-sabi).

## Presentación visual del resultado con Sabi

Cuando el estudiante termine el cuestionario y reciba su resultado principal,
este podrá mostrarse acompañado de una ilustración temática de Sabi acorde
con la **familia vocacional dominante indicada por las reglas de OV-1**.

La primera versión se organiza **por familias vocacionales, no por cada carrera**.
Se contemplan estas seis variantes visuales, todavía sin assets finales:

| Familia vocacional | Dirección visual de Sabi |
|---|---|
| Tecnología e ingeniería | Estética de ingeniería/tecnología. |
| Salud y ciencias de la vida | Bata médica o científica. |
| Sociedad, derecho y comunicación | Apariencia formal/comunicativa. |
| Negocios, organización y emprendimiento | Apariencia ejecutiva o emprendedora. |
| Educación, humanidades e idiomas | Apariencia docente/académica. |
| Creatividad, diseño y entorno | Apariencia artística/creativa. |

La ilustración transmite celebración o acompañamiento positivo del resultado,
sin presentar una familia como superior a otra. Mantener la identidad de Sabi:
ajolote turquesa, branquias coral y emblema S+ visible, con estilo consistente
y sin estereotipos de género o de profesión.

El resultado se comunica como **orientación exploratoria de intereses**, no como
diagnóstico profesional, prueba de aptitud ni instrucción de qué carrera elegir.
La imagen acompaña el texto explicativo; no sustituye motivos, familias afines
y carreras para explorar. No comunica porcentajes de certeza inventados.

La elección visual debe consumir el resultado vocacional ya calculado. No crea
otra puntuación ni modifica la resolución de empates. Si no hay una familia
dominante definida, la presentación se acordará después sin forzar una ganadora.
La lógica vocacional permanece separada del sistema académico y **no genera XP,
ranking ni certificados**; tampoco cambia la privacidad de los resultados.

Más adelante podrá evaluarse una ampliación por carreras específicas. Esa
ampliación queda **fuera del alcance actual**. La colección previa por profesiones
se conserva como antecedente, no como requisito de doce imágenes para esta versión.

## Estado y exclusiones de esta entrega

**Requisito visual pendiente para la fase posterior de diseño/UI**, coordinado
con OV-1D y UI-F una vez consolidados el cuestionario y la interfaz de resultados.
Hoy solo se documenta: no se generan imágenes, no se cargan assets finales,
no se implementa renderizado productivo ni se hacen cambios grandes de UI.
Tampoco se añade lógica productiva compleja ni nuevas dependencias.

Esta decisión documental **no requiere Docker ni pruebas Android**. No se
declaran pruebas funcionales ejecutadas o ilustraciones disponibles por registrarla.

## Pendiente exacto para implementación futura

1. Aprobar el diseño de las seis ilustraciones, su estilo, composición,
   dimensiones, formato, transparencia y procedencia/licencia.
2. Definir los nombres de archivos y el inventario definitivo de assets. No
   considerar las etiquetas de familia como identificadores técnicos ya aprobados.
3. Acordar el mapeo entre los identificadores reales del resultado de OV-1 y cada
   variante, reutilizando el contrato existente sin cambiar sus reglas.
4. Definir condiciones exactas de visualización: resultado principal completado,
   empates o ausencia de dominante, resultado incompleto y consulta de historial.
5. Definir estados visuales y alternativas: carga, ilustración ausente/error,
   texto accesible y adaptación a tamaños de pantalla. La explicación del
   resultado debe seguir disponible si la ilustración falla.
6. En esa fase, integrar los assets y el renderizado, revisar los textos y
   comprobar correspondencia familia/imagen, accesibilidad y estados acordados.
   Registrar entonces las pruebas reales; no darlas por aprobadas ahora.

**Siguiente acción de esta decisión:** diseño/UI debe concretar y aprobar los
assets, su mapeo y los estados/condiciones anteriores antes de implementarlos.
El frente vocacional continúa según su propio checkpoint; esta decisión no
autoriza reescribirlo ni interfiere con las pruebas de instituciones.
