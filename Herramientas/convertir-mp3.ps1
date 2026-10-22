# Convierte los WAV de las clases a MP3 para la version movil.
# Solo la version normal: la lenta se consigue en el movil reproduciendo mas despacio.
#
# Uso:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\convertir-mp3.ps1

param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $ffmpeg) {
    foreach ($c in 'C:\Program Files\File Converter\ffmpeg.exe', "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe") {
        if (Test-Path $c) { $ffmpeg = $c; break }
    }
}
if (-not $ffmpeg) { Write-Host 'ERROR: no se encontro ffmpeg.'; exit 1 }
Write-Host "ffmpeg: $ffmpeg"

$raiz    = (Resolve-Path $Root).Path
$entrada = Join-Path $raiz 'Clases\audio'
$salida  = Join-Path $raiz 'Clases\audio-mp3'

if (-not (Test-Path $entrada)) { Write-Host "ERROR: no existe $entrada"; exit 1 }
if (-not (Test-Path $salida)) { New-Item -ItemType Directory -Path $salida | Out-Null }

# Limpieza de la salida anterior (comprobando que está dentro del proyecto)
$salidaResuelta = (Resolve-Path $salida).Path
if (-not $salidaResuelta.StartsWith($raiz, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "ERROR: ruta de salida fuera del proyecto: $salidaResuelta"
    exit 1
}
Get-ChildItem $salidaResuelta -Filter *.mp3 | Remove-Item -Force

$hechos = 0; $fallos = 0

foreach ($wav in Get-ChildItem $entrada -Filter *.wav) {
    if ($wav.BaseName -like '*-slow') { continue }

    $mp3 = Join-Path $salidaResuelta ($wav.BaseName + '.mp3')
    & $ffmpeg -y -hide_banner -loglevel error -i $wav.FullName `
        -codec:a libmp3lame -b:a 32k -ac 1 -ar 16000 $mp3

    if ((Test-Path $mp3) -and (Get-Item $mp3).Length -gt 500) {
        $hechos++
    } else {
        Write-Host "FALLO $($wav.Name)"
        $fallos++
    }
}

$bytes = (Get-ChildItem $salidaResuelta -Filter *.mp3 | Measure-Object Length -Sum).Sum
Write-Host ''
Write-Host ("LISTO  convertidos={0}  fallos={1}  total={2} MB" -f $hechos, $fallos, [math]::Round($bytes / 1MB, 2))
if ($fallos -gt 0) { exit 1 }
