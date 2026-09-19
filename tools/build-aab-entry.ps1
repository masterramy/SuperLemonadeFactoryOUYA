param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('validation','production')]
  [string]$Mode,

  [ValidateSet('aab','apk')]
  [string]$Artifact = 'aab'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$FrozenCommit = '079a68ba800af3d15e97f140cc5ab1df7ce38332'
$FrozenTree = 'bf7ab61aa895310285b8d3aaf19c73786d664b0b'
$RepoFullName = 'masterramy/SuperLemonadeFactoryOUYA'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$OutRoot = Join-Path $RepoRoot ("dist/local-" + $Artifact)
$ErrorLog = Join-Path $OutRoot 'LAST_BUILD_ERROR.txt'
$ProofDir = Join-Path $OutRoot "$Mode-proof"
New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
Remove-Item -LiteralPath $ErrorLog -Force -ErrorAction SilentlyContinue

function Get-GitBlobSha1([string]$Path) {
  $item = Get-Item -LiteralPath $Path -ErrorAction Stop
  $header = [Text.Encoding]::ASCII.GetBytes("blob $($item.Length)`0")
  $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
  try {
    $hash.AppendData($header)
    $stream = [IO.File]::OpenRead($item.FullName)
    try {
      $buffer = [byte[]]::new(1024 * 1024)
      while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $hash.AppendData($buffer, 0, $read)
      }
    } finally {
      $stream.Dispose()
    }
    return ([Convert]::ToHexString($hash.GetHashAndReset())).ToLowerInvariant()
  } finally {
    $hash.Dispose()
  }
}

