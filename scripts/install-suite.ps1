param(
  [string]$Prefix = $(if ($env:AI_DEVOPS_HOME) { $env:AI_DEVOPS_HOME } else { Join-Path $env:LOCALAPPDATA 'ai-devops-suite' }),
  [string]$ManifestPath = '',
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
$PlatformKey = "windows-$Architecture"
$BundleRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not $ManifestPath) { $ManifestPath = Join-Path $BundleRoot 'suite-manifest.json' }
$ManifestPath = [IO.Path]::GetFullPath($ManifestPath)
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { throw "Suite manifest not found: $ManifestPath" }
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($Manifest.schemaVersion -ne 'ai-devops.suite-manifest/v1') { throw "Unsupported suite manifest: $($Manifest.schemaVersion)" }
if ($Manifest.suiteVersion -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Manifest suiteVersion is invalid.' }
$SuiteVersion = $Manifest.suiteVersion

$Products = @()
foreach ($Component in $Manifest.components) {
  $AssetProperty = $Component.assets.PSObject.Properties[$PlatformKey]
  if (-not $AssetProperty) { throw "Manifest component $($Component.id) does not support $PlatformKey" }
  $Asset = $AssetProperty.Value
  $Target = [string]$Component.target + '.exe'
  foreach ($Value in @($Component.id,$Component.repository,$Component.tag,$Component.version,$Target)) {
    if ($Value -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw "Manifest component contains an unsafe token: $Value" }
  }
  if ([IO.Path]::GetFileName([string]$Asset.name) -ne [string]$Asset.name) { throw "Manifest asset must be a basename: $($Asset.name)" }
  if ($Asset.sha256 -notmatch '^[0-9a-f]{64}$') { throw "Manifest asset has an invalid SHA-256: $($Asset.name)" }
  $Products += @{ ID=[string]$Component.id; Repo=[string]$Component.repository; Tag=[string]$Component.tag; Version=[string]$Component.version; Asset=[string]$Asset.name; SHA256=[string]$Asset.sha256; Target=$Target }
}
if ($Products.Count -lt 1) { throw 'Suite manifest does not contain any components.' }

$EffectiveSourceRoot = ''
if ($SourceRoot) {
  $EffectiveSourceRoot = [IO.Path]::GetFullPath($SourceRoot)
} elseif (Test-Path -LiteralPath (Join-Path $BundleRoot "assets\$PlatformKey") -PathType Container) {
  $EffectiveSourceRoot = $BundleRoot
}
$OfflineMode = [bool]$EffectiveSourceRoot

$Stage = Join-Path ([IO.Path]::GetTempPath()) ("ai-devops-install-" + [guid]::NewGuid().ToString('N'))
$Bin = Join-Path $Prefix 'bin'
$Examples = Join-Path $Prefix 'examples'
$Config = Join-Path $Prefix 'config'
$Protocols = Join-Path $Prefix 'protocols'
$Backups = Join-Path $Prefix 'backups'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$StagedBin = Join-Path $Stage 'bin'
$PreviousVersion = if (Test-Path -LiteralPath (Join-Path $Config 'suite-version')) { (Get-Content -LiteralPath (Join-Path $Config 'suite-version') -Raw).Trim() } else { 'unversioned' }
if ($PreviousVersion -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { $PreviousVersion = 'unversioned' }
$BackupID = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + $PID + '-' + ($PreviousVersion -replace '[^a-zA-Z0-9._-]','_')
$BackupRoot = Join-Path $Backups $BackupID
$BackupBin = Join-Path $BackupRoot 'bin'
$BackupConfig = Join-Path $BackupRoot 'config'
$Controller = Join-Path $Bin 'suitectl.ps1'
$Installer = Join-Path $Bin 'install-suite.ps1'
$TransactionIndex = Join-Path $Config 'install-transaction.txt'
$TransactionState = Join-Path $Config 'install-transaction.json'

function Receive-File([string]$Repo, [string]$Tag, [string]$Name, [string]$Destination) {
  if ($OfflineMode) {
    $Candidates = @(
      (Join-Path $EffectiveSourceRoot (Join-Path "assets\$PlatformKey" $Name)),
      (Join-Path $EffectiveSourceRoot (Join-Path 'protocols' $Name)),
      (Join-Path $EffectiveSourceRoot (Join-Path $Repo $Name)),
      (Join-Path $EffectiveSourceRoot $Name)
    )
    foreach ($Source in $Candidates) {
      if (Test-Path -LiteralPath $Source -PathType Leaf) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        return
      }
    }
    throw "Offline asset not found: $Name. Checked only $EffectiveSourceRoot; network fallback is disabled."
  }
  $Url = "https://github.com/GeneJie199/$Repo/releases/download/$Tag/$Name"
  $LastDownloadError = $null
  for ($Attempt = 1; $Attempt -le 3; $Attempt++) {
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination -TimeoutSec 90 -Headers @{ 'User-Agent'='ai-devops-suite-installer/1' }
      return
    } catch {
      $LastDownloadError = $_
      Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
      if ($Attempt -lt 3) { Start-Sleep -Seconds ([Math]::Pow(2, $Attempt - 1)) }
    }
  }
  throw "Download failed after 3 attempts: $Name. $($LastDownloadError.Exception.Message)"
}

