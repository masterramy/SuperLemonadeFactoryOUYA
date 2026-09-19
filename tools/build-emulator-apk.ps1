param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Fail([string]$Message){ throw $Message }
function Resolve-AirHome {
  if(-not [string]::IsNullOrWhiteSpace($env:AIR_HOME) -and (Test-Path $env:AIR_HOME)){ return (Resolve-Path $env:AIR_HOME).Path }
  $cmd=Get-Command adt -ErrorAction SilentlyContinue
  if($cmd){ return (Resolve-Path (Join-Path (Split-Path -Parent (Split-Path -Parent $cmd.Source)) '.')).Path }
  Fail 'AIR_HOME/adt unavailable.'
}
function Resolve-AndroidSdk {
  foreach($v in @($env:ANDROID_SDK_ROOT,$env:ANDROID_HOME)){
    if(-not [string]::IsNullOrWhiteSpace($v) -and (Test-Path $v)){ return (Resolve-Path $v).Path }
  }
  Fail 'ANDROID_SDK_ROOT/ANDROID_HOME unavailable.'
}

$ScriptDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot=(Resolve-Path (Join-Path $ScriptDir '..')).Path
Set-Location $RepoRoot
$AirHome=Resolve-AirHome
$AndroidSdk=Resolve-AndroidSdk
$OutRoot=Join-Path $RepoRoot 'dist/emulator-qa'
$ProofDir=Join-Path $OutRoot 'proof'
$Apk=Join-Path $OutRoot 'SLF-emulator-x64.apk'
$Key=Join-Path $ProofDir 'emulator-validation.p12'
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue $Apk,$Key

