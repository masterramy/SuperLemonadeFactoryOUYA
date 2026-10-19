param([ValidateSet('phone','emulator')][string]$Target='phone',[switch]$IncludePGS,[string]$PgsGameId='',
      [string]$PgsQaKeystore='', [string]$PgsQaCertSha256='', [switch]$PgsPackagingSmokeOnly)
# TEST-ONLY Android APK. Uses separate .dev app ID and disposable or owner-held QA-only signer.
# Must never touch the personal Play upload key or production-release scripts.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $root
$toolchain=if($env:SLF_TOOLCHAIN_ROOT){$env:SLF_TOOLCHAIN_ROOT}else{Join-Path $env:LOCALAPPDATA 'SuperLemonadeFactory\toolchain'}
$air=if($env:AIR_HOME -and (Test-Path -LiteralPath (Join-Path $env:AIR_HOME 'bin\adt.bat'))){
    $env:AIR_HOME
}else{
    $adtOnPath=Get-Command 'adt.bat' -ErrorAction SilentlyContinue
    if($adtOnPath){Split-Path -Parent (Split-Path -Parent $adtOnPath.Source)}
    else{Join-Path $toolchain 'air-51.3.4.3'}
}
$adt=Join-Path $air 'bin\adt.bat'
if(-not(Test-Path -LiteralPath $adt)){throw "AIR ADT missing: $adt"}
# Use the exact JDK 17 installed by the local release kit or an isolated CI job.
# Never download JDKs, change machine-wide Java, or pick newer Java by accident.
$javaHomeCandidate=$null
if($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))){
    $javaHomeCandidate=$env:JAVA_HOME
} else {
    $jdk=Get-ChildItem -LiteralPath (Join-Path $toolchain 'jdk17') -Recurse -Filter 'java.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if($jdk){$javaHomeCandidate=Split-Path -Parent (Split-Path -Parent $jdk.FullName)}
}
if(-not $javaHomeCandidate){throw 'Java 17 not found in JAVA_HOME or the local cached toolchain. Build will not install software.'}
$env:JAVA_HOME=$javaHomeCandidate
$env:PATH="$(Join-Path $env:JAVA_HOME 'bin');$env:PATH"
# Java prints version details to STDERR by design. Windows PowerShell 5.1
# turns stderr into NativeCommandError when ErrorActionPreference is Stop.
$oldPreference=$ErrorActionPreference
try {
    $ErrorActionPreference='Continue'
    $javaVersion=(& (Join-Path $env:JAVA_HOME 'bin\java.exe') '-version' 2>&1 | Out-String)
} finally {$ErrorActionPreference=$oldPreference}
if($LASTEXITCODE -ne 0 -or $javaVersion -notmatch 'version "17\.') {throw "Expected Java 17; actual: $javaVersion"}
$sdkCandidates=@($env:ANDROID_SDK_ROOT,$env:ANDROID_HOME,(Join-Path $toolchain 'android-sdk'),(Join-Path $env:LOCALAPPDATA 'Android\Sdk'))
$sdk=$null
foreach($candidate in $sdkCandidates){if(-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath (Join-Path $candidate 'platforms\android-36\android.jar'))) { $sdk=$candidate;break }}
if(-not $sdk){throw 'Android SDK platform 36 not found. No downloads attempted.'}
$srcSwf=Join-Path $root 'bin\SLFforOuya-postlaunch-wip.swf'
if(-not(Test-Path -LiteralPath $srcSwf)){throw 'First run COMPILE_POSTLAUNCH_WIP.bat successfully. Missing compiled SWF.'}
$outDir=Join-Path $root 'dist\postlaunch-disposable'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$apkFile=if($Target -eq 'emulator'){'SLF-DEV-EMULATOR-x64.apk'}else{'SLF-DEV-PHONE.apk'}
$apk=Join-Path $outDir $apkFile
$swf=Join-Path $root 'bin\SLFforOuya.swf'
$devDescriptor=Join-Path $outDir 'application.dev.xml'
$aneDir=Join-Path $root 'native/pgs-ane/build/ane'
$aneFile=Join-Path $aneDir 'SLFPGSSavedGames-dev.ane'
if($IncludePGS){
    if($Target -ne 'phone'){throw 'PGS ANE is ARM/ARM64 only; no x64 emulator support.'}
    if(!(Test-Path -LiteralPath $aneFile)){throw "Missing independently compiled DEV ANE: $aneFile"}
    if($PgsGameId -notmatch '^[1-9][0-9]{5,19}$'){throw 'Numeric PGS app ID required for DEV-only integration.'}
    if($PgsPackagingSmokeOnly -and $PgsQaKeystore){throw 'Smoke-only mode must not use owner QA keys.'}
    if(-not $PgsPackagingSmokeOnly -and [string]::IsNullOrWhiteSpace($PgsQaKeystore)){
        throw 'Stable QA keystore required for authenticated PGS testing'
    }
    if(-not $PgsPackagingSmokeOnly -and $PgsQaCertSha256 -notmatch '^[0-9a-fA-F]{64}$'){
        throw 'Expected independent QA signing certificate SHA-256 required.'
    }
} elseif($PgsQaKeystore -or $PgsQaCertSha256 -or $PgsPackagingSmokeOnly){
    throw 'PGS signing options require -IncludePGS.'
}

