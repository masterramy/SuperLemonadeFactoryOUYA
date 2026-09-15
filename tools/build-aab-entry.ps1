param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('validation','production')]
  [string]$Mode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$FrozenCommit = 'afc2e65a65dc95e35ef3391b92be8adc7827e16f'
$FrozenTree = '999b5c3392f8c75e501c32b009880bd88351f80f'
$RepoFullName = 'masterramy/SuperLemonadeFactoryOUYA'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$OutRoot = Join-Path $RepoRoot 'dist/local-aab'
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
    '.github/workflows/gate2a-windows-aab-builders-validation.yml'
  )
  $allowedNew = @('tools/build-aab-entry.ps1')
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
    $actual = Get-GitBlobSha1 $local
    if ($actual -ne $expected[$path]) { throw "Downloaded archive source mismatch for $path. Expected Git blob $($expected[$path]), got $actual." }
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

  $buildScript = Join-Path $ScriptDir 'build-aab.ps1'
  if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) { throw "Core AAB builder is missing: $buildScript" }
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
    "error=$message"
  ) | Set-Content -LiteralPath $ErrorLog -Encoding utf8
  Write-Host ''
  Write-Host 'AAB BUILD FAILED' -ForegroundColor Red
  Write-Host $message -ForegroundColor Red
  Write-Host "Full error log: $ErrorLog" -ForegroundColor Yellow
  exit 1
}
finally {
  $env:PATH = $oldPath
  if ($shimDir) { Remove-Item -LiteralPath $shimDir -Recurse -Force -ErrorAction SilentlyContinue }
}