$ProviderTarget=Join-Path $AirHome 'lib/android/lib/resources/app_entry/res/drawable-xhdpi/ouya_icon.png'
$ProviderExpected='58d4af4a730200aacdb84a8c768d344b463428f6df9ecd4d7dca2e1cabf0e253'
$ProviderBackup=Join-Path $env:TEMP ('slf-emulator-provider-'+[Guid]::NewGuid().ToString('N')+'.png')
$ProviderWasSanitized=$false
try {
  if(-not(Test-Path -LiteralPath $ProviderTarget -PathType Leaf)){ Fail "Expected AIR provider template missing: $ProviderTarget" }
  $providerItem=Get-Item -LiteralPath $ProviderTarget
  $providerHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $ProviderTarget).Hash.ToLowerInvariant()
  if($providerItem.Length -ne 1525 -or $providerHash -ne $ProviderExpected){
    Fail "AIR provider template identity changed; refusing emulator sanitation. bytes=$($providerItem.Length) sha256=$providerHash"
  }
  Copy-Item -LiteralPath $ProviderTarget -Destination $ProviderBackup -Force
  Remove-Item -LiteralPath $ProviderTarget -Force
  $ProviderWasSanitized=$true

  $Swf=Join-Path $RepoRoot 'bin/SLFforOuya.swf'
  Remove-Item -Force -ErrorAction SilentlyContinue $Swf
  & amxmlc '-load-config+=obj/SLF_for_OuyaConfig.xml' "-output=$Swf"
  if($LASTEXITCODE -ne 0 -or -not(Test-Path $Swf)){ Fail 'Exact-head emulator SWF compilation failed.' }

  & adt -certificate -validityPeriod 1 -cn 'Gate 2A Exact Head Emulator QA' 2048-RSA $Key 'gate2a-emulator'
  if($LASTEXITCODE -ne 0 -or -not(Test-Path $Key)){ Fail 'Disposable emulator certificate creation failed.' }

  & adt -package -target apk-emulator -arch x64 -storetype pkcs12 -keystore $Key -storepass 'gate2a-emulator' $Apk application.xml -C bin SLFforOuya.swf -C icons/android icons/icon_48.png icons/icon_57.png icons/icon_72.png icons/icon_96.png icons/icon_114.png icons/icon_144.png icons/icon_192.png -C . LICENSE THIRD_PARTY_NOTICES.md MODIFICATIONS.md SOURCE_DISCLOSURE.md third_party/licenses/flixel-2.55-MIT.txt third_party/licenses/flixel-power-tools-Simplified-BSD.txt third_party/licenses/as3-controller-input-MIT.txt -platformsdk $AndroidSdk
  if($LASTEXITCODE -ne 0 -or -not(Test-Path $Apk)){ Fail 'Exact-head x64 emulator APK packaging failed.' }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path $Apk).Path)
  try {
    $entries=@($zip.Entries | ForEach-Object FullName)
    foreach($entry in @('assets/LICENSE','assets/THIRD_PARTY_NOTICES.md','assets/MODIFICATIONS.md','assets/SOURCE_DISCLOSURE.md','assets/third_party/licenses/flixel-2.55-MIT.txt','assets/third_party/licenses/flixel-power-tools-Simplified-BSD.txt','assets/third_party/licenses/as3-controller-input-MIT.txt')){
      if($entries -notcontains $entry){ Fail "Emulator APK notice missing: $entry" }
    }
    if($entries -notcontains 'lib/x86_64/libCore.so'){ Fail 'x86_64 AIR runtime missing from emulator APK.' }
    if($entries -contains 'lib/armeabi-v7a/libCore.so'){ Fail 'Device-only armeabi-v7a AIR runtime unexpectedly present in x64 emulator APK.' }
    if($entries -contains 'res/drawable-xhdpi-v4/ouya_icon.png'){ Fail 'Obsolete AIR OUYA drawable survived provider sanitation in emulator APK.' }
  } finally { $zip.Dispose() }

  $Aapt=Join-Path $AndroidSdk 'build-tools/36.0.0/aapt.exe'
  if(-not(Test-Path $Aapt)){ Fail "aapt 36.0.0 missing: $Aapt" }
  $badging=(& $Aapt dump badging $Apk 2>&1 | Out-String)
  if($LASTEXITCODE -ne 0){ Fail 'aapt badging failed for emulator APK.' }
  $badging | Set-Content -LiteralPath (Join-Path $ProofDir 'aapt-badging.txt') -Encoding utf8
  foreach($pattern in @("package: name='com\.ramybaheeg\.slfport'","versionName='1\.9'","versionCode='1009000'","sdkVersion:'21'","targetSdkVersion:'36'")){
    if($badging -notmatch $pattern){ Fail "Emulator APK metadata verification failed: $pattern" }
  }
  $permissions=(& $Aapt dump permissions $Apk 2>&1 | Out-String)
  $permissions | Set-Content -LiteralPath (Join-Path $ProofDir 'aapt-permissions.txt') -Encoding utf8
  if($permissions -match '(?im)^\s*uses-permission(?:-sdk-\d+)?:'){ Fail 'Emulator APK unexpectedly declares permissions.' }

  $head=((git rev-parse HEAD)|Out-String).Trim()
  $tree=((git rev-parse 'HEAD^{tree}')|Out-String).Trim()
  $item=Get-Item $Apk
  $sha=(Get-FileHash -Algorithm SHA256 $Apk).Hash.ToLowerInvariant()
  @(
    "commit=$head",
    "tree=$tree",
    'artifact_purpose=rendered_QA_only_not_shipping',
    'air_sdk=51.3.4.3',
    'arch=x86_64',
    'package=com.ramybaheeg.slfport',
    'version_name=1.9',
    'version_code=1009000',
    'min_sdk=21',
    'target_sdk=36',
    'effective_permissions=none',
    "apk_bytes=$($item.Length)",
    "apk_sha256=$sha"
  ) | Set-Content -LiteralPath (Join-Path $ProofDir 'emulator-identity.txt') -Encoding utf8
}
finally {
  Remove-Item -LiteralPath $Key -Force -ErrorAction SilentlyContinue
  if($ProviderWasSanitized){
    Copy-Item -LiteralPath $ProviderBackup -Destination $ProviderTarget -Force
  }
  Remove-Item -LiteralPath $ProviderBackup -Force -ErrorAction SilentlyContinue
}

Write-Host 'EXACT-HEAD X64 EMULATOR QA APK VERIFIED.'
