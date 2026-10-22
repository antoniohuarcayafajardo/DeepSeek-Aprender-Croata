// Comprueba que todos los elementos de cada clase tengan sus audios.
// Uso: node Herramientas\verificar-audio.js

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const data = JSON.parse(fs.readFileSync(path.join(root, 'Clases', 'clases.json'), 'utf8'));

let faltan = [];
let total = 0;

for (const clase of data.clases) {
  const items = [...clase.frases, ...clase.palabras, { id: clase.drill.id, hr: clase.drill.respuesta }];
  for (const item of items) {
    for (const sufijo of ['', '-slow']) {
      const archivo = path.join(root, 'Clases', 'audio', item.id + sufijo + '.wav');
      total++;
      if (!fs.existsSync(archivo) || fs.statSync(archivo).size < 2000) {
        faltan.push(path.relative(root, archivo));
      }
    }
  }
}

console.log(`Elementos esperados: ${total}`);
console.log(`Audios encontrados:  ${total - faltan.length}`);
if (faltan.length) {
  console.log(`FALTAN ${faltan.length}:`);
  faltan.forEach((f) => console.log('  - ' + f));
  process.exit(1);
}
console.log('Todo completo.');
