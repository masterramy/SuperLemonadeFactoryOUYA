Set-StrictMode -Version Latest

$script:AirVersion = '51.3.4.3'
$script:AndroidCliVersion = '15859902'
$script:AndroidCliSha256 = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'
$script:ToolchainRoot = if ([string]::IsNullOrWhiteSpace($env:SLF_TOOLCHAIN_ROOT)) {
  Join-Path $env:LOCALAPPDATA 'SuperLemonadeFactory\toolchain'
} else { $env:SLF_TOOLCHAIN_ROOT }
$script:Receipt = Join-Path $script:ToolchainRoot 'SLF_TOOLCHAIN_RECEIPT.txt'

function Add-LocalPath([string]$Directory) {
  if (-not [string]::IsNullOrWhiteSpace($Directory) -and (Test-Path -LiteralPath $Directory -PathType Container)) {
    if (@($env:PATH -split ';') -notcontains $Directory) { $env:PATH = "$Directory;$env:PATH" }
  }
}

function Add-Receipt([string]$Line) {
  New-Item -ItemType Directory -Force -Path $script:ToolchainRoot | Out-Null
  $Line | Add-Content -LiteralPath $script:Receipt -Encoding utf8
}

function Confirm-License([string]$EnvName,[string]$Title,[string]$Url) {
  if ([Environment]::GetEnvironmentVariable($EnvName) -eq '1') {
    Write-Host "${Title}: accepted by explicit $EnvName=1." -ForegroundColor DarkGray
    return
  }
  if ($env:CI -or $env:SLF_NO_PROMPTS -eq '1') {
    throw "$Title must be explicitly accepted before download. Review $Url and set $EnvName=1 only if accepted."
  }
  Write-Host ''
  Write-Host $Title -ForegroundColor Yellow
  Write-Host $Url -ForegroundColor Cyan
  Write-Host 'This tool is missing. The builder can install a private per-user copy without admin rights.'
  $answer = Read-Host 'Type I AGREE to accept the license and continue, or anything else to stop'
  if ($answer.Trim().ToUpperInvariant() -ne 'I AGREE') { throw "$Title was not accepted; no download was performed." }
}

function Test-Java17 {
  $java = Get-Command java.exe -ErrorAction SilentlyContinue
  $keytool = Get-Command keytool.exe -ErrorAction SilentlyContinue
  $jarsigner = Get-Command jarsigner.exe -ErrorAction SilentlyContinue
  if (-not $java -or -not $keytool -or -not $jarsigner) { return $false }
  $text = (& $java.Source -version 2>&1 | Out-String)
  return $text -match '(?m)(?:openjdk|java) version "17[\.]'
}

