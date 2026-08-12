param(
  [string]$Prefix = $(if ($env:AI_DEVOPS_HOME) { $env:AI_DEVOPS_HOME } else { Join-Path $env:LOCALAPPDATA 'ai-devops-suite' }),
  [string]$Version = '0.3.2',
  [string]$SpecVersion = '0.1.1',
  [string]$SourceRoot = '',
  [switch]$Start,
  [switch]$EnableAutostart
)

$ErrorActionPreference = 'Stop'
$Prefix = [IO.Path]::GetFullPath($Prefix)
$Architecture = switch ($env:PROCESSOR_ARCHITECTURE.ToUpperInvariant()) {
  'AMD64' { 'amd64' }
  'ARM64' { 'arm64' }
  default { throw "Unsupported Windows architecture: $env:PROCESSOR_ARCHITECTURE" }
}
if ($Architecture -eq 'arm64') {
  throw 'The current Windows release provides amd64 binaries only.'
}

$Products = @(
  @{ Repo='lifecycle-spec'; Tag="v$SpecVersion"; Asset="lifecycle-validate-windows-$Architecture.exe"; Target='lifecycle-validate.exe' },
  @{ Repo='ai-dev-cycle-manager'; Tag="v$Version"; Asset="devcycle-windows-$Architecture.exe"; Target='devcycle.exe' },
  @{ Repo='infrastructure-discovery'; Tag="v$Version"; Asset="infrascout-windows-$Architecture.exe"; Target='infrascout.exe' },
  @{ Repo='fleet-observability'; Tag="v$Version"; Asset="fleetctl-windows-$Architecture.exe"; Target='fleetctl.exe' },
  @{ Repo='release-validation'; Tag="v$Version"; Asset="releaseguard-windows-$Architecture.exe"; Target='releaseguard.exe' }
)

$Stage = Join-Path ([IO.Path]::GetTempPath()) ("ai-devops-install-" + [guid]::NewGuid().ToString('N'))
$Bin = Join-Path $Prefix 'bin'
$Examples = Join-Path $Prefix 'examples'
$Config = Join-Path $Prefix 'config'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$StagedBin = Join-Path $Stage 'bin'
$BackupBin = Join-Path $Stage 'backup'

function Receive-File([string]$Repo, [string]$Tag, [string]$Name, [string]$Destination) {
  if ($SourceRoot) {
    $Source = Join-Path ([IO.Path]::GetFullPath($SourceRoot)) (Join-Path $Repo $Name)
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Offline asset not found: $Source" }
    Copy-Item -LiteralPath $Source -Destination $Destination
    return
  }
  $Url = "https://github.com/GeneJie199/$Repo/releases/download/$Tag/$Name"
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination
}

