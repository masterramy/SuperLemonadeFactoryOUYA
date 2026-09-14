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
function Write-TreeReceipt([string]$Root,[string]$Label,[string]$ProofDir,[string]$EnvironmentFile) {
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "Required SDK subtree missing: $Root" }
  $resolved=(Resolve-Path $Root).Path
  $entries=Get-ChildItem -Path $resolved -Recurse -File | ForEach-Object {
    $relative=[IO.Path]::GetRelativePath($resolved,$_.FullName).Replace('\','/')
    $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
    [PSCustomObject]@{Path=$relative;Sha256=$hash;Bytes=$_.Length}
  } | Sort-Object Path
  if (@($entries).Count -eq 0) { Fail "SDK subtree is empty: $Root" }
  $manifest=Join-Path $ProofDir "android-sdk-$Label-sha256-manifest.txt"
  $entries | ForEach-Object { "$($_.Sha256)  $($_.Bytes)  $($_.Path)" } | Set-Content -LiteralPath $manifest -Encoding utf8
  $manifestSha=(Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash.ToLowerInvariant()
  $count=@($entries).Count
  $bytes=($entries | Measure-Object -Property Bytes -Sum).Sum
  "android_sdk_${Label}_file_count=$count" | Add-Content -LiteralPath $EnvironmentFile
  "android_sdk_${Label}_tree_bytes=$bytes" | Add-Content -LiteralPath $EnvironmentFile
  "android_sdk_${Label}_manifest_sha256=$manifestSha" | Add-Content -LiteralPath $EnvironmentFile
}

$ScriptDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot=(Resolve-Path (Join-Path $ScriptDir '..')).Path
Set-Location $RepoRoot

$git=Require-Command 'git'
$java=Require-Command 'java'
$keytool=Require-Command 'keytool'
$jarsigner=Require-Command 'jarsigner'
$amxmlc=Require-Command 'amxmlc'
$adt=Require-Command 'adt'

$Head=(& git rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $Head.Length -ne 40) { Fail 'Unable to resolve Git HEAD.' }
$Tree=(& git rev-parse 'HEAD^{tree}').Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $Tree.Length -ne 40) { Fail 'Unable to resolve Git tree.' }
$Dirty=@(& git status --porcelain=v1 --untracked-files=all)
if ($Dirty.Count -ne 0) {
  Fail "Refusing provenance build from a dirty worktree. Commit/stash local changes first.`n$($Dirty -join "`n")"
}

$AirHome=$env:AIR_HOME
if ([string]::IsNullOrWhiteSpace($AirHome) -or -not (Test-Path -LiteralPath $AirHome -PathType Container)) {
  Fail 'AIR_HOME must point to the installed AIR SDK 51.3.4.3.'
}
$AirHome=(Resolve-Path $AirHome).Path
$AndroidSdk=$env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($AndroidSdk)) { $AndroidSdk=$env:ANDROID_HOME }
if ([string]::IsNullOrWhiteSpace($AndroidSdk) -or -not (Test-Path -LiteralPath $AndroidSdk -PathType Container)) {
  Fail 'ANDROID_SDK_ROOT (or ANDROID_HOME) must point to an installed Android SDK.'
}
$AndroidSdk=(Resolve-Path $AndroidSdk).Path
$AndroidJar=Join-Path $AndroidSdk 'platforms/android-36/android.jar'
if (-not (Test-Path -LiteralPath $AndroidJar -PathType Leaf)) { Fail 'Android platform 36 is required (platforms/android-36/android.jar missing).' }

$OutRoot=Join-Path $RepoRoot 'dist/local-aab'
$ProofDir=Join-Path $OutRoot "$Mode-proof"
New-Item -ItemType Directory -Force -Path $OutRoot,$ProofDir,(Join-Path $RepoRoot 'bin') | Out-Null
$AabName = if ($Mode -eq 'production') { 'SLF-production.aab' } else { 'SLF-validation.aab' }
$Aab=Join-Path $OutRoot $AabName
Remove-Item -Force -ErrorAction SilentlyContinue $Aab
$EnvironmentFile=Join-Path $ProofDir 'build-environment.txt'
$MetadataFile=Join-Path $ProofDir 'release-metadata.txt'
$SourceReceipt=Join-Path $ProofDir 'source-provenance.txt'
@("source_head=$Head","source_tree=$Tree","worktree_clean=true") | Set-Content -LiteralPath $SourceReceipt -Encoding utf8

@(
  "builder_mode=$Mode"
  "source_head=$Head"
  "source_tree=$Tree"
  "os=$([Environment]::OSVersion.VersionString)"
  "powershell=$($PSVersionTable.PSVersion)"
  "air_home=$AirHome"
  "android_sdk_root=$AndroidSdk"
) | Set-Content -LiteralPath $EnvironmentFile -Encoding utf8
(& java -version 2>&1 | Out-String).Trim() | Add-Content -LiteralPath $EnvironmentFile
(& amxmlc -version 2>&1 | Out-String).Trim() | Add-Content -LiteralPath $EnvironmentFile
(& adt -version 2>&1 | Out-String).Trim() | Add-Content -LiteralPath $EnvironmentFile

$AirEntries=Get-ChildItem -Path $AirHome -Recurse -File | ForEach-Object {
  $relative=[IO.Path]::GetRelativePath($AirHome,$_.FullName).Replace('\','/')
  $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
  [PSCustomObject]@{Path=$relative;Sha256=$hash;Bytes=$_.Length}
} | Sort-Object Path
if (@($AirEntries).Count -eq 0) { Fail 'AIR SDK tree contains no files.' }
$AirManifest=Join-Path $ProofDir 'air-sdk-sha256-manifest.txt'
$AirEntries | ForEach-Object { "$($_.Sha256)  $($_.Bytes)  $($_.Path)" } | Set-Content -LiteralPath $AirManifest -Encoding utf8
$AirManifestSha=(Get-FileHash -Algorithm SHA256 -LiteralPath $AirManifest).Hash.ToLowerInvariant()
"air_sdk_requested=51.3.4.3" | Add-Content -LiteralPath $EnvironmentFile
"air_sdk_file_count=$(@($AirEntries).Count)" | Add-Content -LiteralPath $EnvironmentFile
"air_sdk_tree_bytes=$(($AirEntries | Measure-Object -Property Bytes -Sum).Sum)" | Add-Content -LiteralPath $EnvironmentFile
"air_sdk_manifest_sha256=$AirManifestSha" | Add-Content -LiteralPath $EnvironmentFile
$AndroidJarSha=(Get-FileHash -Algorithm SHA256 -LiteralPath $AndroidJar).Hash.ToLowerInvariant()
"android_36_android_jar_sha256=$AndroidJarSha" | Add-Content -LiteralPath $EnvironmentFile
Write-TreeReceipt (Join-Path $AndroidSdk 'platforms/android-36') 'platform-android-36' $ProofDir $EnvironmentFile
$BuildToolRoots=Get-ChildItem -Directory (Join-Path $AndroidSdk 'build-tools') -ErrorAction Stop | Sort-Object Name
if (@($BuildToolRoots).Count -eq 0) { Fail 'No Android build-tools revisions are installed.' }
foreach($bt in $BuildToolRoots){ Write-TreeReceipt $bt.FullName ('build-tools-'+($bt.Name -replace '[^A-Za-z0-9._-]','_')) $ProofDir $EnvironmentFile }
Write-TreeReceipt (Join-Path $AndroidSdk 'platform-tools') 'platform-tools' $ProofDir $EnvironmentFile

$RequiredNotices=@('LICENSE','THIRD_PARTY_NOTICES.md','third_party/licenses/flixel-2.55-MIT.txt','third_party/licenses/flixel-power-tools-Simplified-BSD.txt','third_party/licenses/as3-controller-input-MIT.txt')
foreach($notice in $RequiredNotices){ if(-not(Test-Path -LiteralPath $notice -PathType Leaf)){ Fail "Required release notice missing: $notice" } }
$ExpectedNoticeBlobs=@{
  'third_party/licenses/flixel-2.55-MIT.txt'='5fcbbbdf0d8c043114dbf485b1f0fd7f776dd086'
  'third_party/licenses/flixel-power-tools-Simplified-BSD.txt'='eb85c14d618e818c2bec2bba6ec4a82e5dea7b84'
  'third_party/licenses/as3-controller-input-MIT.txt'='21e3babda57413417549e308c61b9597bd0aa6e1'
}
foreach($notice in $ExpectedNoticeBlobs.Keys){
  $blob=((& git hash-object -- $notice)|Out-String).Trim()
  if($LASTEXITCODE -ne 0 -or $blob -ne $ExpectedNoticeBlobs[$notice]){ Fail "Third-party notice blob mismatch: $notice" }
}
$ExpectedNoticeBlobs.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" } | Set-Content -LiteralPath (Join-Path $ProofDir 'notice-source-identities.txt') -Encoding utf8

$ProviderTarget=Join-Path $AirHome 'lib/android/lib/resources/app_entry/res/drawable-xhdpi/ouya_icon.png'
$ProviderBackup=Join-Path $env:TEMP ('slf-ouya-provider-'+[Guid]::NewGuid().ToString('N')+'.png')
$ProviderExpected='58d4af4a730200aacdb84a8c768d344b463428f6df9ecd4d7dca2e1cabf0e253'
$ProviderWasSanitized=$false
$ValidationKey=Join-Path $ProofDir 'validation-signing.p12'
$Bundletool=Join-Path $ProofDir 'bundletool-all-1.18.3.jar'
try {
  if(-not(Test-Path -LiteralPath $ProviderTarget -PathType Leaf)){ Fail "Expected AIR provider template missing: $ProviderTarget" }
  $providerItem=Get-Item -LiteralPath $ProviderTarget
  $providerHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $ProviderTarget).Hash.ToLowerInvariant()
  if($providerItem.Length -ne 1525 -or $providerHash -ne $ProviderExpected){ Fail "AIR provider template identity changed; refusing sanitation. bytes=$($providerItem.Length) sha256=$providerHash" }
  Copy-Item -LiteralPath $ProviderTarget -Destination $ProviderBackup -Force
  Remove-Item -LiteralPath $ProviderTarget -Force
  $ProviderWasSanitized=$true
  @('classification=INFRA_TOOLCHAIN_PROVIDER_DEFECT','action=temporarily_removed_local_provider_template',"path=$ProviderTarget",'original_bytes=1525',"original_sha256=$ProviderExpected",'restore_required=true') | Set-Content -LiteralPath (Join-Path $ProofDir 'air-provider-template-sanitization.txt') -Encoding utf8

  $Swf=Join-Path $RepoRoot 'bin/SLFforOuya.swf'
  Remove-Item -Force -ErrorAction SilentlyContinue $Swf
  & amxmlc '-load-config+=obj/SLF_for_OuyaConfig.xml' "-output=$Swf"
  if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $Swf -PathType Leaf)){ Fail 'Release SWF compilation failed.' }

  if($Mode -eq 'production'){
    $KeyPath=$env:SLF_ANDROID_KEYSTORE
    $StorePass=$env:SLF_ANDROID_KEYSTORE_PASSWORD
    $ExpectedCert=Normalize-CertSha $env:SLF_ANDROID_EXPECTED_CERT_SHA256
    if([string]::IsNullOrWhiteSpace($KeyPath)){ Fail 'Production build requires SLF_ANDROID_KEYSTORE to name an external PKCS#12 keystore path.' }
    if(-not(Test-Path -LiteralPath $KeyPath -PathType Leaf)){ Fail 'SLF_ANDROID_KEYSTORE does not point to a readable file.' }
    if([string]::IsNullOrWhiteSpace($StorePass)){ Fail 'Production build requires SLF_ANDROID_KEYSTORE_PASSWORD.' }
    if($ExpectedCert.Length -ne 64){ Fail 'Production build requires a valid 64-hex SLF_ANDROID_EXPECTED_CERT_SHA256 fingerprint.' }
    $KeyPath=(Resolve-Path $KeyPath).Path
    $SigningMode='production-external'
  } else {
    $KeyPath=$ValidationKey
    $StorePass='gate2a-validation'
    Remove-Item -Force -ErrorAction SilentlyContinue $ValidationKey
    & adt -certificate -validityPeriod 1 -cn 'Gate 2A Validation' 2048-RSA $ValidationKey $StorePass
    if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $ValidationKey)){ Fail 'Failed to create disposable validation certificate.' }
    $ExpectedCert=''
    $SigningMode='disposable-validation'
  }

  & adt -package -target aab -storetype pkcs12 -keystore $KeyPath -storepass $StorePass $Aab application.xml -C bin SLFforOuya.swf -C icons/android icons/icon_48.png icons/icon_57.png icons/icon_72.png icons/icon_96.png icons/icon_114.png icons/icon_144.png icons/icon_192.png -C . LICENSE THIRD_PARTY_NOTICES.md third_party/licenses/flixel-2.55-MIT.txt third_party/licenses/flixel-power-tools-Simplified-BSD.txt third_party/licenses/as3-controller-input-MIT.txt -platformsdk $AndroidSdk
  if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $Aab -PathType Leaf)){ Fail 'ADT AAB packaging failed.' }
  $AabItem=Get-Item -LiteralPath $Aab
  if($AabItem.Length -le 0){ Fail 'Produced AAB is empty.' }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip=[IO.Compression.ZipFile]::OpenRead($AabItem.FullName)
  try{
    $entries=@($zip.Entries | ForEach-Object FullName)
    $required=@('base/assets/LICENSE','base/assets/THIRD_PARTY_NOTICES.md','base/assets/third_party/licenses/flixel-2.55-MIT.txt','base/assets/third_party/licenses/flixel-power-tools-Simplified-BSD.txt','base/assets/third_party/licenses/as3-controller-input-MIT.txt')
    foreach($entry in $required){ if($entries -notcontains $entry){ Fail "Required notice missing from AAB: $entry" } }
    $ouya=@($entries | Where-Object { $_ -match '(?i)ouya' })
    $allowed=@('base/assets/SLFforOuya.swf','base/res/mipmap-xhdpi-v4/ouya_icon.png')
    $unexpected=@($ouya | Where-Object { $_ -notin $allowed })
    if($unexpected.Count -ne 0){ Fail "Unexpected OUYA-named AAB entries: $($unexpected -join ', ')" }