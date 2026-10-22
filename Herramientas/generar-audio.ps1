# Genera los audios de las clases con la voz croata de Windows.
#
# Uso (PowerShell 5.1, no requiere administrador):
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Herramientas\generar-audio.ps1
#
# Opciones:
#   -Force        Regenera también los archivos que ya existen.
#   -Only c05f1   Genera solo el elemento indicado (para probar).
#
# Salida: Clases\audio\<id>.wav y <id>-slow.wav

param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$Force,
    [string]$Only
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

$jsonPath = Join-Path $Root 'Clases\clases.json'
$audioDir = Join-Path $Root 'Clases\audio'

if (-not (Test-Path $jsonPath)) { Write-Host "ERROR: no existe $jsonPath"; exit 1 }
if (-not (Test-Path $audioDir)) { New-Item -ItemType Directory -Path $audioDir | Out-Null }

# --- Puente para esperar operaciones asíncronas de WinRT -------------------
$script:asTaskMethod = $null
function Get-AsTaskMethod {
    if (-not $script:asTaskMethod) {
        $script:asTaskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() |
            Where-Object {
                $_.Name -eq 'AsTask' -and
                $_.GetParameters().Count -eq 1 -and
                $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
            } | Select-Object -First 1
    }
    $script:asTaskMethod
}

function Await($operation, [Type]$resultType) {
    $method = Get-AsTaskMethod
    $task = $method.MakeGenericMethod($resultType).Invoke($null, @($operation))
    $task.Wait()
    $task.Result
}

# --- Motor de voz ----------------------------------------------------------
[Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

function Get-LanguageTag($voice) {
    $language = $voice.Language
    if ($language -is [string]) { return $language }
    return $language.LanguageTag
}

$allVoices = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices
$tags = @($allVoices | ForEach-Object { Get-LanguageTag $_ })
$hrVoice = $allVoices | Where-Object { (Get-LanguageTag $_) -like 'hr*' } | Select-Object -First 1

if (-not $hrVoice) {
    Write-Host 'NO_HR_VOICE'
    Write-Host ('Voces disponibles: ' + ($(if ($tags.Count) { $tags -join ', ' } else { '(ninguna)' })))
    Write-Host 'Instala la función Voz del croata y vuelve a ejecutar este script.'
    exit 2
}

Write-Host ("Voz croata: {0} ({1})" -f $hrVoice.DisplayName, (Get-LanguageTag $hrVoice))

$synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer
$synth.Voice = $hrVoice

function Save-Speech([string]$text, [string]$path, [double]$rate) {
    $synth.Options.SpeakingRate = $rate
    $stream = Await ($synth.SynthesizeTextToStreamAsync($text)) ([Windows.Media.SpeechSynthesis.SpeechSynthesisStream])
    $size = [int]$stream.Size
    $reader = New-Object Windows.Storage.Streams.DataReader($stream)
    Await ($reader.LoadAsync([uint32]$size)) ([uint32]) | Out-Null
    $bytes = New-Object 'byte[]' $size
    $reader.ReadBytes($bytes)
    [System.IO.File]::WriteAllBytes($path, $bytes)
    return $size
}

# --- Elementos a generar ---------------------------------------------------
$data = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
$items = New-Object System.Collections.Generic.List[object]

foreach ($clase in $data.clases) {
    foreach ($f in $clase.frases)  { $items.Add([pscustomobject]@{ id = $f.id; hr = $f.hr }) }
    foreach ($p in $clase.palabras) { $items.Add([pscustomobject]@{ id = $p.id; hr = $p.hr }) }
    if ($clase.drill)              { $items.Add([pscustomobject]@{ id = $clase.drill.id; hr = $clase.drill.respuesta }) }
}

if ($Only) { $items = $items | Where-Object { $_.id -eq $Only } }

$made = 0; $skipped = 0; $failed = 0
$seen = @{}

foreach ($item in $items) {
    if ($seen.ContainsKey($item.id)) { continue }
    $seen[$item.id] = $true

    foreach ($variant in @(@{ suffix = ''; rate = 1.0 }, @{ suffix = '-slow'; rate = 0.68 })) {
        $file = Join-Path $audioDir ($item.id + $variant.suffix + '.wav')
        if ((Test-Path $file) -and -not $Force) { $skipped++; continue }
        try {
            $size = Save-Speech $item.hr $file $variant.rate
            Write-Host ("OK   {0}{1,-6} {2,7} bytes  {3}" -f $item.id, $variant.suffix, $size, $item.hr)
            $made++
        } catch {
            Write-Host ("FAIL {0}{1} : {2}" -f $item.id, $variant.suffix, $_.Exception.Message)
            $failed++
        }
    }
}

Write-Host ''
Write-Host ("LISTO  generados={0}  omitidos={1}  fallos={2}  carpeta={3}" -f $made, $skipped, $failed, $audioDir)
if ($failed -gt 0) { exit 1 }