function Restore-PreviousInstall {
  Write-Warning 'Install commit failed; restoring the previous installation.'
  foreach ($Product in $Products) {
    $Backup = Join-Path $BackupBin $Product.Target
    $Installed = Join-Path $Bin $Product.Target
    if (Test-Path -LiteralPath $Backup -PathType Leaf) { Copy-Item -LiteralPath $Backup -Destination $Installed -Force }
    else { Remove-Item -LiteralPath $Installed -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath ($Installed + '.new') -Force -ErrorAction SilentlyContinue
  }
  foreach ($Name in 'suitectl.ps1','install-suite.ps1') {
    $Backup = Join-Path $BackupBin $Name
    $Installed = Join-Path $Bin $Name
    if (Test-Path -LiteralPath $Backup -PathType Leaf) { Copy-Item -LiteralPath $Backup -Destination $Installed -Force }
    else { Remove-Item -LiteralPath $Installed -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath ($Installed + '.new') -Force -ErrorAction SilentlyContinue
  }
  foreach ($Name in 'suite-version','suite-manifest.json','install-state.json') {
    $Backup = Join-Path $BackupConfig $Name
    $Installed = Join-Path $Config $Name
    if (Test-Path -LiteralPath $Backup -PathType Leaf) { Copy-Item -LiteralPath $Backup -Destination $Installed -Force }
    elseif (-not $HadPreviousInstallation) { Remove-Item -LiteralPath $Installed -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath ($Installed + '.new') -Force -ErrorAction SilentlyContinue
  }
  if ($WasRunning -and (Test-Path -LiteralPath $Controller -PathType Leaf)) {
    try { & $Controller start -SuiteHome $Prefix | Out-Host } catch { Write-Warning "The previous suite could not be restarted: $($_.Exception.Message)" }
  }
}

function Write-BackupManifest([string]$Root) {
  $Records = @()
  $RootPrefix = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  foreach ($File in Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object Name -ne 'backup-files.json' | Sort-Object FullName) {
    $FullName = [IO.Path]::GetFullPath($File.FullName)
    if (-not $FullName.StartsWith($RootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Backup file escaped its root.' }
    $Relative = $FullName.Substring($RootPrefix.Length).Replace('\','/')
    $Records += [ordered]@{ path=$Relative; size=$File.Length; sha256=(Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
  }
  $Value = [ordered]@{ schemaVersion='ai-devops.backup-files/v1'; files=$Records }
  [IO.File]::WriteAllText((Join-Path $Root 'backup-files.json'), ($Value | ConvertTo-Json -Depth 6), $Utf8NoBom)
}

function Test-BackupManifest([string]$Root) {
  $Path = Join-Path $Root 'backup-files.json'
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Interrupted install backup has no integrity manifest.' }
  $Value = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if ($Value.schemaVersion -ne 'ai-devops.backup-files/v1') { throw 'Interrupted install backup integrity manifest has an unsupported version.' }
  $RootPrefix = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  foreach ($Record in $Value.files) {
    $Relative = [string]$Record.path
    if ($Relative -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._/-]*$' -or $Relative.Contains('..')) { throw "Interrupted install backup contains an unsafe path: $Relative" }
    $File = [IO.Path]::GetFullPath((Join-Path $Root $Relative.Replace('/', [IO.Path]::DirectorySeparatorChar)))
    if (-not $File.StartsWith($RootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Interrupted install backup path escaped its root.' }
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { throw "Interrupted install backup file is missing: $Relative" }
    $Info = Get-Item -LiteralPath $File -Force
    if ($Info.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Interrupted install backup file is a reparse point: $Relative" }
    $Digest = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Info.Length -ne [long]$Record.size -or $Digest -ne [string]$Record.sha256) { throw "Interrupted install backup integrity check failed: $Relative" }
  }
}

function Recover-InterruptedInstall([ValidateSet('startup','failure')][string]$Reason = 'startup') {
  if (-not (Test-Path -LiteralPath $TransactionIndex -PathType Leaf)) { return }
  $Lines = @(Get-Content -LiteralPath $TransactionIndex)
  if ($Lines.Count -lt 2) { throw 'Interrupted install transaction is incomplete.' }
  $Header = @($Lines[0].Split('|'))
  if ($Header.Count -ne 7 -or $Header[0] -ne 'transaction' -or $Header[1] -ne 'ai-devops.install-transaction/v1') { throw 'Interrupted install transaction header is malformed.' }
  $Backup = $Header[2]
  $RestoredVersion = $Header[3]
  $InterruptedTarget = $Header[4]
  $WasPreviouslyRunning = $Header[5]
  $HadPrevious = $Header[6]
  foreach ($Token in @($Backup,$RestoredVersion,$InterruptedTarget)) {
    if ($Token -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Interrupted install transaction contains an unsafe version or backup ID.' }
  }
  if ($WasPreviouslyRunning -notin @('true','false') -or $HadPrevious -notin @('true','false')) { throw 'Interrupted install transaction contains an invalid state.' }
  $Root = Join-Path $Backups $Backup
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Interrupted install backup is unavailable: $Backup" }
  $RootInfo = Get-Item -LiteralPath $Root -Force
  if ($RootInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Interrupted install backup must not be a reparse point.' }
  Test-BackupManifest $Root
  if ($Reason -eq 'failure') { Write-Warning 'Install commit failed; restoring the previous installation.' }
  else { Write-Warning 'Recovering the previous installation after an interrupted upgrade...' }
  foreach ($Line in $Lines[1..($Lines.Count - 1)]) {
    $Fields = @($Line.Split('|'))
    if ($Fields.Count -ne 2 -or $Fields[0] -ne 'managed') { throw 'Interrupted install transaction contains a malformed managed path.' }
    $Relative = $Fields[1]
    if ($Relative -notmatch '^(bin|config|protocols|examples|data)/[a-zA-Z0-9][a-zA-Z0-9._/-]*$' -or $Relative.Contains('..')) { throw 'Interrupted install transaction contains an unsafe managed path.' }
    $NativeRelative = $Relative.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $Source = Join-Path $Root $NativeRelative
    $Destination = Join-Path $Prefix $NativeRelative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    if (Test-Path -LiteralPath $Source -PathType Leaf) { Copy-Item -LiteralPath $Source -Destination $Destination -Force }
    else { Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath ($Destination + '.new') -Force -ErrorAction SilentlyContinue
  }
  $Recovery = [ordered]@{
    schemaVersion = 'ai-devops.install-recovery/v1'
    backupId = $Backup
    restoredVersion = $RestoredVersion
    interruptedTargetVersion = $InterruptedTarget
    recoveredAt = (Get-Date).ToUniversalTime().ToString('o')
    wasRunning = $WasPreviouslyRunning -eq 'true'
  }
  [IO.File]::WriteAllText((Join-Path $Config 'last-install-recovery.json'), ($Recovery | ConvertTo-Json -Depth 4), $Utf8NoBom)
  if ($WasPreviouslyRunning -eq 'true' -and $HadPrevious -eq 'true' -and (Test-Path -LiteralPath $Controller -PathType Leaf)) {
    & $Controller start -SuiteHome $Prefix | Out-Host
  }
  Remove-Item -LiteralPath $TransactionIndex,$TransactionState,($TransactionIndex + '.new'),($TransactionState + '.new') -Force -ErrorAction SilentlyContinue
}

function Write-TransactionState([string]$Phase) {
  $Value = [ordered]@{
    schemaVersion = 'ai-devops.install-transaction/v1'
    backupId = $BackupID
    previousVersion = $PreviousVersion
    targetVersion = $SuiteVersion
    phase = $Phase
    wasRunning = $WasRunning
    hadPreviousInstallation = $HadPreviousInstallation
    updatedAt = (Get-Date).ToUniversalTime().ToString('o')
  }
  [IO.File]::WriteAllText(($TransactionState + '.new'), ($Value | ConvertTo-Json -Depth 4), $Utf8NoBom)
  Move-Item -LiteralPath ($TransactionState + '.new') -Destination $TransactionState -Force
}

$InstallMutationStarted = $false
try {
  New-Item -ItemType Directory -Force -Path $Stage,$StagedBin,$Bin,$Examples,$Config,$Protocols,$Backups | Out-Null
  Recover-InterruptedInstall startup
  $PreviousVersion = if (Test-Path -LiteralPath (Join-Path $Config 'suite-version')) { (Get-Content -LiteralPath (Join-Path $Config 'suite-version') -Raw).Trim() } else { 'unversioned' }
  if ($PreviousVersion -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { $PreviousVersion = 'unversioned' }
  $BackupID = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + $PID + '-' + ($PreviousVersion -replace '[^a-zA-Z0-9._-]','_')
  $BackupRoot = Join-Path $Backups $BackupID
  $BackupBin = Join-Path $BackupRoot 'bin'
  $BackupConfig = Join-Path $BackupRoot 'config'
  foreach ($Product in $Products) {
    $RepoStage = Join-Path $Stage $Product.Repo
    New-Item -ItemType Directory -Force -Path $RepoStage | Out-Null
    $AssetPath = Join-Path $RepoStage $Product.Asset
    Receive-File $Product.Repo $Product.Tag $Product.Asset $AssetPath
    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $AssetPath).Hash.ToLowerInvariant()
    if ($Actual -ne $Product.SHA256) { throw "SHA-256 mismatch for $($Product.Asset)" }
    Copy-Item -LiteralPath $AssetPath -Destination (Join-Path $StagedBin $Product.Target) -Force
    Write-Host "Verified $($Product.Target)"
  }

  $Protocol = $Manifest.protocol
  if ([IO.Path]::GetFileName([string]$Protocol.asset) -ne [string]$Protocol.asset -or $Protocol.asset -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$' -or $Protocol.sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Manifest protocol asset is invalid.' }
  $ProtocolStage = Join-Path $Stage $Protocol.asset
  Receive-File $Protocol.repository $Protocol.tag $Protocol.asset $ProtocolStage
  $ProtocolActual = (Get-FileHash -Algorithm SHA256 -LiteralPath $ProtocolStage).Hash.ToLowerInvariant()
  if ($ProtocolActual -ne $Protocol.sha256) { throw "SHA-256 mismatch for $($Protocol.asset)" }
  Write-Host "Verified $($Protocol.asset)"

  $HadPreviousInstallation = Test-Path -LiteralPath $Controller -PathType Leaf
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
  $ManagedPaths = @($Products | ForEach-Object { 'bin/' + $_.Target })
  New-Item -ItemType Directory -Force -Path $BackupBin,$BackupConfig | Out-Null
  $ManagedPaths += @(
    'bin/suitectl.ps1',
    'bin/install-suite.ps1',
    'examples/release-report.demo.json',
    ('protocols/' + [string]$Protocol.asset),
    'config/suite-version',
    'config/suite-manifest.json',
    'config/install-state.json',
    'config/fleet-token',
    'config/ports.env',
    'data/releaseguard/release-report.json'
  )
  foreach ($Relative in $ManagedPaths) {
    $NativeRelative = $Relative.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $Source = Join-Path $Prefix $NativeRelative
    if (Test-Path -LiteralPath $Source -PathType Leaf) {
      $Destination = Join-Path $BackupRoot $NativeRelative
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
      Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
  }
  if ($HadPreviousInstallation -and -not (Test-Path -LiteralPath (Join-Path $BackupBin 'install-suite.ps1') -PathType Leaf)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install-suite.ps1') -Destination (Join-Path $BackupBin 'install-suite.ps1') -Force
  }
  $BackupState = [ordered]@{
    schemaVersion = 'ai-devops.install-backup/v1'
    backupId = $BackupID
    previousVersion = $PreviousVersion
    targetVersion = $SuiteVersion
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
    wasRunning = $WasRunning
    hadPreviousInstallation = $HadPreviousInstallation
  }
  [IO.File]::WriteAllText((Join-Path $BackupRoot 'backup-state.json'), ($BackupState | ConvertTo-Json -Depth 5), $Utf8NoBom)
  Write-BackupManifest $BackupRoot
  $TransactionLines = @("transaction|ai-devops.install-transaction/v1|$BackupID|$PreviousVersion|$SuiteVersion|$($WasRunning.ToString().ToLowerInvariant())|$($HadPreviousInstallation.ToString().ToLowerInvariant())")
  $TransactionLines += @($ManagedPaths | ForEach-Object { 'managed|' + $_ })
  [IO.File]::WriteAllLines(($TransactionIndex + '.new'), $TransactionLines, $Utf8NoBom)
  Move-Item -LiteralPath ($TransactionIndex + '.new') -Destination $TransactionIndex -Force
  Write-TransactionState prepared

  if ($WasRunning -and (Test-Path -LiteralPath $Controller)) {
    Write-Host 'Stopping the running suite for an atomic upgrade...'
    & $Controller stop -SuiteHome $Prefix | Out-Host
  }
  Write-TransactionState stopped

  $InstallMutationStarted = $true
  try {
    foreach ($Product in $Products) {
      $Pending = Join-Path $Bin ($Product.Target + '.new')
      Copy-Item -LiteralPath (Join-Path $StagedBin $Product.Target) -Destination $Pending -Force
      Move-Item -LiteralPath $Pending -Destination (Join-Path $Bin $Product.Target) -Force
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'suitectl.ps1') -Destination $Controller -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install-suite.ps1') -Destination $Installer -Force
  } catch { throw }
  Write-TransactionState payload-installed
  if ($env:AI_DEVOPS_ACCEPTANCE_ABORT_AFTER_PAYLOAD -eq '1') {
    $TempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $Prefix.StartsWith(($TempPrefix + 'ai-devops-'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Acceptance abort is restricted to an ai-devops-* temporary prefix.' }
    Stop-Process -Id $PID -Force
  }
  if ($env:AI_DEVOPS_ACCEPTANCE_FAIL_AFTER_PAYLOAD -eq '1') {
    $TempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $Prefix.StartsWith(($TempPrefix + 'ai-devops-'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Acceptance failure is restricted to an ai-devops-* temporary prefix.' }
    throw 'Acceptance failure after payload replacement.'
  }

  Copy-Item -LiteralPath (Join-Path $BundleRoot 'examples\release-report.demo.json') -Destination (Join-Path $Examples 'release-report.demo.json') -Force
  Copy-Item -LiteralPath $ProtocolStage -Destination (Join-Path $Protocols $Protocol.asset) -Force
  Copy-Item -LiteralPath $ManifestPath -Destination (Join-Path $Config 'suite-manifest.json.new') -Force
  Move-Item -LiteralPath (Join-Path $Config 'suite-manifest.json.new') -Destination (Join-Path $Config 'suite-manifest.json') -Force
  [IO.File]::WriteAllText((Join-Path $Config 'suite-version'), $SuiteVersion, $Utf8NoBom)
  $InstalledComponents = @($Products | ForEach-Object { [ordered]@{ id=$_.ID; repository=$_.Repo; version=$_.Version; tag=$_.Tag; target=$_.Target; asset=$_.Asset; sha256=$_.SHA256 } })
  $InstallState = [ordered]@{
    schemaVersion = 'ai-devops.install-state/v1'
    suiteVersion = $SuiteVersion
    platform = $PlatformKey
    installedAt = (Get-Date).ToUniversalTime().ToString('o')
    source = $(if ($OfflineMode) { 'offline' } else { 'online' })
    components = $InstalledComponents
    protocol = [ordered]@{ repository=[string]$Protocol.repository; version=[string]$Protocol.version; tag=[string]$Protocol.tag; asset=[string]$Protocol.asset; sha256=[string]$Protocol.sha256 }
    previousBackup = $(if ($HadPreviousInstallation) { $BackupID } else { $null })
    dataPreserved = $true
  }
  [IO.File]::WriteAllText((Join-Path $Config 'install-state.json.new'), ($InstallState | ConvertTo-Json -Depth 8), $Utf8NoBom)
  Move-Item -LiteralPath (Join-Path $Config 'install-state.json.new') -Destination (Join-Path $Config 'install-state.json') -Force
  & (Join-Path $Bin 'suitectl.ps1') init -SuiteHome $Prefix | Out-Host
  Write-TransactionState initialized
  Remove-Item -LiteralPath $TransactionIndex,$TransactionState -Force -ErrorAction SilentlyContinue
  if (-not $HadPreviousInstallation) { Remove-Item -LiteralPath $BackupRoot -Recurse -Force -ErrorAction SilentlyContinue }
  $InstallMutationStarted = $false
  Write-Host ''
  Write-Host "AI DevOps Open Suite $SuiteVersion installed in $Prefix ($($Products.Count) verified components, $($InstallState.source))"
  if ($HadPreviousInstallation) { Write-Host "Rollback backup: $BackupID" }
  if ($EnableAutostart) {
    & (Join-Path $Bin 'suitectl.ps1') enable -SuiteHome $Prefix | Out-Host
  } elseif ($Start -or $WasRunning) {
    & (Join-Path $Bin 'suitectl.ps1') start -SuiteHome $Prefix | Out-Host
  } else {
    Write-Host "Start:  powershell -ExecutionPolicy Bypass -File `"$(Join-Path $Bin 'suitectl.ps1')`" start"
    Write-Host "Status: powershell -ExecutionPolicy Bypass -File `"$(Join-Path $Bin 'suitectl.ps1')`" status"
  }
} catch {
  if (Test-Path -LiteralPath $TransactionIndex -PathType Leaf) { Recover-InterruptedInstall failure }
  elseif ($InstallMutationStarted) { Restore-PreviousInstall }
  throw
} finally {
  $ResolvedStage = [IO.Path]::GetFullPath($Stage)
  if ((Split-Path $ResolvedStage -Leaf).StartsWith('ai-devops-install-') -and $ResolvedStage.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $ResolvedStage -Recurse -Force -ErrorAction SilentlyContinue
  }
}
