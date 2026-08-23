param(
  [Parameter(Mandatory=$true)][string]$Archive,
  [string]$Work = ''
)

$ErrorActionPreference = 'Stop'
$Archive = [IO.Path]::GetFullPath($Archive)
if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) { throw "Offline archive not found: $Archive" }
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if (-not $Work) { $Work = Join-Path ([IO.Path]::GetTempPath()) ('ai-devops-v1-accept-' + [guid]::NewGuid().ToString('N')) }
$Work = [IO.Path]::GetFullPath($Work)
if (-not $Work.StartsWith($TempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $Work) -notlike 'ai-devops-v1-accept-*') {
  throw 'Acceptance work directory must be an ai-devops-v1-accept-* path under the system temporary directory.'
}
$Prefix = Join-Path $Work 'install'
$Extract = Join-Path $Work 'extract'
$Controller = Join-Path $Prefix 'bin\suitectl.ps1'

function Free-Port {
  $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
  try { $Listener.Start(); return ([Net.IPEndPoint]$Listener.LocalEndpoint).Port } finally { $Listener.Stop() }
}

function File-Hash([string]$Path) {
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Data-Fingerprint([string]$DataRoot) {
  $RootPrefix = [IO.Path]::GetFullPath($DataRoot).TrimEnd('\') + '\'
  $Rows = @(
    Get-ChildItem -LiteralPath $DataRoot -Recurse -File | ForEach-Object {
      $FullName = [IO.Path]::GetFullPath($_.FullName)
      $Relative = $FullName.Substring($RootPrefix.Length).Replace('\','/')
      "$Relative|$($_.Length)|$(File-Hash $FullName)"
    } | Sort-Object
  )
  $Text = $Rows -join "`n"
  $Bytes = [Text.Encoding]::UTF8.GetBytes($Text)
  $Hasher = [Security.Cryptography.SHA256]::Create()
  try { ([BitConverter]::ToString($Hasher.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() } finally { $Hasher.Dispose() }
}

try {
  New-Item -ItemType Directory -Force -Path $Extract | Out-Null
  Expand-Archive -LiteralPath $Archive -DestinationPath $Extract
  $Bundle = Join-Path $Extract 'ai-devops-open-suite'
  $Installer = Join-Path $Bundle 'scripts\install-suite.ps1'
  $Manifest = Join-Path $Bundle 'suite-manifest.json'
  if (-not (Test-Path -LiteralPath $Installer -PathType Leaf) -or -not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { throw 'Offline bundle layout is invalid.' }
  $TargetVersion = [string](Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).suiteVersion

  $Ports = @(Free-Port; Free-Port; Free-Port; Free-Port)
  $env:AI_DEVOPS_DEVCYCLE_PORT = $Ports[0]
  $env:AI_DEVOPS_INFRASCOUT_PORT = $Ports[1]
  $env:AI_DEVOPS_FLEETSCOPE_PORT = $Ports[2]
  $env:AI_DEVOPS_RELEASEGUARD_PORT = $Ports[3]
  & $Installer -Prefix $Prefix -SourceRoot $Bundle -ManifestPath $Manifest -Start | Out-Host
  & $Controller doctor -SuiteHome $Prefix | Out-Host
  for ($Attempt = 0; $Attempt -lt 50; $Attempt++) {
    if ((Test-Path -LiteralPath (Join-Path $Prefix 'data\fleetscope\agent-identity.json') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Prefix 'data\fleetscope\agents.json') -PathType Leaf)) { break }
    Start-Sleep -Milliseconds 200
  }
  & $Controller stop -SuiteHome $Prefix | Out-Host

  & (Join-Path $Prefix 'bin\devcycle.exe') requirement create --title 'Upgrade preservation acceptance' --desc 'State must survive install lifecycle operations.' --db (Join-Path $Prefix 'data\devcycle\devcycle.db') | Out-File -LiteralPath (Join-Path $Work 'requirement.json') -Encoding utf8
  & (Join-Path $Prefix 'bin\releaseguard.exe') confirm --report (Join-Path $Prefix 'data\releaseguard\release-report.json') --decision GO --by acceptance --note 'Upgrade preservation acceptance' --out (Join-Path $Prefix 'data\releaseguard\acceptance-approval.json') | Out-File -LiteralPath (Join-Path $Work 'approval.json') -Encoding utf8
  foreach ($Required in @(
    (Join-Path $Prefix 'data\devcycle\devcycle.db'),
    (Join-Path $Prefix 'data\fleetscope\agent-identity.json'),
    (Join-Path $Prefix 'data\fleetscope\agents.json'),
    (Join-Path $Prefix 'data\releaseguard\release-report.json'),
    (Join-Path $Prefix 'data\releaseguard\acceptance-approval.json')
  )) {
    if (-not (Test-Path -LiteralPath $Required -PathType Leaf) -or (Get-Item -LiteralPath $Required).Length -eq 0) { throw "Runtime did not create required preservation evidence: $Required" }
  }
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    [IO.File]::WriteAllText((Join-Path $Prefix "data\$Product\user-preserved.marker"), 'preserve-v1', (New-Object Text.UTF8Encoding($false)))
  }
  $TokenBefore = File-Hash (Join-Path $Prefix 'config\fleet-token')
  $PortsBefore = File-Hash (Join-Path $Prefix 'config\ports.env')

  $DevCycle = Join-Path $Prefix 'bin\devcycle.exe'
  [IO.File]::AppendAllText($DevCycle, 'interrupted-upgrade-marker', (New-Object Text.UTF8Encoding($false)))
  $InterruptedPreviousHash = File-Hash $DevCycle
  & $Controller start -SuiteHome $Prefix *> (Join-Path $Work 'restarted-before-interrupt.log')
  $PowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
  $env:AI_DEVOPS_ACCEPTANCE_ABORT_AFTER_PAYLOAD = '1'
  try {
    $ChildArguments = @(
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', ('"' + $Installer + '"'),
      '-Prefix', ('"' + $Prefix + '"'),
      '-SourceRoot', ('"' + $Bundle + '"'),
      '-ManifestPath', ('"' + $Manifest + '"')
    )
    $Child = Start-Process -FilePath $PowerShellExe -ArgumentList $ChildArguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $Work 'interrupted-upgrade.log') -RedirectStandardError (Join-Path $Work 'interrupted-upgrade.error.log')
    $InterruptExit = $Child.ExitCode
  } finally {
    Remove-Item Env:AI_DEVOPS_ACCEPTANCE_ABORT_AFTER_PAYLOAD -ErrorAction SilentlyContinue
  }
  if ($InterruptExit -eq 0) { throw 'Acceptance interrupt did not terminate the installer.' }
  if (-not (Test-Path -LiteralPath (Join-Path $Prefix 'config\install-transaction.txt')) -or -not (Test-Path -LiteralPath (Join-Path $Prefix 'config\install-transaction.json'))) { throw 'Interrupted upgrade did not leave a recovery journal.' }
  if ((File-Hash $DevCycle) -eq $InterruptedPreviousHash) { throw 'Acceptance interrupt did not occur after payload replacement.' }

  $EmptySource = Join-Path $Work 'recovery-empty-source'
  New-Item -ItemType Directory -Force -Path (Join-Path $EmptySource 'assets\windows-amd64') | Out-Null
  $RecoveryFailed = $false
  try { & $Installer -Prefix $Prefix -SourceRoot $EmptySource -ManifestPath $Manifest | Out-Host } catch { $RecoveryFailed = $true }
  if (-not $RecoveryFailed) { throw 'Recovery probe unexpectedly completed an install with missing assets.' }
  if ((File-Hash $DevCycle) -ne $InterruptedPreviousHash) { throw 'Interrupted upgrade did not restore the previous binary.' }
  $RecoveryPath = Join-Path $Prefix 'config\last-install-recovery.json'
  if (-not (Test-Path -LiteralPath $RecoveryPath -PathType Leaf)) { throw 'Interrupted upgrade recovery metadata is missing.' }
  $Recovery = Get-Content -LiteralPath $RecoveryPath -Raw | ConvertFrom-Json
  if ($Recovery.schemaVersion -ne 'ai-devops.install-recovery/v1' -or $Recovery.interruptedTargetVersion -ne $TargetVersion -or -not $Recovery.wasRunning) { throw 'Interrupted upgrade recovery metadata is invalid.' }
  if ((Test-Path -LiteralPath (Join-Path $Prefix 'config\install-transaction.txt')) -or (Test-Path -LiteralPath (Join-Path $Prefix 'config\install-transaction.json'))) { throw 'Interrupted upgrade journal was not cleared after recovery.' }
  $Status = & $Controller status -SuiteHome $Prefix | Out-String
  if ($Status -notmatch 'DevCycle\s+ready') { throw 'Interrupted upgrade recovery did not restart the previously running suite.' }
  & $Controller stop -SuiteHome $Prefix | Out-Host
  Copy-Item -LiteralPath (Join-Path $Bundle 'assets\windows-amd64\devcycle-windows-amd64.exe') -Destination $DevCycle -Force
  $DataBefore = Data-Fingerprint (Join-Path $Prefix 'data')

  $env:AI_DEVOPS_DEVCYCLE_PORT = Free-Port
  $env:AI_DEVOPS_INFRASCOUT_PORT = Free-Port
  $env:AI_DEVOPS_FLEETSCOPE_PORT = Free-Port
  $env:AI_DEVOPS_RELEASEGUARD_PORT = Free-Port
  & $Installer -Prefix $Prefix -SourceRoot $Bundle -ManifestPath $Manifest | Out-Host
  if ((Data-Fingerprint (Join-Path $Prefix 'data')) -ne $DataBefore) { throw 'Upgrade changed persisted product state.' }
  if ((File-Hash (Join-Path $Prefix 'config\fleet-token')) -ne $TokenBefore) { throw 'Upgrade changed the Fleet token.' }
  if ((File-Hash (Join-Path $Prefix 'config\ports.env')) -ne $PortsBefore) { throw 'Upgrade changed persisted ports because of ambient environment variables.' }
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    if (-not (Test-Path -LiteralPath (Join-Path $Prefix "data\$Product\user-preserved.marker"))) { throw "Upgrade lost $Product data." }
  }
  $InstallState = Get-Content -LiteralPath (Join-Path $Prefix 'config\install-state.json') -Raw | ConvertFrom-Json
  $BackupId = [string]$InstallState.previousBackup
  if (-not $BackupId) { throw 'Upgrade did not record a rollback backup.' }
  $BackupDevCycle = Join-Path $Prefix "backups\$BackupId\bin\devcycle.exe"
  [IO.File]::AppendAllText($BackupDevCycle, 'tamper', (New-Object Text.UTF8Encoding($false)))
  $TamperBlocked = $false
  try { & $Controller rollback -SuiteHome $Prefix -BackupId $BackupId | Out-Host } catch { $TamperBlocked = $true }
  if (-not $TamperBlocked) { throw 'Tampered rollback backup was unexpectedly accepted.' }
  Copy-Item -LiteralPath $DevCycle -Destination $BackupDevCycle -Force
  & $Controller rollback -SuiteHome $Prefix -BackupId $BackupId | Out-Host
  if ((Data-Fingerprint (Join-Path $Prefix 'data')) -ne $DataBefore) { throw 'Rollback changed persisted product state.' }
  if ((File-Hash (Join-Path $Prefix 'config\fleet-token')) -ne $TokenBefore -or (File-Hash (Join-Path $Prefix 'config\ports.env')) -ne $PortsBefore) { throw 'Rollback changed token or ports.' }

  & $Controller uninstall -SuiteHome $Prefix | Out-Host
  foreach ($Product in 'devcycle','infrascout','fleetscope','releaseguard') {
    if (-not (Test-Path -LiteralPath (Join-Path $Prefix "data\$Product\user-preserved.marker"))) { throw "Uninstall lost $Product data." }
  }
  if (@(Get-ChildItem -LiteralPath (Join-Path $Prefix 'bin') -File -ErrorAction SilentlyContinue).Count -ne 0) { throw 'Uninstall left managed binaries behind.' }
  & $Installer -Prefix $Prefix -SourceRoot $Bundle -ManifestPath $Manifest | Out-Host
  $Controller = Join-Path $Prefix 'bin\suitectl.ps1'
  & $Controller purge -SuiteHome $Prefix -ConfirmPurge $Prefix | Out-Host
  if (Test-Path -LiteralPath $Prefix) { throw 'Explicit purge did not remove the suite path.' }

  $MissingPrefix = Join-Path $Work 'missing-install'
  $MissingBlocked = $false
  try { & $Installer -Prefix $MissingPrefix -SourceRoot $EmptySource -ManifestPath $Manifest | Out-Host } catch { $MissingBlocked = $_.Exception.Message -like '*network fallback is disabled*' }
  if (-not $MissingBlocked) { throw 'Missing offline asset did not prove network fallback protection.' }

  [ordered]@{
    platform = 'windows-amd64'
    offlineInstall = 'passed'
    runtime = 'passed'
    doctor = 'passed'
    interruptedUpgradeRecovery = 'passed'
    persistedPortsProtected = $true
    productStatePreserved = @('requirement-db','fleet-identity','fleet-registration','release-report','digest-bound-approval')
    dataMarkersPreserved = 4
    tamperedBackup = 'blocked'
    rollback = 'passed'
    uninstallPreservedData = $true
    purge = 'passed'
    missingAssetNetworkFallback = 'blocked'
    ports = $Ports
  } | ConvertTo-Json -Compress
} finally {
  if (Test-Path -LiteralPath $Controller -PathType Leaf) { try { & $Controller stop -SuiteHome $Prefix *> $null } catch {} }
  if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
}
