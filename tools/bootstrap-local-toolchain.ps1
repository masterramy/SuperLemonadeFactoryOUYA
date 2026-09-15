Set-StrictMode -Version Latest

$script:SlfAirVersion = '51.3.4.3'
$script:SlfAndroidCmdlineVersion = '15859902'
$script:SlfAndroidCmdlineSha256 = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'
$script:SlfToolchainRoot = Join-Path $env:LOCALAPPDATA 'SuperLemonadeFactory\toolchain'
$script:SlfReceipt = Join-Path $script:SlfToolchainRoot 'SLF_TOOLCHAIN_RECEIPT.txt'

function Add-SlfPath([string]$Directory) {
  if ([string]::IsNullOrWhiteSpace($Directory) -or -not (Test-Path -LiteralPath $Directory -PathType Container)) { return }
  $parts = @($env:PATH -split ';')
  if ($parts -notcontains $Directory) { $env:PATH = "$Directory;$env:PATH" }
}

function Write-SlfToolchainReceipt([string]$Line) {
  New-Item -ItemType Directory -Force -Path $script:SlfToolchainRoot | Out-Null
  $Line | Add-Content -LiteralPath $script:SlfReceipt -Encoding utf8
}

function Confirm-SlfLicense([string]$EnvName,[string]$Title,[string]$Url) {
  $accepted = [Environment]::GetEnvironmentVariable($EnvName)
  if ($accepted -eq '1') {
    Write-Host "$Title: accepted by explicit $EnvName=1." -ForegroundColor DarkGray
    return
  }
  if ($env:CI -or $env:SLF_NO_PROMPTS -eq '1') {
    throw "$Title must be explicitly accepted before automatic download. Set $EnvName=1 only after reviewing $Url."
  }
  Write-Host ''
  Write-Host $Title -ForegroundColor Yellow
  Write-Host $Url -ForegroundColor Cyan
  Write-Host 'The required tool is not installed. It can be downloaded into your user profile without admin rights.'
  $answer = Read-Host 'Type I AGREE to accept this license and continue, or anything else to stop'
  if ($answer.Trim().ToUpperInvariant() -ne 'I AGREE') {
    throw "$Title was not accepted; no download was performed."
  }
}

function Get-SlfFirstChildDirectory([string]$Root,[string]$Marker) {
  $markerFile = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $Marker -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $markerFile) { return $null }
  if ($Marker -ieq 'java.exe') { return Split-Path -Parent (Split-Path -Parent $markerFile.FullName) }
  return $markerFile.Directory.Parent.FullName
}

function Initialize-SlfJava {
  if ($env:JAVA_HOME) {
    $bin = Join-Path $env:JAVA_HOME 'bin'
    if ((Test-Path (Join-Path $bin 'java.exe')) -and (Test-Path (Join-Path $bin 'keytool.exe')) -and (Test-Path (Join-Path $bin 'jarsigner.exe'))) {
      Add-SlfPath $bin
      return
    }
  }

  $java = Get-Command java.exe -ErrorAction SilentlyContinue
  $keytool = Get-Command keytool.exe -ErrorAction SilentlyContinue
  $jarsigner = Get-Command jarsigner.exe -ErrorAction SilentlyContinue
  if ($java -and $keytool -and $jarsigner) { return }

  $jdkContainer = Join-Path $script:SlfToolchainRoot 'jdk17'
  $existingJava = Get-ChildItem -LiteralPath $jdkContainer -Recurse -File -Filter java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($existingJava) {
    $home = Split-Path -Parent (Split-Path -Parent $existingJava.FullName)
    $env:JAVA_HOME = $home
    Add-SlfPath (Join-Path $home 'bin')
    return
  }

  Write-Host 'Java 17 JDK was not found. Downloading a portable Eclipse Temurin JDK 17...' -ForegroundColor Yellow
  New-Item -ItemType Directory -Force -Path $jdkContainer | Out-Null
  $assetUrl = 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=windows&vendor=eclipse'
  $assets = Invoke-RestMethod -Uri $assetUrl -Headers @{ 'User-Agent'='SuperLemonadeFactory-LocalAABBuilder' }
  $asset = @($assets)[0]
  if ($null -eq $asset -or [string]::IsNullOrWhiteSpace("$($asset.binary.package.link)")) { throw 'Adoptium did not return a Windows x64 JDK 17 package.' }
  $downloadUrl = "$($asset.binary.package.link)"
  $expectedSha = ("$($asset.binary.package.checksum)").ToLowerInvariant()
  if ($expectedSha.Length -ne 64) { throw 'Adoptium returned an invalid JDK package checksum.' }
  $zip = Join-Path $env:TEMP ('slf-temurin17-' + [Guid]::NewGuid().ToString('N') + '.zip')
  try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zip
    $actualSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
    if ($actualSha -ne $expectedSha) { throw "Temurin JDK checksum mismatch. Expected $expectedSha, got $actualSha." }
    Remove-Item -LiteralPath $jdkContainer -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $jdkContainer | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $jdkContainer -Force
    $existingJava = Get-ChildItem -LiteralPath $jdkContainer -Recurse -File -Filter java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $existingJava) { throw 'Portable Temurin JDK extraction produced no java.exe.' }
    $home = Split-Path -Parent (Split-Path -Parent $existingJava.FullName)
    if (-not (Test-Path (Join-Path $home 'bin\keytool.exe')) -or -not (Test-Path (Join-Path $home 'bin\jarsigner.exe'))) { throw 'Portable Temurin JDK is missing keytool or jarsigner.' }
    $env:JAVA_HOME = $home
    Add-SlfPath (Join-Path $home 'bin')
    Write-SlfToolchainReceipt "temurin17_sha256=$actualSha"
    Write-SlfToolchainReceipt "temurin17_source=$downloadUrl"
  } finally {
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  }
}

