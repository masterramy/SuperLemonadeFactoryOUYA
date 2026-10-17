from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED, ZIP_STORED
import hashlib, urllib.request, shutil, json
root=Path.cwd()
out=root/'v191-package'
source=out/'source'
source.mkdir(parents=True,exist_ok=True)
old='SUPER_LIMEADE_FACTORY_1.9_BRANDED_CORRESPONDING_SOURCE.zip'
new='SUPER_LIMEADE_FACTORY_1.9.1_TITLE_MENU_CORRESPONDING_SOURCE.zip'
url='https://github.com/masterramy/SuperLemonadeFactoryOUYA/releases/download/android-v1.9-source/'+old
req=urllib.request.Request(url,headers={'User-Agent':'Limeade-v191-GPL-packager'})
with urllib.request.urlopen(req,timeout=180) as response, (out/old).open('wb') as f:shutil.copyfileobj(response,f)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(out/old)=='e7ae3f4a50212aae419c9c847115739fc8022af37269cc14a17b7417ed1e7534'
with ZipFile(out/old) as z:
 assert z.testzip() is None
 z.extractall(source)
pinned=['src/Registry.as','src/PCIntroState.as','src/PCMenuState.as','src/MobileControls.as',
        'application.xml','data/branding/title_intro_640.png','data/branding/title_menu_640.png',
        'tools/build-emulator-apk.ps1']
for n in pinned:
 d=source/n;d.parent.mkdir(parents=True,exist_ok=True);d.write_bytes((root/n).read_bytes())
p=source/'tools/build-aab.ps1';s=p.read_text();assert "-ne '1.9'" in s
p.write_text(s.replace("-ne '1.9'","-ne '1.9.1'").replace("Expected '1.9'","Expected '1.9.1'").replace('1009000','1009001'))
p=source/'tools/build-apk.ps1';s=p.read_text()
p.write_text(s.replace("versionName='1\.9'","versionName='1\.9\.1'").replace('manifest_version_name_verified=1.9','manifest_version_name_verified=1.9.1').replace('1009000','1009001'))
notes=("\n\n## Android v1.9.1 title-screen presentation update (2026-10-16)\n\n"
"Replaces the illustrated intro and menu presentation with approved native-resolution pixel-art factory backgrounds (data/branding/title_intro_640.png and title_menu_640.png). "
"Retains original input handlers, menu selection, state transitions, controller routing, gameplay maps, player physics, puzzles, audio and save behavior. "
"Adds the title-screen image embeds in Registry.as and relocates the real menu buttons onto a branded menu strip. "
"The version increments to v1.9.1 (code 1009001). Corresponding source includes these exact title assets, modified AS3 files and build tools.\n")
for n in ['MODIFICATIONS.md','SOURCE_DISCLOSURE.md']:
 p=source/n;p.write_text(p.read_text()+notes)
changed=sorted(pinned+['tools/build-aab.ps1','tools/build-apk.ps1','MODIFICATIONS.md','SOURCE_DISCLOSURE.md'])
h={n:sha(source/n) for n in changed}
entry=source/'tools/build-aab-entry.ps1';s=entry.read_text()
marker='  $expected = @{}'
assert s.count(marker)==1
allow=("  # Explicit v1.9.1 presentation delta; frozen gameplay unchanged.\n"
"  $TitleDeltaExpected = @{\n")
allow+=''.join("    '"+n+"'='"+h[n]+"'\n" for n in changed)
allow+=("  }\n  foreach($p in $TitleDeltaExpected.Keys) {\n"
"    $f=Join-Path $RepoRoot ($p -replace '/', [IO.Path]::DirectorySeparatorChar)\n"
"    if(-not(Test-Path -LiteralPath $f -PathType Leaf)){ throw \"Missing title overlay file: $p\" }\n"
"    $got=(Get-FileHash -Algorithm SHA256 -LiteralPath $f).Hash.ToLowerInvariant()\n"
"    if($got -ne $TitleDeltaExpected[$p]){ throw \"Title overlay SHA-256 mismatch: $p\" }\n"
"  }\n")
s=s.replace(marker,allow+marker)
for oldcheck,add in [
 ('if ($path -in $toolingDelta -or $BrandDeltaExpected.ContainsKey($path)) { continue }','toolingDelta'),
 ('if ($path -in $allowedNew -or $BrandDeltaExpected.ContainsKey($path)) { continue }','allowedNew')]:
 assert s.count(oldcheck)==1,oldcheck
 s=s.replace(oldcheck,'if ($path -in $'+add+' -or $BrandDeltaExpected.ContainsKey($path) -or $TitleDeltaExpected.ContainsKey($path)) { continue }')
