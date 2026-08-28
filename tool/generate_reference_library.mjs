import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const [sourceRoot, outputPath] = process.argv.slice(2);
if (!sourceRoot || !outputPath) {
  throw new Error(
    'Uso: node tool/generate_reference_library.mjs <frontend/src/lib> <salida.json>',
  );
}

function exportedArray(fileName, exportName) {
  const source = fs.readFileSync(path.join(sourceRoot, fileName), 'utf8');
  const declaration = source.indexOf(`export const ${exportName}`);
  if (declaration < 0) throw new Error(`No existe ${exportName}.`);
  const assignment = source.indexOf('=', declaration);
  const start = source.indexOf('[', assignment);
  if (start < 0) throw new Error(`No inicia el arreglo ${exportName}.`);

  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let index = start; index < source.length; index++) {
    const character = source[index];
    if (quote) {
      if (escaped) escaped = false;
      else if (character === '\\') escaped = true;
      else if (character === quote) quote = null;
      continue;
    }
    if (character === '"' || character === "'" || character === '`') {
      quote = character;
      continue;
    }
    if (character === '[') depth++;
    if (character === ']') {
      depth--;
      if (depth === 0) {
        const literal = source.slice(start, index + 1);
        return Function(`"use strict"; return (${literal});`)();
      }
    }
  }
  throw new Error(`No termina el arreglo ${exportName}.`);
}

const payload = {
  version: 1,
  formulas: exportedArray('formularios-icfes.ts', 'FORMULARIOS_ICFES'),
  glossaryAreas: exportedArray('glosario-icfes.ts', 'AREAS_GLOSARIO'),
  glossary: exportedArray('glosario-icfes.ts', 'TERMINOS_GLOSARIO'),
  strategy: {
    phases: exportedArray('estrategia-examen.ts', 'FASES_ESTRATEGIA'),
    areaTactics: exportedArray('estrategia-examen.ts', 'TACTICAS_POR_AREA'),
    distractors: exportedArray('estrategia-examen.ts', 'DISTRACTORES_EXAMEN'),
    checklist: exportedArray('estrategia-examen.ts', 'CHECKLIST_EXAMEN'),
  },
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');

const formulaCount = payload.formulas.reduce(
  (total, area) =>
    total + area.secciones.reduce((sum, section) => sum + section.items.length, 0),
  0,
);
process.stdout.write(
  `Biblioteca generada: ${formulaCount} referencias, ${payload.glossary.length} términos y ${payload.strategy.areaTactics.length} tácticas.\n`,
);
