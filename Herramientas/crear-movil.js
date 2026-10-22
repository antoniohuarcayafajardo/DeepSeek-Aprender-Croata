// Crea las versiones para el móvil, sin JavaScript:
//   Clases\clase-movil-android.html -> imágenes WebP animadas (Android)
//   Clases\clase-movil-iphone.html  -> imágenes GIF animadas (iPhone)
//
// Uso: node Herramientas\crear-movil.js

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const datosPath = path.join(root, 'Clases', 'clases.json');
const visualesPath = path.join(root, 'Clases', 'visuales.json');
const gifsPath = path.join(root, 'Clases', 'gifs.json');
const mp3Dir = path.join(root, 'Clases', 'audio-mp3');
const plantillaPath = path.join(__dirname, 'plantilla-movil-sin-js.html');

const data = JSON.parse(fs.readFileSync(datosPath, 'utf8'));
const visuales = JSON.parse(fs.readFileSync(visualesPath, 'utf8'));
const gifs = fs.existsSync(gifsPath) ? JSON.parse(fs.readFileSync(gifsPath, 'utf8')) : {};

// GIF locales ya optimizados por preparar-imagenes.py: Clases\gifs-opt\<id>.webp
const gifDir = path.join(root, 'Clases', 'gifs-opt');
const gifsLocales = {};
if (fs.existsSync(gifDir)) {
  for (const f of fs.readdirSync(gifDir)) {
    const m = f.match(/^(.*)\.(gif|webp)$/i);
    if (!m) continue;
    const tipo = m[2].toLowerCase() === 'webp' ? 'image/webp' : 'image/gif';
    gifsLocales[m[1]] = `data:${tipo};base64,` + fs.readFileSync(path.join(gifDir, f)).toString('base64');
  }
}

// Proporción de cada imagen, para que la ventana se ajuste sin recortarla
const dimPath = path.join(gifDir, 'dimensiones.json');
const dimensiones = fs.existsSync(dimPath) ? JSON.parse(fs.readFileSync(dimPath, 'utf8')) : {};

// Versión iPhone: GIF animados (los WebP animados no se mueven antes de iOS 16.4)
const gifIphoneDir = path.join(root, 'Clases', 'gifs-iphone');
const gifsIphone = {};
if (fs.existsSync(gifIphoneDir)) {
  for (const f of fs.readdirSync(gifIphoneDir)) {
    const m = f.match(/^(.*)\.gif$/i);
    if (!m) continue;
    gifsIphone[m[1]] = 'data:image/gif;base64,' + fs.readFileSync(path.join(gifIphoneDir, f)).toString('base64');
  }
}

const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

const faltan = [];
const sinImagen = [];

function audio(id) {
  const archivo = path.join(mp3Dir, id + '.mp3');
  if (!fs.existsSync(archivo) || fs.statSync(archivo).size < 500) {
    faltan.push(id);
    return '';
  }
  const b64 = fs.readFileSync(archivo).toString('base64');
  return `<audio controls preload="none" src="data:audio/mpeg;base64,${b64}"></audio>`;
}

function visual(id) {
  const v = visuales[id];
  if (!v) { sinImagen.push(id); return ['✨', 'latir']; }
  return v;
}

function itemHTML(it, modo) {
  const [emoji, anim] = visual(it.id);
  let capaGif = '';
  let proporcion = '';
  if (modo === 'local' && gifsLocales[it.id]) {
    const d = dimensiones[it.id];
    if (d) proporcion = ` style="aspect-ratio:${d[0]}/${d[1]}"`;
    capaGif = `<img class="gif" src="${gifsLocales[it.id]}" alt="">`;
  } else if (modo === 'iphone' && gifsIphone[it.id]) {
    const d = dimensiones[it.id];
    if (d) proporcion = ` style="aspect-ratio:${d[0]}/${d[1]}"`;
    capaGif = `<img class="gif" src="${gifsIphone[it.id]}" alt="">`;
  } else if (modo === 'remoto' && gifs[it.id]) {
    capaGif = `<img class="gif" src="https://media.giphy.com/media/${gifs[it.id]}/giphy.gif" alt="" loading="lazy">`;
  }
  const claseEscena = 'escena a-' + anim + (capaGif ? ' con-imagen' : '');
  return `<div class="item">
  <details class="vis">
    <summary aria-label="Ver animación de ${esc(it.hr)}">
      <span class="mini">${emoji}</span>
      <span class="txt"><span class="hr">${esc(it.hr)}</span><span class="es">${esc(it.es)}</span></span>
    </summary>
    <div class="${claseEscena}"${proporcion}>
      <span class="g">${emoji}</span>
      <span class="p p1">✨</span>
      <span class="p p2">✨</span>
      ${capaGif}
    </div>
  </details>
  ${audio(it.id)}
</div>`;
}