signerOld='78dc5aaf984d6b5cbf46228f12e44cba2c4c903bce09fd1dedfac8e86832b486'
assert signerOld in s
entry.write_text(s.replace(signerOld,h['tools/build-aab.ps1']))
oldz=ZipFile(out/old)
oldhash={n:hashlib.sha256(oldz.read(n)).hexdigest() for n in oldz.namelist()}
newhash={p.relative_to(source).as_posix():sha(p) for p in source.rglob('*') if p.is_file()}
delta={n for n,digest in newhash.items() if oldhash.get(n)!=digest}
assert delta==set(changed)|{'tools/build-aab-entry.ps1'},(sorted(delta),sorted(changed))
assert not any(n.startswith('src/PCPlayState') or n.startswith('data/level') for n in delta)
# Fail closed on the canonical source identities from the owner's audited kit.
expected={
 'src/PCMenuState.as':'34ca93a2dd2e98d60e9665883eb99fd0a06b31503f3d8e243bffa8586a121e7a',
 'src/PCIntroState.as':'56c49eb773cc9c51a1150f39236364e9a78aeb834f441511f7b11f729464792a',
 'src/MobileControls.as':'f8e3d86608dbe817da93d14ba18d850fb0617de703841228732971890f6037c5',
 'data/branding/title_intro_640.png':'b954b7983b8cff1b26cb6179ee703e48437b132c6d6c043e7e65c1e3106d9aa2',
 'data/branding/title_menu_640.png':'964ff7183b0eca7ab61891f757b6a90d3157e8eefa2b902c8b9443d02131626b'}