function Test-SlfAirHome([string]$Root) {
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
  return (Test-Path (Join-Path $Root 'bin\amxmlc.bat')) -and (Test-Path (Join-Path $Root 'bin\adt.bat'))
}

function Initialize-SlfAir {
  if (Test-SlfAirHome $env:AIR_HOME) {
    Add-SlfPath (Join-Path $env:AIR_HOME 'bin')
    return
  }

  $airRoot = Join-Path $script:SlfToolchainRoot ('air-' + $script:SlfAirVersion)
  if (Test-SlfAirHome $airRoot) {
    $env:AIR_HOME = $airRoot
    Add-SlfPath (Join-Path $airRoot 'bin')
    return
  }

  Confirm-SlfLicense 'SLF_ACCEPT_HARMAN_AIR_LICENSE' 'HARMAN AIR SDK License Agreement' 'https://airsdk.harman.com/assets/pdfs/HARMAN%20AIR%20SDK%20License%20Agreement.pdf'
  Write-Host "Downloading HARMAN AIR SDK $($script:SlfAirVersion) directly from HARMAN..." -ForegroundColor Yellow
  $urlsApi = "https://dcdu3ujoji.execute-api.us-east-1.amazonaws.com/production/releases/$($script:SlfAirVersion)/urls"
  $urls = Invoke-RestMethod -Uri $urlsApi -Headers @{ 'User-Agent'='SuperLemonadeFactory-LocalAABBuilder' }
  $urlPath = "$($urls.AIR_Win)"
  if ([string]::IsNullOrWhiteSpace($urlPath)) { throw "HARMAN did not return a Windows AIR SDK URL for $($script:SlfAirVersion)." }
  $archiveUrl = "https://airsdk.harman.com${urlPath}?license=accepted"
  $zip = Join-Path $env:TEMP ('slf-air-' + $script:SlfAirVersion + '-' + [Guid]::NewGuid().ToString('N') + '.zip')
  try {
    Invoke-WebRequest -Uri $archiveUrl -OutFile $zip
    $downloadSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
    Remove-Item -LiteralPath $airRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $airRoot | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $airRoot -Force
    if (-not (Test-SlfAirHome $airRoot)) { throw 'HARMAN AIR SDK extraction did not produce amxmlc.bat and adt.bat.' }
    $env:AIR_HOME = $airRoot
    Add-SlfPath (Join-Path $airRoot 'bin')
    $versionText = (& (Join-Path $airRoot 'bin\adt.bat') -version 2>&1 | Out-String)
    if ($versionText -notmatch [regex]::Escape($script:SlfAirVersion)) { throw "Installed AIR SDK does not report expected version $($script:SlfAirVersion). Output: $versionText" }
    Write-SlfToolchainReceipt "air_version=$($script:SlfAirVersion)"
    Write-SlfToolchainReceipt "air_archive_sha256=$downloadSha"
    Write-SlfToolchainReceipt "air_source=$archiveUrl"
  } finally {
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  }
}

function Test-SlfAndroidSdk([string]$Root) {
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
  return (Test-Path (Join-Path $Root 'platforms\android-36\android.jar')) -and
         (Test-Path (Join-Path $Root 'build-tools\36.0.0')) -and
         (Test-Path (Join-Path $Root 'platform-tools'))
}

function Invoke-SlfSdkManagerLicenses([string]$SdkManager,[string]$SdkRoot) {
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $env:ComSpec
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.ArgumentList.Add('/d')
  $psi.ArgumentList.Add('/c')
  $psi.ArgumentList.Add('"' + $SdkManager + '" --sdk_root="' + $SdkRoot + '" --licenses')
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $psi
  if (-not $process.Start()) { throw 'Could not start sdkmanager --licenses.' }
  for ($i = 0; $i -lt 64; $i++) { $process.StandardInput.WriteLine('y') }
  $process.StandardInput.Close()
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()
  if ($process.ExitCode -ne 0) { throw "sdkmanager --licenses failed with exit $($process.ExitCode).`n$stdout`n$stderr" }
}

