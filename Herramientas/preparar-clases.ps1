# Prepara el material de las clases.
#
#   1. Valida Clases\clases.json.
#   2. Genera Clases\clases.js (la app lo carga sin necesidad de servidor).
#   3. Con -Audio, genera además los archivos de voz en Clases\audio (requiere
#      la voz croata de Windows; se ejecuta con PowerShell 5.1).
#
# Uso:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\preparar-clases.ps1
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\preparar-clases.ps1 -Audio

param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$Audio
)

$ErrorActionPreference = 'Stop'
$jsonPath = Join-Path $Root 'Clases\clases.json'
$jsPath   = Join-Path $Root 'Clases\clases.js'

if (-not (Test-Path $jsonPath)) { Write-Host "ERROR: no existe $jsonPath"; exit 1 }

$raw = Get-Content -Raw -Encoding UTF8 $jsonPath
$data = $raw | ConvertFrom-Json

# --- Validación ------------------------------------------------------------
$errores = @()
$ids = @{}
$totalItems = 0

foreach ($clase in $data.clases) {
    if (-not $clase.n) { $errores += 'Clase sin número' }
    if (-not $clase.titulo) { $errores += "Clase $($clase.n) sin título" }
    if ($clase.frases.Count -lt 2) { $errores += "Clase $($clase.n): menos de 2 frases" }

    $items = @()
    $items += $clase.frases
    $items += $clase.palabras

    foreach ($it in $items) {
        $totalItems++
        if (-not $it.id) { $errores += "Clase $($clase.n): elemento sin id"; continue }
        if (-not $it.hr) { $errores += "Clase $($clase.n): $($it.id) sin texto croata" }
        if ($ids.ContainsKey($it.id)) { $errores += "id duplicado: $($it.id)" }
        $ids[$it.id] = $true
    }

    $totalItems++
    if (-not $clase.drill.id) { $errores += "Clase $($clase.n): mini-reto sin id" }
    if (-not $clase.drill.respuesta) { $errores += "Clase $($clase.n): mini-reto sin respuesta" }
    if ($clase.drill.id -and $ids.ContainsKey($clase.drill.id)) { $errores += "id duplicado: $($clase.drill.id)" }
    if ($clase.drill.id) { $ids[$clase.drill.id] = $true }
}

if ($errores.Count -gt 0) {
    Write-Host 'ERRORES EN clases.json:'
    $errores | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

# --- clases.js -------------------------------------------------------------
$visPath = Join-Path $Root 'Clases\visuales.json'
$visRaw = '{}'
if (Test-Path $visPath) { $visRaw = Get-Content -Raw -Encoding UTF8 $visPath }

# Imagenes disponibles para la version de ordenador (rutas relativas a Clases\)
$gifDir = Join-Path $Root 'Clases\gifs-opt'
$dimsPath = Join-Path $gifDir 'dimensiones.json'
$dims = @{}
if (Test-Path $dimsPath) {
    $dj = Get-Content -Raw -Encoding UTF8 $dimsPath | ConvertFrom-Json
    foreach ($prop in $dj.PSObject.Properties) { $dims[$prop.Name] = $prop.Value }
}

$imgMap = [ordered]@{}
if (Test-Path $gifDir) {
    foreach ($f in Get-ChildItem $gifDir -File | Where-Object { $_.Extension -match '^\.(webp|gif)$' }) {
        $id = $f.BaseName
        $w = 240; $h = 180
        if ($dims.ContainsKey($id)) { $w = [int]$dims[$id][0]; $h = [int]$dims[$id][1] }
        $imgMap[$id] = [pscustomobject]@{ src = "gifs-opt/$($f.Name)"; w = $w; h = $h }
    }
}
$imgJson = '{}'
if ($imgMap.Count -gt 0) { $imgJson = $imgMap | ConvertTo-Json -Depth 4 -Compress }

$js = "window.CLASES = $raw;`nwindow.VISUALES = $visRaw;`nwindow.IMAGENES = $imgJson;`n"
$utf8SinBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsPath, $js, $utf8SinBom)

Write-Host ("OK  clases.json válido: {0} clases, {1} elementos" -f $data.clases.Count, $totalItems)
Write-Host ("OK  generado {0} ({1} KB)" -f $jsPath, [math]::Round((Get-Item $jsPath).Length / 1KB, 1))

# --- Audio ----------------------------------------------------------------
if ($Audio) {
    Write-Host ''
    $generador = Join-Path $PSScriptRoot 'generar-audio.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $generador -Root $Root
    exit $LASTEXITCODE
}