for n,digest in expected.items():assert newhash[n]==digest,(n,newhash[n])
with ZipFile(out/new,'w',compression=ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
 for p in sorted(source.rglob('*')):
  if p.is_file():z.write(p,p.relative_to(source).as_posix())
assert ZipFile(out/new).testzip() is None
ssha=sha(out/new)
signbat=r'''@echo off
setlocal
cd /d "%~dp0"
where pwsh.exe >nul 2>&1
if errorlevel 1 (
 echo PowerShell 7 required.
 pause
 exit /b 2
)
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SIGN_V191.ps1"
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
'''
signps=r'''[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$baseDir=$PSScriptRoot
$zip=Join-Path $baseDir 'SOURCE_ZIP'
$dest=Join-Path $baseDir 'SOURCE_V1_9_1'
try {
 if(-not(Test-Path -LiteralPath $zip -PathType Leaf)){throw 'Matching full source ZIP missing.'}
 if((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'SOURCE_SHA'){throw 'Source archive SHA mismatch.'}
 if(-not(Test-Path -LiteralPath $dest -PathType Container)){Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force}
 $entry=Join-Path $dest 'tools/build-aab-entry.ps1'
 if(-not(Test-Path -LiteralPath $entry -PathType Leaf)){throw 'Extraction incomplete.'}
 if((Get-FileHash -LiteralPath $entry -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'ENTRY_SHA'){throw 'Source builder verifier mismatch.'}
 $signer=Join-Path $dest 'tools/build-aab.ps1'
 if((Get-FileHash -LiteralPath $signer -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'SIGNER_SHA'){throw 'Signer verifier mismatch.'}
 $key=(Read-Host 'Existing Google Play upload keystore .p12/.pfx full path').Trim('"')
 if(-not(Test-Path -LiteralPath $key -PathType Leaf)){throw 'Keystore missing.'}
 $key=(Resolve-Path -LiteralPath $key).Path
 if($key.StartsWith([IO.Path]::GetFullPath($dest).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Private keystore must be outside source folder.'}
 $fingerprint='73C5DEBCE610E0655E5EDD1CE8046100184A5C63C8FDB308D12EC1A0D50ED248'
 Write-Host 'Using existing verified owner upload signing certificate.'
 $secure=Read-Host -AsSecureString 'Keystore password (hidden)'
 $bstr=[IntPtr]::Zero
 try {
   $bstr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
   $env:SLF_ANDROID_KEYSTORE_PASSWORD=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
   $env:SLF_ANDROID_KEYSTORE=$key
   $env:SLF_ANDROID_EXPECTED_CERT_SHA256=$fingerprint
   $env:SLF_NO_PAUSE='1'
   Push-Location $dest
   try { & cmd.exe /d /c 'BUILD_AAB_PRODUCTION.bat'; $rc=$LASTEXITCODE } finally { Pop-Location }
   if($rc -ne 0){throw "Production signing/build failed: $rc"}
 } finally {
   Remove-Item Env:SLF_ANDROID_KEYSTORE -ErrorAction SilentlyContinue
   Remove-Item Env:SLF_ANDROID_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
   Remove-Item Env:SLF_ANDROID_EXPECTED_CERT_SHA256 -ErrorAction SilentlyContinue
   Remove-Item Env:SLF_NO_PAUSE -ErrorAction SilentlyContinue
   if($bstr -ne [IntPtr]::Zero){[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)}
   $secure=$null
 }
 $aab=Join-Path $dest 'dist/local-aab/SLF-production.aab'
 if(-not(Test-Path -LiteralPath $aab -PathType Leaf)){throw 'Builder reported success without AAB.'}
 $receipt=Join-Path $baseDir 'SLF_V191_NONSECRET_RELEASE_RECEIPT.txt'
 $hash=(Get-FileHash -LiteralPath $aab -Algorithm SHA256).Hash.ToLowerInvariant()
 @('package=com.ramybaheeg.slfport','versionName=1.9.1','versionCode=1009001',
   "upload_certificate_sha256=$fingerprint","aab_sha256=$hash",
   "aab_bytes=$((Get-Item $aab).Length)",'play_upload_performed=false','publication_performed=false') |
     Set-Content -LiteralPath $receipt -Encoding utf8
 Write-Host "NEW SIGNED AAB: $aab" -ForegroundColor Green
 Write-Host "Nonsecret proof: $receipt"
} catch {
 Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red
 exit 1
}
'''
signps=signps.replace('SOURCE_ZIP',new).replace('SOURCE_SHA',ssha).replace('ENTRY_SHA',sha(entry)).replace('SIGNER_SHA',h['tools/build-aab.ps1'])
pubbat=r'''@echo off
setlocal
cd /d "%~dp0"
where gh.exe >nul 2>&1
if errorlevel 1 (
 echo GitHub CLI required: https://cli.github.com
 pause
 exit /b 2
)
where pwsh.exe >nul 2>&1
if errorlevel 1 (
 echo PowerShell 7 required.
 pause
 exit /b 2
)
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PUBLISH_SOURCE_V191.ps1"
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
'''
pubps=r'''[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo='masterramy/SuperLemonadeFactoryOUYA'
$tag='android-v1.9.1-source'
$asset=Join-Path $PSScriptRoot 'SOURCE_ZIP'
try {
 if(-not(Test-Path -LiteralPath $asset -PathType Leaf)){throw 'Source ZIP missing'}
 if((Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'SOURCE_SHA'){throw 'Source ZIP SHA mismatch'}
 & gh auth status
 if($LASTEXITCODE -ne 0){throw 'Sign in using gh auth login'}
 $raw=& gh api "repos/$repo"
 if($LASTEXITCODE -ne 0){throw 'Repository check failed'}
 $meta=$raw | ConvertFrom-Json
 if($meta.private -or $meta.full_name -ne $repo){throw 'Repository is not the expected public repo'}
 $base='0d5fd0bb63558ad6659ba31552deaede4745382b'
 & gh api "repos/$repo/commits/$base" 1>$null
 if($LASTEXITCODE -ne 0){throw 'Pinned source commit inaccessible'}
 $answer=Read-Host 'Type PUBLISH to publicly post v1.9.1 corresponding source'
 if($answer -cne 'PUBLISH'){throw 'Cancelled by owner'}
 $existing=& gh release view $tag --repo $repo --json url --jq '.url' 2>$null
 if($LASTEXITCODE -eq 0 -and $existing){throw "Public release already exists; inspect $existing. Not overwriting."}
 & gh release create $tag $asset --repo $repo --target $base --title 'Super Limeade Factory Android v1.9.1 - Corresponding Source' --notes-file (Join-Path $PSScriptRoot 'SOURCE_RELEASE_NOTES.md') --latest=false
 if($LASTEXITCODE -ne 0){throw 'GitHub release failed'}
 $link="https://github.com/$repo/releases/tag/$tag"
 $link|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'SOURCE_RELEASE_URL.txt')
 Write-Host "PUBLIC SOURCE LINK: $link" -ForegroundColor Green
} catch {
 Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red
 exit 1
}
'''
pubps=pubps.replace('SOURCE_ZIP',new).replace('SOURCE_SHA',ssha)
notes=f'''# Super Limeade Factory Android v1.9.1 corresponding source
This GitHub release includes the complete corresponding source for Android v1.9.1,
package com.ramybaheeg.slfport, versionCode 1009001, including new title/menu art and build tools.
Download the attached ZIP asset. No installable AAB or signing credentials included.
SHA256: {ssha}
Original Rev52 gameplay source: 0d5fd0bb63558ad6659ba31552deaede4745382b.
Independent modification based on Super Lemonade Factory, originally developed by Shane Brouwer / Initials Video Games, not sponsored or endorsed by them.
'''
readme=f'''SUPER LIMEADE FACTORY v1.9.1 - WINDOWS SOURCE AND SIGNING KIT
THE TITLE AND MAIN MENU HAVE BEEN BUILT AND TESTED IN AN ANDROID EMULATOR.
THIS KIT DOES NOT CONTAIN AN OWNER-SIGNED AAB OR PRIVATE KEY.

1. Extract the entire kit ZIP.
2. Double-click SIGN_V191.bat. Use SAME existing private Play upload keystore;
   password is masked and never uploaded to GitHub, Drive, or ChatGPT.
3. Verify v1.9.1/1009001 signed AAB in SOURCE_V1_9_1/dist/local-aab/.
4. Run PUBLISH_SOURCE_V191.bat to post the NEW public GPL source,
   while preserving the already public v1.9 source release.
5. In Play Console replace pending 1.9 code1009000 with new 1.9.1 code1009001.
   Listing's source reference should be:
   https://github.com/masterramy/SuperLemonadeFactoryOUYA/releases/tag/android-v1.9.1-source
6. Briefly smoke-test signed version on real phone: intro/menu/Play/touch/save.
7. Owner authorizes final Google Play Production submission explicitly.

FULL SOURCE ZIP: {new}
FULL SOURCE SHA256: {ssha}
FULL SOURCE BYTES: {(out/new).stat().st_size}
GAMEPLAY MAPS, PHYSICS, SAVES AND PUZZLES UNCHANGED.
'''
kit='SUPER_LIMEADE_FACTORY_V1.9.1_TITLE_MENU_WINDOWS_RELEASE_KIT.zip'
files={'SIGN_V191.bat':signbat,'SIGN_V191.ps1':signps,
       'PUBLISH_SOURCE_V191.bat':pubbat,'PUBLISH_SOURCE_V191.ps1':pubps,
       'SOURCE_RELEASE_NOTES.md':notes,'START_HERE.txt':readme,
       'RELEASE_DIFF.json':json.dumps({'version':'1.9.1','versionCode':1009001,
          'gameplay_changed':False,'delta':sorted(delta),'source_sha256':ssha},indent=2)}
with ZipFile(out/kit,'w',compression=ZIP_STORED,allowZip64=True) as z:
 z.write(out/new,new)
 for name,data in files.items():z.writestr(name,data)
assert ZipFile(out/kit).testzip() is None
receipt={'source':new,'source_bytes':(out/new).stat().st_size,'source_sha256':ssha,
 'kit':kit,'kit_bytes':(out/kit).stat().st_size,'kit_sha256':sha(out/kit),
 'delta':sorted(delta),'gameplay_changes':False}
(out/'RELEASE_RECEIPT.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt,indent=2))
