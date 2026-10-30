param(
  [Parameter(Mandatory=$true)][string]$OfflineArchive,
  [Parameter(Mandatory=$true)][string]$PreviousArchive,
  [string]$Work = ''
)

$ErrorActionPreference = 'Stop'
$OfflineArchive = [IO.Path]::GetFullPath($OfflineArchive)
if (-not (Test-Path -LiteralPath $OfflineArchive -PathType Leaf)) { throw "Offline archive not found: $OfflineArchive" }
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if (-not $Work) { $Work = Join-Path ([IO.Path]::GetTempPath()) ('ai-devops-v100-upgrade-' + [guid]::NewGuid().ToString('N')) }
$Work = [IO.Path]::GetFullPath($Work)
if (-not $Work.StartsWith(($TempRoot + 'ai-devops-v100-upgrade-'), [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Acceptance work directory must be an ai-devops-v100-upgrade-* path under the system temporary directory.'
}

$Prefix = Join-Path $Work 'install'
$NewRoot = Join-Path $Work 'new'
$OldRoot = Join-Path $Work 'old'
$LegacySource = Join-Path $Work 'legacy-source'
$Controller = Join-Path $Prefix 'bin\suitectl.ps1'

function Free-Port {
  $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
  try { $Listener.Start(); return ([Net.IPEndPoint]$Listener.LocalEndpoint).Port } finally { $Listener.Stop() }
}

function File-Hash([string]$Path) {
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$Saved = @{
  AI_DEVOPS_DEVCYCLE_PORT = $env:AI_DEVOPS_DEVCYCLE_PORT
  AI_DEVOPS_INFRASCOUT_PORT = $env:AI_DEVOPS_INFRASCOUT_PORT
  AI_DEVOPS_FLEETSCOPE_PORT = $env:AI_DEVOPS_FLEETSCOPE_PORT
  AI_DEVOPS_RELEASEGUARD_PORT = $env:AI_DEVOPS_RELEASEGUARD_PORT
}

try {
  New-Item -ItemType Directory -Force -Path $NewRoot,$OldRoot,$LegacySource | Out-Null
  Expand-Archive -LiteralPath $OfflineArchive -DestinationPath $NewRoot
  $NewBundle = Join-Path $NewRoot 'ai-devops-open-suite'
  $NewInstaller = Join-Path $NewBundle 'scripts\install-suite.ps1'
  $NewManifest = Join-Path $NewBundle 'suite-manifest.json'
  if (-not (Test-Path -LiteralPath $NewInstaller -PathType Leaf) -or -not (Test-Path -LiteralPath $NewManifest -PathType Leaf)) { throw 'New offline bundle layout is invalid.' }
  $TargetVersion = [string](Get-Content -LiteralPath $NewManifest -Raw | ConvertFrom-Json).suiteVersion

  $OldArchive = [IO.Path]::GetFullPath($PreviousArchive)
  Expand-Archive -LiteralPath $OldArchive -DestinationPath $OldRoot
  $OldBundle = Join-Path $OldRoot 'ai-devops-open-suite'
  $OldInstaller = Join-Path $OldBundle 'scripts\install-suite.ps1'
  $OldManifest = Join-Path $OldBundle 'suite-manifest.json'
  if ([string](Get-Content $OldManifest -Raw | ConvertFrom-Json).suiteVersion -ne '1.0.0') { throw 'Expected actual v1.0.0 source bundle.' }

  $Ports = @(Free-Port; Free-Port; Free-Port; Free-Port)
  $env:AI_DEVOPS_DEVCYCLE_PORT = $Ports[0]
  $env:AI_DEVOPS_INFRASCOUT_PORT = $Ports[1]
  $env:AI_DEVOPS_FLEETSCOPE_PORT = $Ports[2]
  $env:AI_DEVOPS_RELEASEGUARD_PORT = $Ports[3]
  & $OldInstaller -Prefix $Prefix -SourceRoot $OldBundle -ManifestPath $OldManifest -Start | Out-Host
  & $Controller doctor -SuiteHome $Prefix | Out-Host
  & $Controller stop -SuiteHome $Prefix | Out-Host
  & (Join-Path $Prefix 'bin\devcycle.exe') requirement create --title 'v1.0 upgrade preservation' --desc 'Real v1 schema3 retained' --db (Join-Path $Prefix 'data\devcycle\devcycle.db') | Out-File (Join-Path $Work 'requirement-v1.json') -Encoding utf8
  if ($LASTEXITCODE -ne 0) { throw 'v1 requirement create failed.' }
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    $DataRoot = Join-Path $Prefix "data\$Product"
    New-Item -ItemType Directory -Force -Path $DataRoot | Out-Null
    [IO.File]::WriteAllText((Join-Path $DataRoot 'user-v100.marker'), 'preserve-v100', (New-Object Text.UTF8Encoding($false)))
  }
  $TokenBefore = File-Hash (Join-Path $Prefix 'config\fleet-token')
  $PortsBefore = File-Hash (Join-Path $Prefix 'config\ports.env')

  & $NewInstaller -Prefix $Prefix -SourceRoot $NewBundle -ManifestPath $NewManifest -Start | Out-Host
  & $Controller doctor -SuiteHome $Prefix | Out-Host
  $State = Get-Content -LiteralPath (Join-Path $Prefix 'config\install-state.json') -Raw | ConvertFrom-Json
  $BackupId = [string]$State.previousBackup
  if (-not $BackupId -or -not (Test-Path -LiteralPath (Join-Path $Prefix "backups\$BackupId\backup-files.json") -PathType Leaf)) { throw 'Upgrade did not create an integrity-checked backup.' }
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    if (-not (Test-Path -LiteralPath (Join-Path $Prefix "data\$Product\user-v100.marker") -PathType Leaf)) { throw "Upgrade lost $Product data." }
  }
  if ((File-Hash (Join-Path $Prefix 'config\fleet-token')) -ne $TokenBefore) { throw 'Upgrade changed the Fleet token.' }
  if ((File-Hash (Join-Path $Prefix 'config\ports.env')) -ne $PortsBefore) { throw 'Upgrade changed persisted ports.' }

  $TeamRepo = Join-Path $Work 'team-source'
  New-Item -ItemType Directory -Force $TeamRepo | Out-Null
  git -C $TeamRepo init -q
  git -C $TeamRepo -c user.name=Acceptance -c user.email=acceptance@example.invalid commit --allow-empty -qm baseline
  $MissionPayload = @{ repository=$TeamRepo; goal='Document local persistence'; checks=@('git status --porcelain'); models=@(@{ id='persistence'; provider='local'; adapter='codex'; capabilities=@('coding','exploration','testing','review'); contextLimit=100000; tier=2; available=$true; tools=$true }); policy=@{ trustedLocalCLI=$true; sourceExport=$false; allowedProviders=@('local') } }
  $Mission = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$($Ports[0])/api/team/missions" -ContentType application/json -Body ($MissionPayload | ConvertTo-Json -Depth 15)
  if (-not $Mission.id) { throw 'Team sidecar Mission was not created.' }
  & $Controller stop -SuiteHome $Prefix | Out-Host
  $Sidecar = Join-Path $Prefix 'data\devcycle\devcycle.db.team.db'
  if (-not (Test-Path $Sidecar)) { throw 'Team sidecar missing.' }
  $SidecarBefore = File-Hash $Sidecar
  python -c "import sqlite3,sys; assert sqlite3.connect(sys.argv[1]).execute('pragma user_version').fetchone()[0]==3; assert sqlite3.connect(sys.argv[2]).execute('pragma user_version').fetchone()[0]==1; print('original schema3 + Team schema1 verified')" (Join-Path $Prefix 'data\devcycle\devcycle.db') $Sidecar
  if ($LASTEXITCODE -ne 0) { throw 'Database schema verification failed.' }
  & $Controller start -SuiteHome $Prefix | Out-Host
  $Restarted = Invoke-RestMethod -Uri "http://127.0.0.1:$($Ports[0])/api/team/missions/$($Mission.id)"
  if ($Restarted.id -ne $Mission.id) { throw 'Team mission did not survive restart.' }

  & $Controller doctor -SuiteHome $Prefix | Out-Host
  & $Controller stop -SuiteHome $Prefix | Out-Host
  & (Join-Path $Prefix 'bin\devcycle.exe') requirement list --db (Join-Path $Prefix 'data\devcycle\devcycle.db') | Out-File (Join-Path $Work 'requirements-v2.json') -Encoding utf8
  if ($LASTEXITCODE -ne 0) { throw 'v2 cannot read v1 requirements.' }
  & $Controller rollback -SuiteHome $Prefix -BackupId $BackupId | Out-Host
  if ((Get-Content -LiteralPath (Join-Path $Prefix 'config\suite-version') -Raw).Trim() -ne '1.0.0') { throw 'Rollback did not restore suite v1.0.0.' }
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    if (-not (Test-Path -LiteralPath (Join-Path $Prefix "data\$Product\user-v100.marker") -PathType Leaf)) { throw "Rollback lost $Product data." }
  }
  if ((File-Hash (Join-Path $Prefix 'config\fleet-token')) -ne $TokenBefore -or (File-Hash (Join-Path $Prefix 'config\ports.env')) -ne $PortsBefore) { throw 'Rollback changed token or ports.' }

  if ((File-Hash $Sidecar) -ne $SidecarBefore) { throw 'Rollback altered Team sidecar.' }
  & $Controller start -SuiteHome $Prefix | Out-Host
  & $Controller doctor -SuiteHome $Prefix | Out-Host
  & $Controller stop -SuiteHome $Prefix | Out-Host
  & (Join-Path $Prefix 'bin\devcycle.exe') requirement list --db (Join-Path $Prefix 'data\devcycle\devcycle.db') | Out-File (Join-Path $Work 'requirements-rollback.json') -Encoding utf8
  if ($LASTEXITCODE -ne 0) { throw 'Rolled back v1 cannot read requirements.' }
  & $NewInstaller -Prefix $Prefix -SourceRoot $NewBundle -ManifestPath $NewManifest | Out-Host
  & $Controller purge -SuiteHome $Prefix -ConfirmPurge $Prefix | Out-Host
  if (Test-Path -LiteralPath $Prefix) { throw 'Acceptance cleanup failed.' }

  [ordered]@{
    platform = 'windows-amd64'
    source = 'public-v1.0.0-launcher'
    target = $TargetVersion
    dataMarkersPreserved = 4
    fleetTokenPreserved = $true
    portsPreserved = $true
    doctor = 'passed'
    rollbackVersion = '1.0.0'
    backupIntegrityManifest = $true
    cleanup = $true
    ports = $Ports
  } | ConvertTo-Json -Compress
} finally {
  foreach ($Name in $Saved.Keys) {
    if ($null -eq $Saved[$Name]) { Remove-Item "Env:$Name" -ErrorAction SilentlyContinue } else { Set-Item "Env:$Name" $Saved[$Name] }
  }
  if (Test-Path -LiteralPath $Controller -PathType Leaf) { try { & $Controller stop -SuiteHome $Prefix *> $null } catch {} }
  if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
}