function Ensure-Java17 {
  if ($env:JAVA_HOME) { Add-LocalPath (Join-Path $env:JAVA_HOME 'bin') }
  if (Test-Java17) { return }

  $container = Join-Path $script:ToolchainRoot 'jdk17'
  $javaExe = Get-ChildItem -LiteralPath $container -Recurse -File -Filter java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $javaExe) {
    Write-Host 'Java 17 JDK was not found. Downloading portable Eclipse Temurin JDK 17...' -ForegroundColor Yellow
    $api = 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=windows&vendor=eclipse'
    $asset = @(Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent'='SuperLemonadeFactory-LocalAABBuilder' })[0]
    if ($null -eq $asset -or [string]::IsNullOrWhiteSpace("$($asset.binary.package.link)")) { throw 'Adoptium did not return a Windows x64 JDK 17 package.' }
    $url = "$($asset.binary.package.link)"
    $expected = ("$($asset.binary.package.checksum)").ToLowerInvariant()
    if ($expected.Length -ne 64) { throw 'Adoptium returned an invalid JDK checksum.' }
    $zip = Join-Path $env:TEMP ('slf-jdk17-' + [Guid]::NewGuid().ToString('N') + '.zip')
    try {
      Invoke-WebRequest -Uri $url -OutFile $zip
      $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
      if ($actual -ne $expected) { throw "Temurin JDK checksum mismatch. Expected $expected, got $actual." }
      Remove-Item $container -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Force -Path $container | Out-Null
      Expand-Archive -LiteralPath $zip -DestinationPath $container -Force
      Add-Receipt "temurin17_sha256=$actual"
      Add-Receipt "temurin17_source=$url"
    } finally { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
    $javaExe = Get-ChildItem -LiteralPath $container -Recurse -File -Filter java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if (-not $javaExe) { throw 'Portable Temurin JDK extraction produced no java.exe.' }
  $javaHome = Split-Path -Parent (Split-Path -Parent $javaExe.FullName)
  $env:JAVA_HOME = $javaHome
  Add-LocalPath (Join-Path $javaHome 'bin')
  if (-not (Test-Java17)) { throw 'Portable Java bootstrap completed, but Java 17/keytool/jarsigner are not usable.' }
}

function Test-Air([string]$Root) {
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
  $adt = Join-Path $Root 'bin\adt.bat'
  $amxmlc = Join-Path $Root 'bin\amxmlc.bat'
  if (-not (Test-Path $adt) -or -not (Test-Path $amxmlc)) { return $false }
  $text = (& $adt -version 2>&1 | Out-String)
  return $text -match [regex]::Escape($script:AirVersion)
}

function Ensure-Air {
  if (Test-Air $env:AIR_HOME) { Add-LocalPath (Join-Path $env:AIR_HOME 'bin'); return }
  $root = Join-Path $script:ToolchainRoot ('air-' + $script:AirVersion)
  if (-not (Test-Air $root)) {
    Confirm-License 'SLF_ACCEPT_HARMAN_AIR_LICENSE' 'HARMAN AIR SDK License Agreement' 'https://airsdk.harman.com/assets/pdfs/HARMAN%20AIR%20SDK%20License%20Agreement.pdf'
    Write-Host "Downloading HARMAN AIR SDK $($script:AirVersion) directly from HARMAN..." -ForegroundColor Yellow
    $api = "https://dcdu3ujoji.execute-api.us-east-1.amazonaws.com/production/releases/$($script:AirVersion)/urls"
    $urls = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent'='SuperLemonadeFactory-LocalAABBuilder' }
    $path = "$($urls.AIR_Win)"
    if ([string]::IsNullOrWhiteSpace($path)) { throw "HARMAN did not return a Windows AIR SDK URL for $($script:AirVersion)." }
    $url = "https://airsdk.harman.com${path}?license=accepted"
    $zip = Join-Path $env:TEMP ('slf-air-' + [Guid]::NewGuid().ToString('N') + '.zip')
    try {
      Invoke-WebRequest -Uri $url -OutFile $zip
      $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
      Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Force -Path $root | Out-Null
      Expand-Archive -LiteralPath $zip -DestinationPath $root -Force
      Add-Receipt "air_version=$($script:AirVersion)"
      Add-Receipt "air_archive_sha256=$sha"
      Add-Receipt "air_source=$url"
    } finally { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
  }
  if (-not (Test-Air $root)) { throw "Installed AIR SDK does not report expected version $($script:AirVersion)." }
  $env:AIR_HOME = $root
  Add-LocalPath (Join-Path $root 'bin')
}

function Test-Android([string]$Root) {
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
  return (Test-Path (Join-Path $Root 'platforms\android-36\android.jar')) -and
    (Test-Path (Join-Path $Root 'build-tools\36.0.0')) -and
    (Test-Path (Join-Path $Root 'platform-tools'))
}

function Ensure-Android {
  $existing = if ([string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
  if (Test-Android $existing) {
    $env:ANDROID_SDK_ROOT = $existing; $env:ANDROID_HOME = $existing
    Add-LocalPath (Join-Path $existing 'platform-tools')
    return
  }

  $root = Join-Path $script:ToolchainRoot 'android-sdk'
  if (-not (Test-Android $root)) {
    Confirm-License 'SLF_ACCEPT_ANDROID_SDK_LICENSE' 'Android Software Development Kit License Agreement' 'https://developer.android.com/studio/terms'
    Write-Host 'Android SDK 36 was not found. Installing a portable per-user Android SDK...' -ForegroundColor Yellow
    $cliRoot = Join-Path $root 'cmdline-tools\latest'
    $sdkManager = Join-Path $cliRoot 'bin\sdkmanager.bat'
    if (-not (Test-Path $sdkManager)) {
      $url = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
      $zip = Join-Path $env:TEMP ('slf-android-cli-' + [Guid]::NewGuid().ToString('N') + '.zip')
      $tmp = Join-Path $env:TEMP ('slf-android-cli-' + [Guid]::NewGuid().ToString('N'))
      try {
        Invoke-WebRequest -Uri $url -OutFile $zip
        $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
        if ($sha -ne $script:AndroidCliSha256) { throw "Android command-line tools checksum mismatch. Expected $($script:AndroidCliSha256), got $sha." }
        Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
        $source = Join-Path $tmp 'cmdline-tools'
        if (-not (Test-Path (Join-Path $source 'bin\sdkmanager.bat'))) { throw 'Android command-line tools archive layout was unexpected.' }
        Remove-Item $cliRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $cliRoot | Out-Null
        Copy-Item (Join-Path $source '*') -Destination $cliRoot -Recurse -Force
        Add-Receipt "android_cmdline_tools_version=$($script:AndroidCliVersion)"
        Add-Receipt "android_cmdline_tools_sha256=$sha"
        Add-Receipt "android_cmdline_tools_source=$url"
      } finally {
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
    if (-not (Test-Path $sdkManager)) { throw 'sdkmanager.bat is unavailable after Android command-line tools installation.' }
    $env:ANDROID_SDK_ROOT = $root
    $env:ANDROID_HOME = $root
    Add-LocalPath (Join-Path $cliRoot 'bin')

    # Supply acceptance only to installation of the three requested Android SDK packages.
    # Do not run `sdkmanager --licenses`, which would offer unrelated add-on terms.
    $answers = 1..8 | ForEach-Object { 'y' }
    $answers | & $sdkManager "--sdk_root=$root" 'platforms;android-36' 'build-tools;36.0.0' 'platform-tools'
    if ($LASTEXITCODE -ne 0) { throw "Android SDK package installation failed with exit $LASTEXITCODE." }
    Add-Receipt 'android_platform=android-36'
    Add-Receipt 'android_build_tools=36.0.0'
  }
  if (-not (Test-Android $root)) { throw 'Android SDK 36 installation did not produce platform 36, build-tools 36.0.0, and platform-tools.' }
  $env:ANDROID_SDK_ROOT = $root
  $env:ANDROID_HOME = $root
  Add-LocalPath (Join-Path $root 'platform-tools')
}

function Initialize-SlfLocalToolchain {
  New-Item -ItemType Directory -Force -Path $script:ToolchainRoot | Out-Null
  Ensure-Java17
  Ensure-Air
  Ensure-Android
  foreach ($name in @('java.exe','keytool.exe','jarsigner.exe','amxmlc.bat','adt.bat')) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Toolchain bootstrap completed but required command is unavailable: $name" }
  }
  if (-not (Test-Android $env:ANDROID_SDK_ROOT)) { throw 'Toolchain bootstrap completed but Android SDK 36 is incomplete.' }
  Write-Host ''
  Write-Host 'Local Android/AIR build toolchain is ready.' -ForegroundColor Green
  Write-Host "AIR_HOME=$env:AIR_HOME"
  Write-Host "ANDROID_SDK_ROOT=$env:ANDROID_SDK_ROOT"
  Write-Host "JAVA_HOME=$env:JAVA_HOME"
}