function Get-GitBlobSha1AfterCrlfToLf([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
  $normalized = [IO.MemoryStream]::new()
  try {
    for ($i = 0; $i -lt $bytes.Length; $i++) {
      if ($bytes[$i] -eq 13 -and ($i + 1) -lt $bytes.Length -and $bytes[$i + 1] -eq 10) {
        $normalized.WriteByte(10)
        $i++
      } else {
        $normalized.WriteByte($bytes[$i])
      }
    }
    $payload = $normalized.ToArray()
    $header = [Text.Encoding]::ASCII.GetBytes("blob $($payload.Length)`0")
    $sha1 = [Security.Cryptography.SHA1]::Create()
    try {
      $combined = [byte[]]::new($header.Length + $payload.Length)
      [Array]::Copy($header, 0, $combined, 0, $header.Length)
      [Array]::Copy($payload, 0, $combined, $header.Length, $payload.Length)
      return ([Convert]::ToHexString($sha1.ComputeHash($combined))).ToLowerInvariant()
    } finally {
      $sha1.Dispose()
    }
  } finally {
    $normalized.Dispose()
  }
}

function Verify-ArchiveSource {
  $treeUrl = "https://api.github.com/repos/$RepoFullName/git/trees/${FrozenTree}?recursive=1"
  try {
    $remote = Invoke-RestMethod -Uri $treeUrl -Headers @{ 'User-Agent'='SuperLemonadeFactory-LocalAABBuilder' }
  } catch {
    throw "Could not verify the downloaded source archive against the frozen GitHub tree. Internet access to api.github.com is required for archive-mode provenance. $($_.Exception.Message)"
  }
  if ($remote.truncated -eq $true) { throw 'GitHub returned a truncated frozen source tree; refusing archive-mode provenance.' }
  if (("$($remote.sha)").ToLowerInvariant() -ne $FrozenTree) { throw "Frozen tree identity mismatch. Expected $FrozenTree, got $($remote.sha)." }

  $toolingDelta = @(
    'BUILD_AAB_VALIDATION.bat',
    'BUILD_AAB_PRODUCTION.bat',
    'tools/build-aab-entry.ps1',
    'tools/bootstrap-local-toolchain.ps1',
    '.github/workflows/gate2a-windows-aab-builders-validation.yml'
  )
  $allowedNew = @(
    'BUILD_APK_VALIDATION.bat',
    'BUILD_APK_PRODUCTION.bat',
    'BUILD_ANDROID_VALIDATION.bat',
    'BUILD_ANDROID_PRODUCTION.bat',
    'BUILD_WINDOWS_README.txt',
    'tools/build-apk.ps1',
    '.github/workflows/gate2a-adaptive-source-builders-validation.yml',
    '.github/workflows/gate2a-rev48-final-source-package.yml'
  )
  $expected = @{}
  foreach ($entry in @($remote.tree)) {
    if ($entry.type -eq 'blob') { $expected[$entry.path] = ("$($entry.sha)").ToLowerInvariant() }
  }
  if ($expected.Count -eq 0) { throw 'Frozen GitHub tree contained no blob entries.' }

  $verified = 0
  foreach ($path in ($expected.Keys | Sort-Object)) {
    if ($path -in $toolingDelta) { continue }
    $local = Join-Path $RepoRoot ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { throw "Downloaded archive is missing frozen source file: $path" }
    $expectedBlob = $expected[$path]
    $actualRaw = Get-GitBlobSha1 $local
    if ($actualRaw -ne $expectedBlob) {
      $actualLf = Get-GitBlobSha1AfterCrlfToLf $local
      if ($actualLf -ne $expectedBlob) {
        throw "Downloaded archive source mismatch for $path. Expected Git blob $expectedBlob, raw=$actualRaw, crlf_to_lf=$actualLf."
      }
    }
    $verified++
  }

  $localFiles = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File | ForEach-Object {
    [IO.Path]::GetRelativePath($RepoRoot, $_.FullName).Replace('\','/')
  }
  foreach ($path in $localFiles) {
    if ($path -like 'dist/*') { continue }
    if ($path -eq 'bin/SLFforOuya.swf') { continue }
    if ($expected.ContainsKey($path)) { continue }
    if ($path -in $allowedNew) { continue }
    throw "Downloaded archive contains an unexpected source file: $path"
  }

  return $verified
}

function New-FrozenGitShim {
  param([string]$Directory)
  New-Item -ItemType Directory -Force -Path $Directory | Out-Null
  $shim = @"
@echo off
if /I "%~1"=="rev-parse" (
  if /I "%~2"=="HEAD" (echo $FrozenCommit) else (echo $FrozenTree)
  exit /b 0
)
if /I "%~1"=="status" exit /b 0
if /I "%~1"=="hash-object" (
  if /I "%~3"=="third_party/licenses/flixel-2.55-MIT.txt" (echo 5fcbbbdf0d8c043114dbf485b1f0fd7f776dd086& exit /b 0)
  if /I "%~3"=="third_party/licenses/flixel-power-tools-Simplified-BSD.txt" (echo eb85c14d618e818c2bec2bba6ec4a82e5dea7b84& exit /b 0)
  if /I "%~3"=="third_party/licenses/as3-controller-input-MIT.txt" (echo 21e3babda57413417549e308c61b9597bd0aa6e1& exit /b 0)
)
echo ERROR: archive provenance git shim received unsupported command: %* 1>&2
exit /b 2
"@
  Set-Content -LiteralPath (Join-Path $Directory 'git.cmd') -Value $shim -Encoding ascii
}

$oldPath = $env:PATH
$shimDir = $null
$provenanceMode = $null
$verifiedCount = 0
try {
  Set-Location $RepoRoot
  $gitDir = Join-Path $RepoRoot '.git'
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ((Test-Path -LiteralPath $gitDir) -and $git) {
    $provenanceMode = 'git-checkout'
  } else {
    $provenanceMode = 'archive-frozen-tree'
    $verifiedCount = Verify-ArchiveSource
    $shimDir = Join-Path $env:TEMP ('slf-frozen-git-shim-' + [Guid]::NewGuid().ToString('N'))
    New-FrozenGitShim $shimDir
    $env:PATH = "$shimDir;$oldPath"
  }

  $bootstrapScript = Join-Path $ScriptDir 'bootstrap-local-toolchain.ps1'
  if (-not (Test-Path -LiteralPath $bootstrapScript -PathType Leaf)) { throw "Local toolchain bootstrap is missing: $bootstrapScript" }
  . $bootstrapScript
  Initialize-SlfLocalToolchain

  $buildName = if ($Artifact -eq 'apk') { 'build-apk.ps1' } else { 'build-aab.ps1' }
  $buildScript = Join-Path $ScriptDir $buildName
  if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) { throw "Core $Artifact builder is missing: $buildScript" }
  & $buildScript -Mode $Mode

  New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
  @(
    "provenance_mode=$provenanceMode",
    "frozen_product_commit=$FrozenCommit",
    "frozen_product_tree=$FrozenTree",
    "archive_verified_blob_count=$verifiedCount"
  ) | Set-Content -LiteralPath (Join-Path $ProofDir 'archive-source-verification.txt') -Encoding utf8
  Remove-Item -LiteralPath $ErrorLog -Force -ErrorAction SilentlyContinue
}
catch {
  New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null
  $message = $_.Exception.Message
  @(
    "timestamp_utc=$([DateTime]::UtcNow.ToString('o'))",
    "mode=$Mode",
    "artifact=$Artifact",
    "error=$message"
  ) | Set-Content -LiteralPath $ErrorLog -Encoding utf8
  Write-Host ''
  Write-Host "$($Artifact.ToUpperInvariant()) BUILD FAILED" -ForegroundColor Red
  Write-Host $message -ForegroundColor Red
  Write-Host "Full error log: $ErrorLog" -ForegroundColor Yellow
  exit 1
}
finally {
  $env:PATH = $oldPath
  if ($shimDir) { Remove-Item -LiteralPath $shimDir -Recurse -Force -ErrorAction SilentlyContinue }
}
