param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('validation','production')]
  [string]$Mode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Fail([string]$Message) { throw $Message }
function Require-Command([string]$Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { Fail "Required command is not available on PATH: $Name" }
  return $cmd.Source
}
function Normalize-CertSha([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  return ($Value -replace '[^0-9A-Fa-f]','').ToUpperInvariant()
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..')).Path
Set-Location $RepoRoot

$null = Require-Command 'git'
$null = Require-Command 'java'
$null = Require-Command 'keytool'
$null = Require-Command 'amxmlc'
$null = Require-Command 'adt'

$Head = (& git rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $Head.Length -ne 40) { Fail 'Unable to resolve source HEAD.' }
$Tree = (& git rev-parse 'HEAD^{tree}').Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $Tree.Length -ne 40) { Fail 'Unable to resolve source tree.' }
$Dirty = @(& git status --porcelain=v1 --untracked-files=all)
if ($Dirty.Count -ne 0) { Fail ('Refusing provenance build from a dirty worktree.' + [Environment]::NewLine + ($Dirty -join [Environment]::NewLine)) }

$AirHome = $env:AIR_HOME
if ([string]::IsNullOrWhiteSpace($AirHome) -or -not (Test-Path -LiteralPath $AirHome -PathType Container)) { Fail 'AIR_HOME must point to the installed AIR SDK 51.3.4.3.' }
$AirHome = (Resolve-Path $AirHome).Path

$AndroidSdk = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($AndroidSdk)) { $AndroidSdk = $env:ANDROID_HOME }
if ([string]::IsNullOrWhiteSpace($AndroidSdk) -or -not (Test-Path -LiteralPath $AndroidSdk -PathType Container)) { Fail 'ANDROID_SDK_ROOT (or ANDROID_HOME) must point to an installed Android SDK.' }
$AndroidSdk = (Resolve-Path $AndroidSdk).Path
$AndroidJar = Join-Path $AndroidSdk 'platforms/android-36/android.jar'
if (-not (Test-Path -LiteralPath $AndroidJar -PathType Leaf)) { Fail 'Android platform 36 is required (platforms/android-36/android.jar missing).' }
$BuildTools = Join-Path $AndroidSdk 'build-tools/36.0.0'
$Aapt = Join-Path $BuildTools 'aapt.exe'
$ApkSigner = Join-Path $BuildTools 'apksigner.bat'
foreach ($tool in @($Aapt,$ApkSigner)) {
  if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { Fail "Android build-tools 36.0.0 is incomplete: $tool" }
}

$OutRoot = Join-Path $RepoRoot 'dist/local-apk'
$ProofDir = Join-Path $OutRoot "$Mode-proof"
New-Item -ItemType Directory -Force -Path $OutRoot,$ProofDir,(Join-Path $RepoRoot 'bin') | Out-Null
$ApkName = if ($Mode -eq 'production') { 'SLF-production.apk' } else { 'SLF-validation.apk' }
$Apk = Join-Path $OutRoot $ApkName
Remove-Item -Force -ErrorAction SilentlyContinue $Apk

$MetadataFile = Join-Path $ProofDir 'release-metadata.txt'
$SourceReceipt = Join-Path $ProofDir 'source-provenance.txt'
@(
  "source_head=$Head",
  "source_tree=$Tree",
  "worktree_clean=true",
  "artifact=apk",
  "builder_mode=$Mode"
) | Set-Content -LiteralPath $SourceReceipt -Encoding utf8

$RequiredNotices = @(
  'LICENSE',
  'THIRD_PARTY_NOTICES.md',
  'third_party/licenses/flixel-2.55-MIT.txt',
  'third_party/licenses/flixel-power-tools-Simplified-BSD.txt',
  'third_party/licenses/as3-controller-input-MIT.txt'
)
foreach ($notice in $RequiredNotices) {
  if (-not (Test-Path -LiteralPath $notice -PathType Leaf)) { Fail "Required release notice missing: $notice" }
}
$ExpectedNoticeBlobs = @{
  'third_party/licenses/flixel-2.55-MIT.txt'='5fcbbbdf0d8c043114dbf485b1f0fd7f776dd086'
  'third_party/licenses/flixel-power-tools-Simplified-BSD.txt'='eb85c14d618e818c2bec2bba6ec4a82e5dea7b84'
  'third_party/licenses/as3-controller-input-MIT.txt'='21e3babda57413417549e308c61b9597bd0aa6e1'
}
foreach ($notice in $ExpectedNoticeBlobs.Keys) {
  $blob = ((& git hash-object -- $notice) | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or $blob -ne $ExpectedNoticeBlobs[$notice]) { Fail "Third-party notice blob mismatch: $notice" }
}

