# Builds an isolated source-only PGSv2 AIR ANE. Never touches Production signer.
param(
  [Parameter(Mandatory=$true)][string]$AirSdk,
  [string]$GradleCommand = 'gradle',
  [string]$OutputDirectory = ''
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
if([string]::IsNullOrWhiteSpace($OutputDirectory)){$OutputDirectory=Join-Path $here 'dist'}
$compc=Join-Path $AirSdk 'bin/compc.bat'
$adt=Join-Path $AirSdk 'bin/adt.bat'
foreach($tool in @($compc,$adt)) {if(-not(Test-Path $tool)){throw "Missing AIR tool: $tool"}}
$fre=Get-ChildItem -LiteralPath $AirSdk -Recurse -Filter 'FlashRuntimeExtensions.jar' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if($null -eq $fre){throw 'Real AIR FlashRuntimeExtensions.jar required to compile FRE bridge'}
$env:AIR_FRE_JAR=$fre.FullName
$env:ANDROID_HOME=if($env:ANDROID_HOME){$env:ANDROID_HOME}else{$env:ANDROID_SDK_ROOT}
if(-not $env:ANDROID_HOME){throw 'ANDROID_HOME or ANDROID_SDK_ROOT required'}
$stage=Join-Path $OutputDirectory 'stage'
New-Item -Force -ItemType Directory -Path $OutputDirectory | Out-Null
if(Test-Path $stage){Remove-Item -Recurse -Force $stage}
New-Item -Force -ItemType Directory -Path $stage | Out-Null
Push-Location $here
try {
  # Gradle uses the real Google SDK dependency. An offline shape-test is not enough.
  & $GradleCommand 'assembleRelease' '--no-daemon'
  if($LASTEXITCODE -ne 0){throw 'Google PGS native Android Gradle build failed'}
  $aar=Get-ChildItem -Path (Join-Path $here 'build/outputs/aar') -Filter '*-release.aar' -File | Select-Object -First 1
  if($null -eq $aar){throw 'Native Gradle compile did not produce an AAR'}
  $native=Join-Path $stage 'native-unpacked'
  [IO.Compression.ZipFile]::ExtractToDirectory($aar.FullName,$native)
  $classes=Join-Path $native 'classes.jar'
  if(-not (Test-Path $classes)){throw 'Native AAR has no classes.jar'}
  $swc=Join-Path $OutputDirectory 'SLF_PGSBridge.swc'
  & $compc ('-source-path='+ (Join-Path $here 'as3')) '-include-classes=com.ramybaheeg.slfport.pgs.PGSBridge' ('-output='+$swc)
  if($LASTEXITCODE -ne 0 -or -not(Test-Path $swc)){throw 'ANE ActionScript SWC compile failed'}
  $swcUnpacked=Join-Path $stage 'swc-unpacked'
  [IO.Compression.ZipFile]::ExtractToDirectory($swc,$swcUnpacked)
  $library=Join-Path $swcUnpacked 'library.swf'
  if(-not(Test-Path $library)){throw 'Compiled SWC missing library.swf'}
  $args=@('-package','-target','ane',(Join-Path $OutputDirectory 'SLF_PGSv2_WIP.ane'),(Join-Path $here 'extension.xml'),'-swc',$swc)
  foreach($arch in @('Android-ARM','Android-ARM64','Android-x64')){
    $folder=Join-Path $stage $arch
    New-Item -Force -ItemType Directory -Path $folder | Out-Null
    Copy-Item $classes (Join-Path $folder 'SLFPGSNative.jar')
    Copy-Item $library (Join-Path $folder 'library.swf')
    $args+=@('-platform',$arch,'-platformoptions',(Join-Path $here 'platform.xml'),'-C',$folder,'.')
  }
  # No production keys or Google sign-in are needed to package a QA-only ANE.
  & $adt @args
  if($LASTEXITCODE -ne 0){throw 'ADT ANE packaging failed'}
  $ane=Join-Path $OutputDirectory 'SLF_PGSv2_WIP.ane'
  if(-not(Test-Path $ane)){throw 'ANE artifact absent after ADT'}
  $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $ane).Hash.ToLowerInvariant()
  "ANE=$ane`nSHA256=$hash`nPRODUCTION_SIGNING_USED=false`nPUBLISHABLE=false" |
    Set-Content -Encoding utf8 (Join-Path $OutputDirectory 'SLF_PGS_ANE_WIP_RECEIPT.txt')
  Write-Output "QA-only ANE created $ane SHA256 $hash; real account/device testing still mandatory"
} finally {Pop-Location}