try {
  New-Item -ItemType Directory -Force -Path $Stage,$StagedBin,$BackupBin,$Bin,$Examples,$Config | Out-Null
  foreach ($Product in $Products) {
    $RepoStage = Join-Path $Stage $Product.Repo
    New-Item -ItemType Directory -Force -Path $RepoStage | Out-Null
    $AssetPath = Join-Path $RepoStage $Product.Asset
    $ChecksumPath = Join-Path $RepoStage 'checksums.txt'
    Receive-File $Product.Repo $Product.Tag $Product.Asset $AssetPath
    Receive-File $Product.Repo $Product.Tag 'checksums.txt' $ChecksumPath
    $Pattern = '^([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($Product.Asset) + '$'
    $Match = Get-Content -LiteralPath $ChecksumPath | Select-String -Pattern $Pattern | Select-Object -First 1
    if (-not $Match) { throw "Checksum entry missing for $($Product.Asset)" }
    $Expected = $Match.Matches[0].Groups[1].Value.ToLowerInvariant()
    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $AssetPath).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) { throw "SHA-256 mismatch for $($Product.Asset)" }
    Copy-Item -LiteralPath $AssetPath -Destination (Join-Path $StagedBin $Product.Target) -Force
    Write-Host "Verified $($Product.Target)"
  }

  $Controller = Join-Path $Bin 'suitectl.ps1'
  $WasRunning = $false
  $ManagedBinaries = @{
    devcycle='devcycle.exe'
    infrascout='infrascout.exe'
    fleetscope='fleetctl.exe'
    'fleet-agent'='fleetctl.exe'
    releaseguard='releaseguard.exe'
  }
  foreach ($PidFile in Get-ChildItem (Join-Path $Prefix 'run') -Filter '*.pid' -File -ErrorAction SilentlyContinue) {
    if (-not $ManagedBinaries.ContainsKey($PidFile.BaseName)) { continue }
    $Value = (Get-Content -LiteralPath $PidFile.FullName -Raw).Trim()
    if ($Value -notmatch '^\d+$') { continue }
    $Process = Get-Process -Id ([int]$Value) -ErrorAction SilentlyContinue
    if (-not $Process) { continue }
    try {
      $ExpectedPath = [IO.Path]::GetFullPath((Join-Path $Bin $ManagedBinaries[$PidFile.BaseName]))
      $ActualPath = [IO.Path]::GetFullPath($Process.Path)
      if ($ActualPath.Equals($ExpectedPath, [StringComparison]::OrdinalIgnoreCase)) { $WasRunning = $true; break }
    } catch {}
  }
  if ($WasRunning -and (Test-Path -LiteralPath $Controller)) {
    Write-Host 'Stopping the running suite for an atomic upgrade...'
    & $Controller stop -SuiteHome $Prefix | Out-Host
  }

  foreach ($Product in $Products) {
    $Installed = Join-Path $Bin $Product.Target
    if (Test-Path -LiteralPath $Installed) { Copy-Item -LiteralPath $Installed -Destination (Join-Path $BackupBin $Product.Target) -Force }
  }
  if (Test-Path -LiteralPath $Controller) { Copy-Item -LiteralPath $Controller -Destination (Join-Path $BackupBin 'suitectl.ps1') -Force }

  try {
    foreach ($Product in $Products) {
      $Pending = Join-Path $Bin ($Product.Target + '.new')
      Copy-Item -LiteralPath (Join-Path $StagedBin $Product.Target) -Destination $Pending -Force
      Move-Item -LiteralPath $Pending -Destination (Join-Path $Bin $Product.Target) -Force
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'suitectl.ps1') -Destination $Controller -Force
  } catch {
    foreach ($Product in $Products) {
      $Backup = Join-Path $BackupBin $Product.Target
      $Installed = Join-Path $Bin $Product.Target
      if (Test-Path -LiteralPath $Backup) { Copy-Item -LiteralPath $Backup -Destination $Installed -Force }
      else { Remove-Item -LiteralPath $Installed -Force -ErrorAction SilentlyContinue }
      Remove-Item -LiteralPath ($Installed + '.new') -Force -ErrorAction SilentlyContinue
    }
    $ControllerBackup = Join-Path $BackupBin 'suitectl.ps1'
    if (Test-Path -LiteralPath $ControllerBackup) { Copy-Item -LiteralPath $ControllerBackup -Destination $Controller -Force }
    elseif (Test-Path -LiteralPath $Controller) { Remove-Item -LiteralPath $Controller -Force }
    if ($WasRunning -and (Test-Path -LiteralPath $Controller)) {
      try { & $Controller start -SuiteHome $Prefix | Out-Host } catch { Write-Warning "The previous suite could not be restarted: $($_.Exception.Message)" }
    }
    throw
  }

  Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'examples\release-report.demo.json') -Destination (Join-Path $Examples 'release-report.demo.json') -Force
  [IO.File]::WriteAllText((Join-Path $Config 'suite-version'), $Version, $Utf8NoBom)
  & (Join-Path $Bin 'suitectl.ps1') init -SuiteHome $Prefix | Out-Host
  Write-Host ''
  Write-Host "AI DevOps Open Suite $Version installed in $Prefix"
  if ($EnableAutostart) {
    & (Join-Path $Bin 'suitectl.ps1') enable -SuiteHome $Prefix | Out-Host
  } elseif ($Start -or $WasRunning) {
    & (Join-Path $Bin 'suitectl.ps1') start -SuiteHome $Prefix | Out-Host
  } else {
    Write-Host "Start:  powershell -ExecutionPolicy Bypass -File `"$(Join-Path $Bin 'suitectl.ps1')`" start"
    Write-Host "Status: powershell -ExecutionPolicy Bypass -File `"$(Join-Path $Bin 'suitectl.ps1')`" status"
  }
} finally {
  $ResolvedStage = [IO.Path]::GetFullPath($Stage)
  if ((Split-Path $ResolvedStage -Leaf).StartsWith('ai-devops-install-') -and $ResolvedStage.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $ResolvedStage -Recurse -Force -ErrorAction SilentlyContinue
  }
}