function Initialize-SlfAndroid {
  $existing = $env:ANDROID_SDK_ROOT
  if ([string]::IsNullOrWhiteSpace($existing)) { $existing = $env:ANDROID_HOME }
  if (Test-SlfAndroidSdk $existing) {
    $env:ANDROID_SDK_ROOT = $existing
    $env:ANDROID_HOME = $existing
    Add-SlfPath (Join-Path $existing 'platform-tools')
    return
  }

  $sdkRoot = Join-Path $script:SlfToolchainRoot 'android-sdk'
  if (Test-SlfAndroidSdk $sdkRoot) {
    $env:ANDROID_SDK_ROOT = $sdkRoot
    $env:ANDROID_HOME = $sdkRoot
    Add-SlfPath (Join-Path $sdkRoot 'platform-tools')
    return
  }

  Confirm-SlfLicense 'SLF_ACCEPT_ANDROID_SDK_LICENSE' 'Android Software Development Kit License Agreement' 'https://developer.android.com/studio/terms'
  Write-Host 'Android SDK 36 toolchain was not found. Installing a portable per-user Android SDK...' -ForegroundColor Yellow
  New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
  $cmdlineRoot = Join-Path $sdkRoot 'cmdline-tools\latest'
  $sdkManager = Join-Path $cmdlineRoot 'bin\sdkmanager.bat'
  if (-not (Test-Path $sdkManager)) {
    $zipUrl = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
    $zip = Join-Path $env:TEMP ('slf-android-cli-' + [Guid]::NewGuid().ToString('N') + '.zip')
    $tempExtract = Join-Path $env:TEMP ('slf-android-cli-' + [Guid]::NewGuid().ToString('N'))
    try {
      Invoke-WebRequest -Uri $zipUrl -OutFile $zip
      $actualSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
      if ($actualSha -ne $script:SlfAndroidCmdlineSha256) { throw "Android command-line tools checksum mismatch. Expected $($script:SlfAndroidCmdlineSha256), got $actualSha." }
      Expand-Archive -LiteralPath $zip -DestinationPath $tempExtract -Force
      $source = Join-Path $tempExtract 'cmdline-tools'
      if (-not (Test-Path (Join-Path $source 'bin\sdkmanager.bat'))) { throw 'Android command-line tools archive layout was unexpected.' }
      Remove-Item -LiteralPath $cmdlineRoot -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Force -Path $cmdlineRoot | Out-Null
      Copy-Item -Path (Join-Path $source '*') -Destination $cmdlineRoot -Recurse -Force
      Write-SlfToolchainReceipt "android_cmdline_tools_version=$($script:SlfAndroidCmdlineVersion)"
      Write-SlfToolchainReceipt "android_cmdline_tools_sha256=$actualSha"
      Write-SlfToolchainReceipt "android_cmdline_tools_source=$zipUrl"
    } finally {
      Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
  if (-not (Test-Path $sdkManager)) { throw 'sdkmanager.bat is unavailable after Android command-line tools installation.' }

  $env:ANDROID_SDK_ROOT = $sdkRoot
  $env:ANDROID_HOME = $sdkRoot
  Add-SlfPath (Join-Path $cmdlineRoot 'bin')
  Invoke-SlfSdkManagerLicenses $sdkManager $sdkRoot
  & $sdkManager "--sdk_root=$sdkRoot" 'platforms;android-36' 'build-tools;36.0.0' 'platform-tools'
  if ($LASTEXITCODE -ne 0) { throw "Android SDK package installation failed with exit $LASTEXITCODE." }
  if (-not (Test-SlfAndroidSdk $sdkRoot)) { throw 'Android SDK 36 installation did not produce the required platform/build-tools/platform-tools.' }
  Add-SlfPath (Join-Path $sdkRoot 'platform-tools')
  Write-SlfToolchainReceipt 'android_platform=android-36'
  Write-SlfToolchainReceipt 'android_build_tools=36.0.0'
}

function Initialize-SlfLocalToolchain {
  New-Item -ItemType Directory -Force -Path $script:SlfToolchainRoot | Out-Null
  Initialize-SlfJava
  Initialize-SlfAir
  Initialize-SlfAndroid

  $required = @('java.exe','keytool.exe','jarsigner.exe','amxmlc.bat','adt.bat')
  foreach ($name in $required) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Local toolchain bootstrap completed but required command remains unavailable: $name" }
  }
  if (-not (Test-SlfAndroidSdk $env:ANDROID_SDK_ROOT)) { throw 'Local toolchain bootstrap completed but Android SDK 36 is still incomplete.' }
  Write-Host ''
  Write-Host 'Local Android/AIR build toolchain is ready.' -ForegroundColor Green
  Write-Host "AIR_HOME=$env:AIR_HOME"
  Write-Host "ANDROID_SDK_ROOT=$env:ANDROID_SDK_ROOT"
  Write-Host "JAVA_HOME=$env:JAVA_HOME"
}