$temporaryKeyGenerated=((-not $IncludePGS) -or [bool]$PgsPackagingSmokeOnly)
$key=if($temporaryKeyGenerated){Join-Path $outDir 'delete-after-packaging-disposable.p12'}else{
    if(-not(Test-Path -LiteralPath $PgsQaKeystore -PathType Leaf)){throw 'Owner QA keystore missing; refusing to create or rotate.'}
    (Resolve-Path -LiteralPath $PgsQaKeystore).Path
}
$testPassword=if($temporaryKeyGenerated){'slf-only-disposable-qa'}else{
    if([string]::IsNullOrEmpty($env:SLF_PGS_QA_STOREPASS)){throw 'SLF_PGS_QA_STOREPASS environment secret required.'}
    $env:SLF_PGS_QA_STOREPASS
}
# Leave public release descriptor and uploaded source unchanged.
$descriptor=[IO.File]::ReadAllText((Join-Path $root 'application.xml'))
if(-not $descriptor.Contains('<id>com.ramybaheeg.slfport</id>')){throw 'Unexpected source package; refusing descriptor change.'}
$descriptor=$descriptor.Replace('<id>com.ramybaheeg.slfport</id>','<id>com.ramybaheeg.slfport.dev</id>')
$descriptor=$descriptor.Replace('<name>Super Limeade Factory</name>','<name>Super Limeade Factory DEV</name>')
if($IncludePGS){
    $open='<manifest android:installLocation="auto">'
    $app='<application android:appCategory="game" android:resizeableActivity="false">'
    $oldSdk='<uses-sdk android:minSdkVersion="21" android:targetSdkVersion="36" />'
    $pgsSdk='<uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36" />'
    if(-not $descriptor.Contains($oldSdk)){throw 'Unknown game SDK manifest; refusing PGS minSdk change.'}
    $descriptor=$descriptor.Replace($oldSdk,$pgsSdk)
    if(-not $descriptor.Contains($open) -or -not $descriptor.Contains($app)){throw 'Unknown Android manifest, refusing PGS injection.'}
    $descriptor=$descriptor.Replace($open,$open+"`n"+'  <uses-permission android:name="android.permission.INTERNET"/>')
    $pgsValue='\u003'+$PgsGameId
    $descriptor=$descriptor.Replace($app,$app+"`n"+'  <meta-data android:name="com.google.android.gms.games.APP_ID" android:value="'+$pgsValue+'"/>')
    if($PgsPackagingSmokeOnly){
        $descriptor=$descriptor.Replace($app,$app+"`n"+'  <meta-data android:name="com.ramybaheeg.slfport.pgs.QA_SMOKE_ONLY" android:value="true"/>')
    }
    $index=$descriptor.LastIndexOf('</application>')
    if($index -lt 0){throw 'Missing AIR root closing tag.'}
    $descriptor=$descriptor.Insert($index,"  <extensions>`n    <extensionID>com.ramybaheeg.slfport.pgs.savedgames</extensionID>`n  </extensions>`n")
}

