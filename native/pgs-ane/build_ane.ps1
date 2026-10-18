# Isolated developer-only, no Play publication or production signing.
# Run on Windows with JDK 17, Gradle 8.7+, Android SDK 35, AIR SDK 51+.
param([string]$AirHome = $env:AIR_HOME, [string]$OutputDirectory = 'build/ane')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    if (-not $AirHome) { throw 'AIR_HOME required (Harman AIR 51+)' }
    $compiler = Join-Path $AirHome 'bin/acompc.bat'
    $adt = Join-Path $AirHome 'bin/adt.bat'
    $fre = Join-Path $AirHome 'lib/android/FlashRuntimeExtensions.jar'
    if (!(Test-Path $fre)) { $fre = Join-Path $AirHome 'lib/FlashRuntimeExtensions.jar' }
    foreach($p in @($compiler,$adt,$fre)) { if (!(Test-Path $p)) { throw "Missing native build input: $p" } }
    $env:AIR_FRE_JAR = $fre
    if (!(Get-Command gradle -ErrorAction SilentlyContinue)) { throw 'Gradle executable missing; install Gradle and Android SDK first' }
    & gradle --no-daemon --console=plain assembleRelease
    if ($LASTEXITCODE -ne 0) { throw "Android Google SDK native compile failed ($LASTEXITCODE)" }
    $aar = Get-ChildItem -Path build/outputs/aar -Filter '*release.aar' | Select-Object -First 1
    if (-not $aar) { throw 'Missing built Android .aar' }
    $tmp = Join-Path $root 'build/ane-stage'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item $aar.FullName (Join-Path $tmp 'android-library.zip')
    Expand-Archive -Path (Join-Path $tmp 'android-library.zip') -DestinationPath (Join-Path $tmp 'android-library') -Force
    $classes = Join-Path $tmp 'android-library/classes.jar'
    if (!(Test-Path $classes)) { throw 'Missing classes.jar inside Android AAR' }
    $lib = Join-Path $tmp 'SLFPGSNative.jar'
    Copy-Item $classes $lib
    $swc = Join-Path $tmp 'SLFPGSNative.swc'
    & $compiler '-source-path=as3' '-include-classes=com.ramybaheeg.slfport.pgs.BridgeMarker' "-output=$swc"
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $swc)) { throw 'Failed to build native extension SWC' }
    $absoluteOutput = Join-Path $root $OutputDirectory
    New-Item -ItemType Directory -Path $absoluteOutput -Force | Out-Null
    $ane = Join-Path $absoluteOutput 'SLFPGSSavedGames-dev.ane'
    & $adt -package -target ane $ane extension.xml -swc $swc `
        -platform Android-ARM -platformoptions platform.xml -C $tmp SLFPGSNative.jar `
        -platform Android-ARM64 -platformoptions platform.xml -C $tmp SLFPGSNative.jar
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $ane)) { throw 'ADT ANE packaging failed' }
    & python (Join-Path $root '../../qa/postlaunch/test_native_ane_packaging.py')
    if ($LASTEXITCODE -ne 0) { throw 'Native contract gate failed' }
    Write-Host "DEV ANE assembled: $ane (requires app-specific PGS config and device QA)"
} finally { Pop-Location }
