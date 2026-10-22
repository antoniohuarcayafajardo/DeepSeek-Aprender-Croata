# Clase diaria de croata (3 minutos)

Hay dos versiones y cada una sirve para una cosa:

| Archivo | Para qué | Cómo es |
|---|---|---|
| `clase-computador.html` | Ordenador | Temporizador de 3:00, progreso e imágenes animadas |
| `clase-movil-android.html` | **Android** | WebP animado · 1,2 MB · sin JavaScript |
| `clase-movil-iphone.html` | **iPhone** | GIF animado · 1,4 MB · sin JavaScript |

## En el ordenador

Doble clic en `clase-computador.html`. No hace falta internet ni instalar nada.

| Botón | Qué hace |
|---|---|
| 🖼️ (la imagen) | Despliega la escena animada de esa palabra; se vuelve a tocar para cerrarla |
| ▶ | Pronuncia la frase o palabra (voz croata pregrabada) |
| 🐢 | La misma, más despacio |
| **▶ Empezar la clase** | Arranca el temporizador de 3:00 y reproduce toda la clase seguida |
| **↻ Repetir todo** | Vuelve a reproducir la clase completa |
| **Ver respuesta** | Muestra y pronuncia la solución del mini-reto |
| **✅ Clase hecha** | Marca la clase como hecha; la próxima vez empieza la siguiente |

La página recuerda en el navegador qué clases has marcado y abre siempre la primera
pendiente. Con ‹ y › te mueves a otra cuando quieras repasar.

## En el móvil

Hay dos archivos, uno por sistema. Los dos tienen lo mismo: diez clases, 70 audios,
imágenes de las clases 1 y 2 y escenas de reserva. **No usan JavaScript**, así que funcionan
en visores que bloquean scripts (Google Drive, visores de archivos).

| Móvil | Archivo | Imágenes |
|---|---|---|
| Android | `clase-movil-android.html` | WebP animado (más ligero) |
| iPhone | `clase-movil-iphone.html` | GIF animado (se mueve en cualquier iOS) |

El de iPhone también funciona en Android, por si prefieres usar uno solo.

1. Abre el archivo que corresponda (descargado, o desde Drive).
2. Toca el número de la clase para desplegarla.
3. Cada frase tiene su reproductor: pulsa ▶ y la oyes. También puedes arrastrar la barra
   para repetir un trozo.

### Imágenes y animaciones

Hay dos niveles:

1. **Imágenes propias** (las que bajas tú). Van en la carpeta `Imagenes GIF` de la raíz,
   con el nombre de la palabra croata: `Molim.webp`, `Oprostitе.webp`, `Dobar dan.webp`.
   El sistema las convierte a WebP animado de 240 px y las incrusta en la clase que
   corresponde.
2. **Escena de reserva**: si una palabra aún no tiene imagen, al tocar el emoji se abre la
   escena animada con CSS (el café echa vapor, el pez nada…). No usa JavaScript y funciona
   sin conexión.

Las animaciones CSS se definen con las clases `a-latir`, `a-flotar`, `a-menear`,
`a-rebotar`, `a-nadar`, `a-vapor`, `a-girar`, `a-deslizar` y `a-temblar`. Si el teléfono
tiene activada la opción de reducir movimiento, se desactivan solas.

Qué no tiene, por no llevar JavaScript: temporizador, progreso guardado y botón de
«clase hecha». A cambio no se rompe en ningún sitio.

### Si el audio no suena

El texto se verá siempre, porque es HTML normal. Si los reproductores no arrancan, es que
ese visor también bloquea el audio: ábrelo entonces con **Chrome**, desde las descargas
del teléfono (Archivos → Descargas → tocar el archivo → Abrir con Chrome).

## Contenido de la carpeta

- `clases.json` — las clases: título, objetivo, 3 frases, 3 palabras y un mini-reto.
- `visuales.json` — la imagen (emoji) y la animación de cada palabra, por su `id`.
- `clases.js` — el mismo contenido en el formato que carga `clase-computador.html`.
- `clase-computador.html` — la versión de ordenador.
- `clase-movil-android.html` — la versión móvil para Android (WebP).
- `clase-movil-iphone.html` — la versión móvil para iPhone (GIF).
- `gifs-opt/` — las imágenes ya convertidas, con sus proporciones en `dimensiones.json`.
- `gifs-iphone/` — las mismas imágenes en GIF para iPhone.
- `audio/` — dos WAV por elemento: normal y `-slow`.
- `audio-mp3/` — un MP3 por elemento; es lo que se incrusta en la versión móvil.

## Si añades imágenes nuevas

Deja los archivos en `Imagenes GIF` (nombre = palabra croata) y ejecuta un solo comando:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\actualizar.ps1
```

Convierte las imágenes a WebP y a GIF, actualiza el manifiesto del ordenador y
reconstruye **las dos** páginas móviles. Añade unos 30–90 KB por imagen y por versión.

## Si añades o cambias clases

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\preparar-clases.ps1 -Audio
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\convertir-mp3.ps1
node .\Herramientas\crear-movil.js
```

El primero valida `clases.json` y regenera los WAV; el segundo los pasa a MP3; el tercero
reconstruye las dos páginas móviles. La generación de voz necesita ejecutarse fuera del sandbox.

## Nota sobre la voz

El audio es pregrabado con la voz croata de Windows (Microsoft Matej, *hr-HR*), así que
suena en Chrome, Safari o Firefox sin depender de las voces del sistema.