$ProviderTarget = Join-Path $AirHome 'lib/android/lib/resources/app_entry/res/drawable-xhdpi/ouya_icon.png'
$ProviderBackup = Join-Path $env:TEMP ('slf-ouya-provider-' + [Guid]::NewGuid().ToString('N') + '.png')
$ProviderExpected = '58d4af4a730200aacdb84a8c768d344b463428f6df9ecd4d7dca2e1cabf0e253'
$ProviderWasSanitized = $false
$ValidationKey = Join-Path $ProofDir 'validation-signing.p12'
$KeyPath = $null

try {
  if (-not (Test-Path -LiteralPath $ProviderTarget -PathType Leaf)) { Fail "Expected AIR provider template missing: $ProviderTarget" }
  $providerItem = Get-Item -LiteralPath $ProviderTarget
  $providerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ProviderTarget).Hash.ToLowerInvariant()
  if ($providerItem.Length -ne 1525 -or $providerHash -ne $ProviderExpected) { Fail "AIR provider template identity changed; refusing sanitation. bytes=$($providerItem.Length) sha256=$providerHash" }
  Copy-Item -LiteralPath $ProviderTarget -Destination $ProviderBackup -Force
  Remove-Item -LiteralPath $ProviderTarget -Force
  $ProviderWasSanitized = $true
  @(
    'classification=INFRA_TOOLCHAIN_PROVIDER_DEFECT',
    'action=temporarily_removed_local_provider_template',
    "path=$ProviderTarget",
    'original_bytes=1525',
    "original_sha256=$ProviderExpected",
    'restore_required=true'
  ) | Set-Content -LiteralPath (Join-Path $ProofDir 'air-provider-template-sanitization.txt') -Encoding utf8

  $Swf = Join-Path $RepoRoot 'bin/SLFforOuya.swf'
  Remove-Item -Force -ErrorAction SilentlyContinue $Swf
  & amxmlc '-load-config+=obj/SLF_for_OuyaConfig.xml' "-output=$Swf"
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Swf -PathType Leaf)) { Fail 'Release SWF compilation failed.' }

  if ($Mode -eq 'production') {
    $KeyPath = $env:SLF_ANDROID_KEYSTORE
    $StorePass = $env:SLF_ANDROID_KEYSTORE_PASSWORD
    $ExpectedCert = Normalize-CertSha $env:SLF_ANDROID_EXPECTED_CERT_SHA256
    if ([string]::IsNullOrWhiteSpace($KeyPath)) { Fail 'Production build requires SLF_ANDROID_KEYSTORE to name an external PKCS#12 keystore path.' }
    if (-not (Test-Path -LiteralPath $KeyPath -PathType Leaf)) { Fail 'SLF_ANDROID_KEYSTORE does not point to a readable file.' }
    if ([string]::IsNullOrWhiteSpace($StorePass)) { Fail 'Production build requires SLF_ANDROID_KEYSTORE_PASSWORD.' }
    if ($ExpectedCert.Length -ne 64) { Fail 'Production build requires a valid 64-hex SLF_ANDROID_EXPECTED_CERT_SHA256 fingerprint.' }
    $KeyPath = (Resolve-Path $KeyPath).Path
    $SigningMode = 'production-external'
  } else {
    $KeyPath = $ValidationKey
    $StorePass = 'gate2a-validation'
    Remove-Item -Force -ErrorAction SilentlyContinue $ValidationKey
    & adt -certificate -validityPeriod 1 -cn 'Gate 2A Validation APK' 2048-RSA $ValidationKey $StorePass
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ValidationKey)) { Fail 'Failed to create disposable validation certificate.' }
    $ExpectedCert = ''
    $SigningMode = 'disposable-validation'
  }

  & adt -package -target apk -storetype pkcs12 -keystore $KeyPath -storepass $StorePass $Apk application.xml -C bin SLFforOuya.swf -C icons/android icons/icon_48.png icons/icon_57.png icons/icon_72.png icons/icon_96.png icons/icon_114.png icons/icon_144.png icons/icon_192.png -C . LICENSE THIRD_PARTY_NOTICES.md third_party/licenses/flixel-2.55-MIT.txt third_party/licenses/flixel-power-tools-Simplified-BSD.txt third_party/licenses/as3-controller-input-MIT.txt -platformsdk $AndroidSdk
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Apk -PathType Leaf)) { Fail 'ADT APK packaging failed.' }

  $ApkItem = Get-Item -LiteralPath $Apk
  if ($ApkItem.Length -le 0) { Fail 'Produced APK is empty.' }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($ApkItem.FullName)
  try {
    $entries = @($zip.Entries | ForEach-Object FullName)
    $required = @(
      'assets/LICENSE',
      'assets/THIRD_PARTY_NOTICES.md',
      'assets/third_party/licenses/flixel-2.55-MIT.txt',
      'assets/third_party/licenses/flixel-power-tools-Simplified-BSD.txt',
      'assets/third_party/licenses/as3-controller-input-MIT.txt'
    )
    foreach ($entry in $required) {
      if ($entries -notcontains $entry) { Fail "Required notice missing from APK: $entry" }
    }
    if ($entries -contains 'res/drawable-xhdpi-v4/ouya_icon.png') { Fail 'Obsolete AIR OUYA drawable survived provider sanitation in APK.' }
  } finally { $zip.Dispose() }

  $Badging = (& $Aapt dump badging $Apk 2>&1 | Out-String)
  if ($LASTEXITCODE -ne 0) { Fail 'aapt dump badging failed for produced APK.' }
  $Badging | Set-Content -LiteralPath (Join-Path $ProofDir 'aapt-badging.txt') -Encoding utf8
  if ($Badging -notmatch "package: name='com\.ramybaheeg\.slfport'") { Fail 'APK package name verification failed.' }
  if ($Badging -notmatch "versionName='1\.9'") { Fail 'APK versionName verification failed.' }
  if ($Badging -notmatch "versionCode='1009000'") { Fail 'APK versionCode verification failed.' }
  if ($Badging -notmatch "sdkVersion:'21'") { Fail 'APK minSdk verification failed.' }
  if ($Badging -notmatch "targetSdkVersion:'36'") { Fail 'APK targetSdk verification failed.' }

  $Permissions = (& $Aapt dump permissions $Apk 2>&1 | Out-String)
  if ($LASTEXITCODE -ne 0) { Fail 'aapt dump permissions failed for produced APK.' }
  $Permissions | Set-Content -LiteralPath (Join-Path $ProofDir 'aapt-permissions.txt') -Encoding utf8
  if ($Permissions -match '(?im)^\s*uses-permission(?:-sdk-\d+)?:') { Fail 'Produced APK unexpectedly declares one or more permissions.' }
  if ($Permissions -match 'android\.permission\.INTERNET') { Fail 'Produced APK unexpectedly declares android.permission.INTERNET.' }

  $SignerOutput = (& $ApkSigner verify --verbose --print-certs $Apk 2>&1 | Out-String)
  $SignerExit = $LASTEXITCODE
  $SignerOutput | Set-Content -LiteralPath (Join-Path $ProofDir 'apk-signature-verify.txt') -Encoding utf8
  if ($SignerExit -ne 0) { Fail "APK signature verification failed with exit $SignerExit." }
  if ($SignerOutput -notmatch '(?i)Verifies') { Fail 'APK signer verification did not report a verified package.' }
  $ShaMatch = [regex]::Match($SignerOutput,'(?im)Signer #1 certificate SHA-256 digest:\s*([0-9A-Fa-f]+)')
  if (-not $ShaMatch.Success) { Fail 'Could not extract APK signer SHA-256 digest.' }
  $ActualCert = Normalize-CertSha $ShaMatch.Groups[1].Value
  if ($ActualCert.Length -ne 64) { Fail "Unexpected APK signer SHA-256 fingerprint length: $($ActualCert.Length)." }
  $ProductionCertVerified = 'not-applicable-disposable-validation'
  if ($Mode -eq 'production') {
    if ($ActualCert -ne $ExpectedCert) { Fail "Production APK signer mismatch. Expected $ExpectedCert, got $ActualCert." }
    $ProductionCertVerified = 'true'
  }

  $ApkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Apk).Hash.ToLowerInvariant()
  @(
    "commit=$Head",
    "tree=$Tree",
    'artifact=apk',
    'air_sdk=51.3.4.3',
    'android_target_sdk=36',
    'android_min_sdk=21',
    "signing_mode=$SigningMode",
    "apk_bytes=$($ApkItem.Length)",
    "apk_sha256=$ApkHash",
    'manifest_package_verified=com.ramybaheeg.slfport',
    'manifest_version_name_verified=1.9',
    'manifest_version_code_verified=1009000',
    'manifest_effective_permissions_verified=none',
    'manifest_target_sdk_verified=36',
    'manifest_min_sdk_verified=21',
    "apk_signer_sha256=$ActualCert",
    "production_signing_certificate_verified=$ProductionCertVerified",
    'build_status=verified'
  ) | Set-Content -LiteralPath $MetadataFile -Encoding utf8
}
finally {
  if ($Mode -eq 'validation') { Remove-Item -Force -ErrorAction SilentlyContinue $ValidationKey }
  if ($ProviderWasSanitized) {
    if (-not (Test-Path -LiteralPath $ProviderBackup -PathType Leaf)) { throw 'AIR provider backup is missing; cannot restore provider template.' }
    Copy-Item -LiteralPath $ProviderBackup -Destination $ProviderTarget -Force
    Remove-Item -LiteralPath $ProviderBackup -Force -ErrorAction SilentlyContinue
    $restoredItem = Get-Item -LiteralPath $ProviderTarget
    $restoredHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ProviderTarget).Hash.ToLowerInvariant()
    if ($restoredItem.Length -ne 1525 -or $restoredHash -ne $ProviderExpected) { throw "AIR provider template restore verification failed. bytes=$($restoredItem.Length) sha256=$restoredHash" }
    'provider_template_restored=true' | Add-Content -LiteralPath $MetadataFile -ErrorAction SilentlyContinue
  }
}