const CSS_GIF = `<style>
  .escena .gif{position:absolute;inset:0;width:100%;height:100%;object-fit:contain;background:#f7f3ea}
  .escena.con-imagen{height:auto;min-height:160px;max-height:60vh;padding:0;background:#f7f3ea}
  .escena.con-imagen .g,.escena.con-imagen .p{display:none}
</style>`;

function generar(modo) {
  const secciones = data.clases.map((c, i) => {
    const frases = c.frases.map((x) => itemHTML(x, modo)).join('\n');
    const palabras = c.palabras.map((x) => itemHTML(x, modo)).join('\n');
    return `<details class="clase"${i === 0 ? ' open' : ''}>
<summary><span class="num">${c.n}</span><span class="tit">${esc(c.titulo)}</span></summary>
<div class="cuerpo">
  <p class="obj">${esc(c.objetivo)}</p>
  <h3>Frases</h3>
  ${frases}
  <h3>Palabras</h3>
  ${palabras}
  <h3>Mini-reto</h3>
  <p class="preg">${esc(c.drill.pregunta)}</p>
  ${itemHTML({ id: c.drill.id, hr: c.drill.respuesta, es: c.drill.es }, modo)}
</div>
</details>`;
  }).join('\n');

  let html = fs.readFileSync(plantillaPath, 'utf8');
  html = html.replace('<!--CLASES-->', () => secciones);
  html = html.replace('__TOTAL__', () => String(data.clases.length));

  const usaGif = modo !== 'ninguno';
  if (usaGif) {
    html = html.replace('</head>', CSS_GIF + '\n</head>');
  }
  if (modo === 'remoto') {
    html = html.replace('class="ver">v4', 'class="ver">v5 GIF');
    html = html.replace('audio incluido', 'GIF de Giphy · necesita internet');
    html = html.replace('Toca la imagen de una palabra para ver su animación.',
      'Toca la imagen de una palabra para ver su GIF. Necesita internet.');
  }
  if (modo === 'iphone') {
    html = html.replace('class="ver">v4', 'class="ver">v5 iPhone');
  }
  if (modo === 'local') {
    html = html.replace('class="ver">v4', 'class="ver">v5 Android');
  }
  return html;
}

// Los GIF locales se incrustan siempre que existan. La versión iPhone usa GIF animados.
const quiereRemoto = process.argv.includes('--gif');
const salidas = [['clase-movil-android.html', 'local'], ['clase-movil-iphone.html', 'iphone']];
if (quiereRemoto) salidas.push(['clase-movil-gif.html', 'remoto']);

for (const [nombre, modo] of salidas) {
  const destino = path.join(root, 'Clases', nombre);
  fs.writeFileSync(destino, generar(modo), 'utf8');
  const cuantos = modo === 'local' ? Object.keys(gifsLocales).length
    : modo === 'iphone' ? Object.keys(gifsIphone).length
    : Object.keys(gifs).length;
  console.log(`OK  ${nombre}  ${(fs.statSync(destino).size / 1024).toFixed(0)} KB  (${cuantos} GIF)`);
}

console.log(`    ${data.clases.length} clases · ${data.clases.length * 7} elementos`);
if (sinImagen.length) console.log(`AVISO: sin imagen asignada (${sinImagen.length}): ${sinImagen.join(', ')}`);
if (faltan.length) {
  console.log(`AVISO: faltan ${faltan.length} audios: ${faltan.slice(0, 8).join(', ')}`);
  console.log('Ejecuta antes Herramientas\\convertir-mp3.ps1');
}