[IO.File]::WriteAllText($devDescriptor,$descriptor,(New-Object System.Text.UTF8Encoding($false)))
$provider=Join-Path $air 'lib\android\lib\resources\app_entry\res\drawable-xhdpi\ouya_icon.png'
$providerBackup=Join-Path $env:TEMP ('slf-dev-provider-'+[Guid]::NewGuid().ToString('N')+'.png')
$sanitized=$false
$providerDigest='58d4af4a730200aacdb84a8c768d344b463428f6df9ecd4d7dca2e1cabf0e253'
try {
    Copy-Item -LiteralPath $srcSwf -Destination $swf -Force
    if($temporaryKeyGenerated){
        & $adt -certificate -validityPeriod 1 -cn 'SLF Disposable Development QA' 2048-RSA $key $testPassword
        if($LASTEXITCODE -ne 0 -or -not(Test-Path $key)){throw 'Could not create temporary test certificate.'}
    }
    if(Test-Path -LiteralPath $provider){
        $actual=(Get-FileHash -Algorithm SHA256 -LiteralPath $provider).Hash.ToLowerInvariant()
        if($actual -ne $providerDigest){throw 'Unknown AIR provider icon template; refusing to modify SDK files.'}
        Copy-Item -LiteralPath $provider -Destination $providerBackup -Force
        Remove-Item -LiteralPath $provider -Force
        $sanitized=$true
    }
    Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
    $targetArgs=if($Target -eq 'emulator'){@('-target','apk-emulator','-arch','x64')}else{@('-target','apk','-arch','armv8')}
    $pgsArgs=if($IncludePGS){@('-extdir',$aneDir)}else{@()}
    & $adt -package @targetArgs -storetype pkcs12 -keystore $key -storepass $testPassword $apk $devDescriptor @pgsArgs `
        -C bin SLFforOuya.swf `
        -C icons/android icons/icon_48.png icons/icon_57.png icons/icon_72.png icons/icon_96.png icons/icon_114.png icons/icon_144.png icons/icon_192.png `
        -C . LICENSE THIRD_PARTY_NOTICES.md MODIFICATIONS.md SOURCE_DISCLOSURE.md -platformsdk $sdk
    if($LASTEXITCODE -ne 0 -or -not(Test-Path $apk)){throw 'Disposable APK packaging failed.'}
    # Validate actual native ABI in the generated APK, not merely the ADT exit code.
    # New Android handsets frequently reject 32-bit-only ARM packages.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $apkZip=[IO.Compression.ZipFile]::OpenRead($apk)
    $abiValid=$false
    try {
        $libs=@($apkZip.Entries | Where-Object { $_.FullName -like 'lib/*/*.so' } | ForEach-Object { $_.FullName })
        $requiredPrefix=if($Target -eq 'emulator'){'lib/x86_64/'}else{'lib/arm64-v8a/'}
        $abiValid=(@($libs | Where-Object { $_.StartsWith($requiredPrefix) }).Count -gt 0)
    } finally {$apkZip.Dispose()}
    if(-not $abiValid){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw "QA APK is missing expected $requiredPrefix native libraries (has: $($libs -join ','))"
    }
    $aapt=Join-Path $sdk 'build-tools\36.0.0\aapt.exe'
    if(-not(Test-Path $aapt)){throw 'Cannot verify package identity: Android aapt build tools 36 missing.'}
    $badging=(& $aapt dump badging $apk | Out-String)
    if($LASTEXITCODE -ne 0 -or $badging -notmatch "package: name='com\.ramybaheeg\.slfport\.dev'"){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw 'APK is not isolated under expected .dev package name; deleted for safety.'
    }
    $minRequired=if($IncludePGS){'24'}else{'21'}
    if($badging -notmatch "sdkVersion:'$minRequired'"){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw "DEV APK minSDK not $minRequired; refusing wrong compatibility build."
    }
    if($badging -notmatch "versionCode='1009001'" -or $badging -notmatch "versionName='1\.9\.1'" -or
       $badging -notmatch "targetSdkVersion:'36'") {
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw 'Disposable APK manifest/version identity unexpected; deleted for safety.'
    }
    $apkSignTool=Join-Path $sdk 'build-tools\36.0.0\apksigner.bat'
    if(-not (Test-Path -LiteralPath $apkSignTool)){throw 'Cannot verify QA APK certificate; apksigner unavailable.'}
    $sig=(& $apkSignTool verify --print-certs $apk 2>&1 | Out-String)
    if($LASTEXITCODE -ne 0){throw "Disposable APK signature invalid: $sig"}
    $certMatch=[regex]::Match($sig, '(?im)Signer #1 certificate SHA-256 digest:\s*([0-9a-fA-F]{64})')
    if(-not $certMatch.Success){throw 'Cannot identify APK signing certificate.'}
    $certSha=$certMatch.Groups[1].Value.ToLowerInvariant()
    if(-not $temporaryKeyGenerated -and $certSha -ne $PgsQaCertSha256.ToLowerInvariant()){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw 'Unexpected QA certificate fingerprint; refusing unapproved signing identity.'
    }
    if($certSha -eq '73c5debce610e0655e5edd1ce8046100184a5c63c8fdb308d12ec1a0d50ed248'){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw 'Refusing disposable build signed by Production upload certificate.'
    }
    $permissions=(& $aapt dump permissions $apk 2>&1 | Out-String)
    $permissionLines=@($permissions -split "`n" | Where-Object { $_ -match 'uses-permission' })
    $badPermission=@($permissionLines | Where-Object { $_ -notmatch 'android.permission.INTERNET' })
    if($LASTEXITCODE -ne 0 -or ((-not $IncludePGS) -and $permissionLines.Count -gt 0) -or
       ($IncludePGS -and ($permissionLines.Count -ne 1 -or $badPermission.Count -gt 0))){
        Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue
        throw 'Unexpected Android permission in disposable QA APK.'
    }
    $sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $apk).Hash.ToLowerInvariant()
    $receiptPermission=if($IncludePGS){"INTERNET"}else{"none"}
    $receiptLines=@("pgs_native_ane_included=$([bool]$IncludePGS)", "pgs_packaging_smoke_only=$([bool]$PgsPackagingSmokeOnly)", "pgs_qa_signer_stable=$(-not $temporaryKeyGenerated)", "pgs_remote_auth_verified=false", "status=QA_BUILD_PASS_NOT_PRODUCTION", "package=com.ramybaheeg.slfport.dev", "purpose=independent_test_only", "target=$Target", "aab_created=false", "prod_signing_key_touched=false", "bytes=$((Get-Item $apk).Length)", "sha256=$sha", "test_signer_sha256=$certSha", "permissions=$receiptPermission", "required_native_abi=$requiredPrefix")
    # Keep a distinct signed receipt for each APK ABI; the second build must
    # never overwrite the verification evidence for the first one.
    $specificReceipt=if($Target -eq 'phone'){'SLF_DEV_PHONE_RECEIPT.txt'}else{'SLF_DEV_EMULATOR_RECEIPT.txt'}
    $receiptLines | Set-Content -LiteralPath (Join-Path $outDir $specificReceipt) -Encoding utf8
    $receiptLines | Set-Content -LiteralPath (Join-Path $outDir 'SLF_DISPOSABLE_APK_RECEIPT.txt') -Encoding utf8
    Write-Host "Built ISOLATED development APK: $apk" -ForegroundColor Green
    Write-Host 'This DEV-only package cannot update the Google Play app. Auth and two-device sync are unverified.'
}
finally {
    if($temporaryKeyGenerated -and (Test-Path $key)){Remove-Item -LiteralPath $key -Force}
    if($sanitized){Copy-Item -LiteralPath $providerBackup -Destination $provider -Force}
    Remove-Item -LiteralPath $providerBackup -Force -ErrorAction SilentlyContinue
}
