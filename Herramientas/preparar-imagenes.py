# Convierte las imagenes de "Imagenes GIF" (WebP/GIF animados) a WebP optimizados en
# Clases\gifs-opt\<id>.webp, listos para incrustar en la pagina.
#
# Uso: python Herramientas\preparar-imagenes.py [-f]
#   -f  rehace las que ya existen

import glob
import json
import os
import sys
import unicodedata

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRADA = os.path.join(RAIZ, 'Imagenes GIF')
SALIDA = os.path.join(RAIZ, 'Clases', 'gifs-opt')
CLASES = os.path.join(RAIZ, 'Clases', 'clases.json')

ANCHO = 240          # ancho final en px
MAX_FRAMES = 14      # fotogramas como maximo
DURACION = 110       # ms por fotograma
CALIDAD = 65

FORZAR = '-f' in sys.argv


def normalizar(texto):
    if not texto:
        return ''
    t = texto.lower().replace('\u0111', 'd')
    t = unicodedata.normalize('NFKD', t)
    t = ''.join(c for c in t if not unicodedata.combining(c))
    t = ''.join(c for c in t if c.isalnum() or c == ' ')
    return ' '.join(t.split())


with open(CLASES, encoding='utf-8') as f:
    data = json.load(f)

mapa = {}
for clase in data['clases']:
    for p in clase['palabras']:
        mapa[normalizar(p['hr'])] = p['id']
    for fr in clase['frases']:
        mapa.setdefault(normalizar(fr['hr']), fr['id'])
    mapa.setdefault(normalizar(clase['drill']['respuesta']), clase['drill']['id'])

os.makedirs(SALIDA, exist_ok=True)

archivos = sorted(
    f for f in glob.glob(os.path.join(ENTRADA, '*'))
    if os.path.splitext(f)[1].lower() in ('.gif', '.webp', '.png', '.apng', '.jpg', '.jpeg')
)

hechos = 0
fallos = []

for ruta in archivos:
    nombre = os.path.splitext(os.path.basename(ruta))[0]
    ident = nombre if (len(nombre) == 4 and nombre.startswith('c')) else mapa.get(normalizar(nombre))

    if not ident:
        fallos.append(f'{os.path.basename(ruta)}: palabra no encontrada en el vocabulario')
        continue

    destino = os.path.join(SALIDA, ident + '.webp')
    if os.path.exists(destino) and not FORZAR:
        print(f'OMITIDO {os.path.basename(ruta)} -> {ident}.webp (ya existe)')
        continue

    try:
        im = Image.open(ruta)
        total = getattr(im, 'n_frames', 1)
        paso = max(1, total // MAX_FRAMES)
        indices = list(range(0, total, paso))[:MAX_FRAMES]

        frames = []
        for i in indices:
            im.seek(i)
            cuadro = im.convert('RGBA')
            fondo = Image.new('RGB', cuadro.size, (255, 253, 247))
            fondo.paste(cuadro, mask=cuadro.split()[-1])
            alto = max(1, round(fondo.height * ANCHO / fondo.width))
            frames.append(fondo.resize((ANCHO, alto), Image.LANCZOS))

        frames[0].save(
            destino,
            format='WEBP',
            save_all=True,
            append_images=frames[1:],
            duration=DURACION,
            loop=0,
            quality=CALIDAD,
            method=6,
        )
        kb = os.path.getsize(destino) / 1024
        print(f'OK  {os.path.basename(ruta)} -> {ident}.webp  {kb:.0f} KB  ({len(frames)} fotogramas)')
        hechos += 1
    except Exception as e:
        fallos.append(f'{os.path.basename(ruta)}: {e}')

print()

# Dimensiones de cada imagen, para que la ventana tenga su misma proporcion
dims = {}
for g in glob.glob(os.path.join(SALIDA, '*.webp')):
    try:
        with Image.open(g) as im:
            dims[os.path.splitext(os.path.basename(g))[0]] = [im.width, im.height]
    except Exception:
        pass
with open(os.path.join(SALIDA, 'dimensiones.json'), 'w', encoding='utf-8') as f:
    json.dump(dims, f, indent=2, ensure_ascii=False)

piezas = glob.glob(os.path.join(SALIDA, '*.webp')) + glob.glob(os.path.join(SALIDA, '*.gif'))
total_kb = sum(os.path.getsize(g) for g in piezas) / 1024
print(f'LISTO  nuevos={hechos}  total={len(piezas)} imagenes, {total_kb/1024:.2f} MB')

for f in fallos:
    print('  AVISO:', f)
