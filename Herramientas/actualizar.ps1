# Actualiza TODO de una vez:
#   1. Imagenes para Android (WebP animado)
#   2. Imagenes para iPhone (GIF animado)
#   3. Manifiesto de imagenes para la version de ordenador
#   4. Las dos paginas moviles: Android e iPhone
#
# Uso: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\actualizar.ps1

param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$raiz = (Resolve-Path $Root).Path

Write-Host '1/4  Imagenes Android (WebP)...'
& python (Join-Path $PSScriptRoot 'preparar-imagenes.py')
if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR en el paso 1'; exit 1 }

Write-Host ''
Write-Host '2/4  Imagenes iPhone (GIF)...'
& python (Join-Path $PSScriptRoot 'preparar-gif-iphone.py')
if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR en el paso 2'; exit 1 }

Write-Host ''
Write-Host '3/4  Manifiesto del ordenador...'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'preparar-clases.ps1') -Root $raiz
if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR en el paso 3'; exit 1 }

Write-Host ''
Write-Host '4/4  Paginas moviles...'
& node (Join-Path $PSScriptRoot 'crear-movil.js')
if ($LASTEXITCODE -ne 0) { Write-Host 'ERROR en el paso 4'; exit 1 }

Write-Host ''
Write-Host 'Listo. Archivos para el movil:'
Get-ChildItem (Join-Path $raiz 'Clases') -Filter 'clase-movil*.html' |
    ForEach-Object { Write-Host ("  {0,-26} {1,6} KB" -f $_.Name, [math]::Round($_.Length / 1KB, 0)) }
