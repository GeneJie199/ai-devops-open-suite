param(
  [Parameter(Position=0)]
  [ValidateSet('init','start','stop','restart','status','open','logs','doctor','enable','disable','version','upgrade','rollback','uninstall','purge')]
  [string]$Command = 'status',
  [string]$SuiteHome = $(if ($env:AI_DEVOPS_HOME) { $env:AI_DEVOPS_HOME } elseif ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { Join-Path $env:LOCALAPPDATA 'ai-devops-suite' }),
  [string]$ManifestPath = '',
  [string]$SourceRoot = '',
  [string]$BackupId = '',
  [string]$ConfirmPurge = ''
)

$ErrorActionPreference = 'Stop'
$SuiteHome = [IO.Path]::GetFullPath($SuiteHome)
$Bin = Join-Path $SuiteHome 'bin'
$Data = Join-Path $SuiteHome 'data'
$Logs = Join-Path $SuiteHome 'logs'
$Run = Join-Path $SuiteHome 'run'
$Examples = Join-Path $SuiteHome 'examples'
$Config = Join-Path $SuiteHome 'config'
$Backups = Join-Path $SuiteHome 'backups'
$InstallStatePath = Join-Path $Config 'install-state.json'
$TokenPath = Join-Path $Config 'fleet-token'
$VersionPath = Join-Path $Config 'suite-version'
$PortConfigPath = Join-Path $Config 'ports.env'
$AutostartName = 'AI DevOps Open Suite.lnk'
$AutostartPath = if ($env:OS -eq 'Windows_NT') { Join-Path ([Environment]::GetFolderPath('Startup')) $AutostartName } else { '' }
$AutostartBootstrap = Join-Path $Config 'autostart.ps1'
$SuiteVersion = if (Test-Path -LiteralPath $VersionPath) { (Get-Content -LiteralPath $VersionPath -Raw).Trim() } else { '0.3.3' }
$IsWindowsHost = $env:OS -eq 'Windows_NT'
$SavedPorts = @{}
if (Test-Path -LiteralPath $PortConfigPath -PathType Leaf) {
  foreach ($Line in Get-Content -LiteralPath $PortConfigPath) {
    if ($Line -match '^(AI_DEVOPS_(?:INFRASCOUT|DEVCYCLE|FLEETSCOPE|RELEASEGUARD)_PORT)=([0-9]+)$') { $SavedPorts[$Matches[1]] = $Matches[2] }
  }
}
$Ports = @{
  infrascout = [int]$(if ($env:AI_DEVOPS_INFRASCOUT_PORT) { $env:AI_DEVOPS_INFRASCOUT_PORT } elseif ($SavedPorts.AI_DEVOPS_INFRASCOUT_PORT) { $SavedPorts.AI_DEVOPS_INFRASCOUT_PORT } else { 8765 })
  devcycle = [int]$(if ($env:AI_DEVOPS_DEVCYCLE_PORT) { $env:AI_DEVOPS_DEVCYCLE_PORT } elseif ($SavedPorts.AI_DEVOPS_DEVCYCLE_PORT) { $SavedPorts.AI_DEVOPS_DEVCYCLE_PORT } else { 8766 })
  fleetscope = [int]$(if ($env:AI_DEVOPS_FLEETSCOPE_PORT) { $env:AI_DEVOPS_FLEETSCOPE_PORT } elseif ($SavedPorts.AI_DEVOPS_FLEETSCOPE_PORT) { $SavedPorts.AI_DEVOPS_FLEETSCOPE_PORT } else { 8770 })
  releaseguard = [int]$(if ($env:AI_DEVOPS_RELEASEGUARD_PORT) { $env:AI_DEVOPS_RELEASEGUARD_PORT } elseif ($SavedPorts.AI_DEVOPS_RELEASEGUARD_PORT) { $SavedPorts.AI_DEVOPS_RELEASEGUARD_PORT } else { 8771 })
}
foreach ($Port in $Ports.Values) { if ($Port -lt 1 -or $Port -gt 65535) { throw "Invalid suite port: $Port" } }
$Urls = @{
  infrascout = "http://127.0.0.1:$($Ports.infrascout)/"
  devcycle = "http://127.0.0.1:$($Ports.devcycle)/"
  fleetscope = "http://127.0.0.1:$($Ports.fleetscope)/"
  releaseguard = "http://127.0.0.1:$($Ports.releaseguard)/"
}

function Binary([string]$Name) {
  $Suffix = if ($IsWindowsHost) { '.exe' } else { '' }
  Join-Path $Bin ($Name + $Suffix)
}

function Initialize-Suite {
  New-Item -ItemType Directory -Force -Path $Bin,$Data,$Logs,$Run,(Split-Path -Parent $TokenPath) | Out-Null
  foreach ($Name in 'devcycle','infrascout','fleetscope','releaseguard') {
    New-Item -ItemType Directory -Force -Path (Join-Path $Data $Name) | Out-Null
  }
  if (-not (Test-Path -LiteralPath $TokenPath)) {
    $Bytes = New-Object byte[] 32
    $Generator = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $Generator.GetBytes($Bytes) } finally { $Generator.Dispose() }
    [IO.File]::WriteAllText($TokenPath, [Convert]::ToBase64String($Bytes), (New-Object Text.UTF8Encoding($false)))
  }
  $PortConfig = @(
    "AI_DEVOPS_DEVCYCLE_PORT=$($Ports.devcycle)",
    "AI_DEVOPS_INFRASCOUT_PORT=$($Ports.infrascout)",
    "AI_DEVOPS_FLEETSCOPE_PORT=$($Ports.fleetscope)",
    "AI_DEVOPS_RELEASEGUARD_PORT=$($Ports.releaseguard)"
  )
  [IO.File]::WriteAllLines($PortConfigPath, $PortConfig, (New-Object Text.UTF8Encoding($false)))
  $Report = Join-Path $Data 'releaseguard\release-report.json'
  $Demo = Join-Path $Examples 'release-report.demo.json'
  if (-not (Test-Path -LiteralPath $Report) -and (Test-Path -LiteralPath $Demo)) {
    Copy-Item -LiteralPath $Demo -Destination $Report
  }
  Write-Host "Suite home: $SuiteHome"
}

function Quote-Argument([string]$Value) {
  if ($Value.Length -eq 0) { return '""' }
  if ($Value -notmatch '[\s"]') { return $Value }
  '"' + $Value.Replace('"','\"') + '"'
}

function Managed-Process([string]$Name) {
  $PidPath = Join-Path $Run ($Name + '.pid')
  if (-not (Test-Path -LiteralPath $PidPath)) { return $null }
  $Value = (Get-Content -LiteralPath $PidPath -Raw).Trim()
  if ($Value -notmatch '^\d+$') { return $null }
  $Process = Get-Process -Id ([int]$Value) -ErrorAction SilentlyContinue
  if (-not $Process) { return $null }
  $BinaryName = switch ($Name) {
    'devcycle' { 'devcycle' }
    'infrascout' { 'infrascout' }
    'fleetscope' { 'fleetctl' }
    'fleet-agent' { 'fleetctl' }
    'releaseguard' { 'releaseguard' }
    default { return $null }
  }
  try {
    $ExpectedPath = [IO.Path]::GetFullPath((Binary $BinaryName))
    $ActualPath = [IO.Path]::GetFullPath($Process.Path)
    if (-not $ActualPath.Equals($ExpectedPath, [StringComparison]::OrdinalIgnoreCase)) { return $null }
  } catch { return $null }
  $Process
}

function Start-Managed([string]$Name, [string]$Executable, [string[]]$Arguments) {
  $Existing = Managed-Process $Name
  if ($Existing) { return }
  if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { throw "Missing binary: $Executable. Run install-suite first." }
  $Out = Join-Path $Logs ($Name + '.log')
  $Err = Join-Path $Logs ($Name + '.error.log')
  $Line = ($Arguments | ForEach-Object { Quote-Argument $_ }) -join ' '
  $Process = Start-Process -FilePath $Executable -ArgumentList $Line -RedirectStandardOutput $Out -RedirectStandardError $Err -PassThru -WindowStyle Hidden
  [IO.File]::WriteAllText((Join-Path $Run ($Name + '.pid')), [string]$Process.Id, (New-Object Text.UTF8Encoding($false)))
  Start-Sleep -Milliseconds 250
  if ($Process.HasExited) { throw "$Name failed to start. See $Err" }
}

function Wait-Endpoint([string]$Name, [string]$Url) {
  for ($Attempt = 0; $Attempt -lt 80; $Attempt++) {
    try { Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 1 | Out-Null; return } catch { Start-Sleep -Milliseconds 100 }
  }
  throw "$Name did not become ready: $Url"
}

function Start-Suite {
  Initialize-Suite
  try {
    $Required = 'devcycle','infrascout','fleetctl','releaseguard','lifecycle-validate'
    foreach ($Name in $Required) { if (-not (Test-Path -LiteralPath (Binary $Name))) { throw "Missing binary: $(Binary $Name)" } }
    Start-Managed 'devcycle' (Binary 'devcycle') @('serve','--db',(Join-Path $Data 'devcycle\devcycle.db'),'--addr',"127.0.0.1:$($Ports.devcycle)")
    if ($IsWindowsHost) {
      Start-Managed 'infrascout' (Binary 'infrascout') @('serve','--demo','--addr',"127.0.0.1:$($Ports.infrascout)")
    } else {
      $InfraState = Join-Path $Data 'infrascout'
      if (-not (Test-Path -LiteralPath (Join-Path $InfraState 'baseline.json'))) { & (Binary 'infrascout') baseline --state-dir $InfraState | Out-Null }
      Start-Managed 'infrascout' (Binary 'infrascout') @('watch','--state-dir',$InfraState,'--interval','1m','--addr',"127.0.0.1:$($Ports.infrascout)")
    }
    $OldToken = $env:FLEET_TOKEN
    try {
      $env:FLEET_TOKEN = (Get-Content -LiteralPath $TokenPath -Raw).Trim()
      Start-Managed 'fleetscope' (Binary 'fleetctl') @('serve','--data',(Join-Path $Data 'fleetscope'),'--addr',"127.0.0.1:$($Ports.fleetscope)")
      Wait-Endpoint 'FleetScope' ($Urls.fleetscope + 'api/v1/health')
      $AgentArgs = @('agent','--center',$Urls.fleetscope.TrimEnd('/'),'--node',[Environment]::MachineName.ToLowerInvariant(),'--interval','15s','--report-interval','1m','--spool-dir',(Join-Path $Data 'fleetscope\agent-spool'),'--credential-file',(Join-Path $Data 'fleetscope\agent-identity.json'),'--label',"version=$SuiteVersion")
      if (-not $IsWindowsHost) { $AgentArgs += @('--inventory',(Join-Path $Data 'infrascout\inventory.json'),'--drift',(Join-Path $Data 'infrascout\drift.json')) }
      Start-Managed 'fleet-agent' (Binary 'fleetctl') $AgentArgs
    } finally {
      if ($null -eq $OldToken) { Remove-Item Env:FLEET_TOKEN -ErrorAction SilentlyContinue } else { $env:FLEET_TOKEN = $OldToken }
    }
    $ReleaseState = Join-Path $Data 'releaseguard\releaseguard-runs.db'
    if (-not (Test-Path -LiteralPath $ReleaseState)) { $ReleaseState = '' }
    Start-Managed 'releaseguard' (Binary 'releaseguard') @('serve','--report',(Join-Path $Data 'releaseguard\release-report.json'),'--state',$ReleaseState,'--addr',"127.0.0.1:$($Ports.releaseguard)")
    Wait-Endpoint 'DevCycle' ($Urls.devcycle + 'api/requirements')
    Wait-Endpoint 'InfraScout' ($Urls.infrascout + 'api/data')
    Wait-Endpoint 'ReleaseGuard' ($Urls.releaseguard + 'api/v1/health')
    Show-Status
  } catch {
    Stop-Suite
    throw
  }
}

function Stop-Suite {
  foreach ($Name in 'fleet-agent','releaseguard','fleetscope','infrascout','devcycle') {
    $Process = Managed-Process $Name
    $PidPath = Join-Path $Run ($Name + '.pid')
    if ($Process) { Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue; $Process.WaitForExit(5000) | Out-Null }
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
  }
  Write-Host 'AI DevOps Open Suite stopped.'
}

function Endpoint-State([string]$Url) {
  try { $Response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 1; if ($Response.StatusCode -eq 200) { return 'ready' } } catch {}
  'offline'
}

function Show-Status {
  @(
    [pscustomobject]@{ Module='DevCycle'; State=(Endpoint-State ($Urls.devcycle + 'api/requirements')); URL=$Urls.devcycle },
    [pscustomobject]@{ Module='InfraScout'; State=(Endpoint-State ($Urls.infrascout + 'api/data')); URL=$Urls.infrascout },
    [pscustomobject]@{ Module='FleetScope'; State=(Endpoint-State ($Urls.fleetscope + 'api/v1/health')); URL=$Urls.fleetscope },
    [pscustomobject]@{ Module='Fleet Agent'; State=$(if (Managed-Process 'fleet-agent') { 'running' } else { 'offline' }); URL='local collector' },
    [pscustomobject]@{ Module='ReleaseGuard'; State=(Endpoint-State ($Urls.releaseguard + 'api/v1/health')); URL=$Urls.releaseguard },
    [pscustomobject]@{ Module='Autostart'; State=$(if ($AutostartPath -and (Test-Path -LiteralPath $AutostartPath)) { 'enabled' } else { 'disabled' }); URL='current user login' }
  ) | Format-Table -AutoSize
}

function Test-PortAvailable([int]$Port) {
  $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
  try { $Listener.Start(); return $true } catch { return $false } finally { try { $Listener.Stop() } catch {} }
}

function Invoke-Doctor {
  $script:DoctorFailed = $false
  $Checks = @()
  $Failed = $false
  $Checks += [pscustomobject]@{ Check='Platform'; State='OK'; Detail="$([Environment]::OSVersion.Platform), PowerShell $($PSVersionTable.PSVersion)" }

  foreach ($Name in 'devcycle','infrascout','fleetctl','releaseguard','lifecycle-validate') {
    $Path = Binary $Name
    $Present = Test-Path -LiteralPath $Path -PathType Leaf
    if (-not $Present) { $Failed = $true }
    $Checks += [pscustomobject]@{ Check="Binary: $Name"; State=$(if ($Present) { 'OK' } else { 'FAIL' }); Detail=$Path }
  }

  $Writable = $false
  $Probe = Join-Path $SuiteHome ('.doctor-' + [guid]::NewGuid().ToString('N'))
  try {
    if (Test-Path -LiteralPath $SuiteHome -PathType Container) {
      [IO.File]::WriteAllText($Probe, 'ok', (New-Object Text.UTF8Encoding($false)))
      $Writable = $true
    }
  } catch {} finally { Remove-Item -LiteralPath $Probe -Force -ErrorAction SilentlyContinue }
  if (-not $Writable) { $Failed = $true }
  $Checks += [pscustomobject]@{ Check='Suite data'; State=$(if ($Writable) { 'OK' } else { 'FAIL' }); Detail="$SuiteHome writable" }

  $TokenReady = Test-Path -LiteralPath $TokenPath -PathType Leaf
  if (-not $TokenReady) { $Failed = $true }
  $Checks += [pscustomobject]@{ Check='Fleet token'; State=$(if ($TokenReady) { 'OK' } else { 'FAIL' }); Detail=$TokenPath }

  foreach ($Item in @(
    [pscustomobject]@{ Name='DevCycle'; Port=$Ports.devcycle; Url=$Urls.devcycle + 'api/requirements'; Process='devcycle' },
    [pscustomobject]@{ Name='InfraScout'; Port=$Ports.infrascout; Url=$Urls.infrascout + 'api/data'; Process='infrascout' },
    [pscustomobject]@{ Name='FleetScope'; Port=$Ports.fleetscope; Url=$Urls.fleetscope + 'api/v1/health'; Process='fleetscope' },
    [pscustomobject]@{ Name='ReleaseGuard'; Port=$Ports.releaseguard; Url=$Urls.releaseguard + 'api/v1/health'; Process='releaseguard' }
  )) {
    $Endpoint = Endpoint-State $Item.Url
    $Managed = $null -ne (Managed-Process -Name $Item.Process)
    $Available = ($Endpoint -eq 'ready' -and $Managed) -or ($Endpoint -ne 'ready' -and (Test-PortAvailable ([int]$Item.Port)))
    if (-not $Available) { $Failed = $true }
    $Detail = if ($Endpoint -eq 'ready' -and $Managed) { "port $($Item.Port), managed endpoint ready" } elseif ($Endpoint -eq 'ready') { "port $($Item.Port) responds but is not managed by this installation" } elseif ($Available) { "port $($Item.Port) available" } else { "port $($Item.Port) occupied by another process" }
    $Checks += [pscustomobject]@{ Check="Port: $($Item.Name)"; State=$(if ($Available) { 'OK' } else { 'FAIL' }); Detail=$Detail }
  }

  $Checks += [pscustomobject]@{ Check='Autostart'; State='INFO'; Detail=$(if ($AutostartPath -and (Test-Path -LiteralPath $AutostartPath)) { "enabled at $AutostartPath" } else { 'disabled; run suitectl enable to start after login' }) }
  $Checks | Format-Table -AutoSize | Out-Host
  if ($Failed) {
    $script:DoctorFailed = $true
    Write-Host 'Doctor found blocking issues.' -ForegroundColor Red
    return
  }
  Write-Host 'Doctor completed: the suite is ready to run.'
}

function Enable-Autostart {
  if (-not $IsWindowsHost) { throw 'This PowerShell controller enables autostart on Windows only. Use suitectl enable on Linux or macOS.' }
  $Controller = Join-Path $Bin 'suitectl.ps1'
  if (-not (Test-Path -LiteralPath $Controller -PathType Leaf)) { throw "Missing controller: $Controller. Run install-suite first." }
  Initialize-Suite
  $PowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  if (-not (Test-Path -LiteralPath $PowerShell)) { $PowerShell = (Get-Command pwsh -ErrorAction Stop).Source }
  $EscapedController = $Controller.Replace("'", "''")
  $EscapedSuiteHome = $SuiteHome.Replace("'", "''")
  $Bootstrap = @(
    "`$env:AI_DEVOPS_DEVCYCLE_PORT = '$($Ports.devcycle)'",
    "`$env:AI_DEVOPS_INFRASCOUT_PORT = '$($Ports.infrascout)'",
    "`$env:AI_DEVOPS_FLEETSCOPE_PORT = '$($Ports.fleetscope)'",
    "`$env:AI_DEVOPS_RELEASEGUARD_PORT = '$($Ports.releaseguard)'",
    "& '$EscapedController' start -SuiteHome '$EscapedSuiteHome'"
  )
  [IO.File]::WriteAllLines($AutostartBootstrap, $Bootstrap, [Text.Encoding]::Unicode)
  $Shell = New-Object -ComObject WScript.Shell
  $Shortcut = $Shell.CreateShortcut($AutostartPath)
  $Shortcut.TargetPath = $PowerShell
  $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$AutostartBootstrap`""
  $Shortcut.WorkingDirectory = $SuiteHome
  $Shortcut.WindowStyle = 7
  $Shortcut.Description = 'Start AI DevOps Open Suite for the current user'
  $Shortcut.Save()
  if (-not (Test-Path -LiteralPath $AutostartPath)) { throw "Could not create autostart shortcut: $AutostartPath" }
  Write-Host "Autostart enabled: $AutostartPath"
  Stop-Suite
  Start-Suite
}

function Disable-Autostart {
  if (-not $IsWindowsHost) { throw 'This PowerShell controller disables autostart on Windows only. Use suitectl disable on Linux or macOS.' }
  Remove-Item -LiteralPath $AutostartPath -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $AutostartBootstrap -Force -ErrorAction SilentlyContinue
  Write-Host 'Autostart disabled. Running modules were not stopped.'
}

function Open-Suite {
  Start-Process $Urls.devcycle | Out-Null
  Write-Host "Opened $($Urls.devcycle). Use the module switcher to move through the suite."
}

function Show-Logs {
  foreach ($File in Get-ChildItem -LiteralPath $Logs -File -ErrorAction SilentlyContinue | Sort-Object Name) {
    Write-Host "`n== $($File.Name) =="
    Get-Content -LiteralPath $File.FullName -Tail 40
  }
}

function Show-Version {
  if (Test-Path -LiteralPath $InstallStatePath -PathType Leaf) {
    $State = Get-Content -LiteralPath $InstallStatePath -Raw | ConvertFrom-Json
    [pscustomobject]@{ Suite=$State.suiteVersion; Platform=$State.platform; InstalledAt=$State.installedAt; Source=$State.source } | Format-List
    $State.components | Select-Object id,version,target | Format-Table -AutoSize
    return
  }
  Write-Host "AI DevOps Open Suite $SuiteVersion (legacy installation metadata)"
}

function Invoke-Upgrade {
  $Installer = Join-Path $Bin 'install-suite.ps1'
  if ($SourceRoot) {
    $BundledInstaller = Join-Path ([IO.Path]::GetFullPath($SourceRoot)) 'scripts\install-suite.ps1'
    if (Test-Path -LiteralPath $BundledInstaller -PathType Leaf) { $Installer = $BundledInstaller }
  }
  if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) { throw "Installed upgrade helper is missing: $Installer" }
  $EffectiveManifest = $ManifestPath
  if (-not $EffectiveManifest -and $SourceRoot) { $EffectiveManifest = Join-Path ([IO.Path]::GetFullPath($SourceRoot)) 'suite-manifest.json' }
  if (-not $EffectiveManifest) { $EffectiveManifest = Join-Path $Config 'suite-manifest.json' }
  if (-not (Test-Path -LiteralPath $EffectiveManifest -PathType Leaf)) { throw 'Provide -ManifestPath or a full offline -SourceRoot containing suite-manifest.json.' }
  & $Installer -Prefix $SuiteHome -ManifestPath $EffectiveManifest -SourceRoot $SourceRoot
  if (-not $?) { throw 'Upgrade failed.' }
}

function Copy-InstallSnapshot([string]$Destination, [string]$Reason) {
  $DestinationBin = Join-Path $Destination 'bin'
  $DestinationConfig = Join-Path $Destination 'config'
  New-Item -ItemType Directory -Force -Path $DestinationBin,$DestinationConfig | Out-Null
  foreach ($Name in 'lifecycle-validate.exe','devcycle.exe','infrascout.exe','fleetctl.exe','releaseguard.exe','suitectl.ps1','install-suite.ps1') {
    $Path = Join-Path $Bin $Name
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Copy-Item -LiteralPath $Path -Destination (Join-Path $DestinationBin $Name) -Force }
  }
  foreach ($Name in 'suite-version','suite-manifest.json','install-state.json') {
    $Path = Join-Path $Config $Name
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Copy-Item -LiteralPath $Path -Destination (Join-Path $DestinationConfig $Name) -Force }
  }
  $State = [ordered]@{ schemaVersion='ai-devops.install-backup/v1'; backupId=(Split-Path -Leaf $Destination); previousVersion=$SuiteVersion; targetVersion=$Reason; createdAt=(Get-Date).ToUniversalTime().ToString('o'); wasRunning=$false; hadPreviousInstallation=$true }
  [IO.File]::WriteAllText((Join-Path $Destination 'backup-state.json'), ($State | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-BackupManifest $Destination
}

function Write-BackupManifest([string]$Root) {
  $Records = @()
  foreach ($File in Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object Name -ne 'backup-files.json' | Sort-Object FullName) {
    $Relative = [IO.Path]::GetRelativePath($Root, $File.FullName).Replace('\','/')
    $Records += [ordered]@{ path=$Relative; size=$File.Length; sha256=(Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
  }
  $Value = [ordered]@{ schemaVersion='ai-devops.backup-files/v1'; files=$Records }
  [IO.File]::WriteAllText((Join-Path $Root 'backup-files.json'), ($Value | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
}

function Test-BackupManifest([string]$Root) {
  $Path = Join-Path $Root 'backup-files.json'
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Rollback backup has no integrity manifest.' }
  $Manifest = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if ($Manifest.schemaVersion -ne 'ai-devops.backup-files/v1') { throw 'Rollback backup integrity manifest has an unsupported version.' }
  foreach ($Record in $Manifest.files) {
    if ($Record.path -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._/-]*$' -or $Record.path.Contains('..')) { throw "Rollback backup contains an unsafe path: $($Record.path)" }
    $File = [IO.Path]::GetFullPath((Join-Path $Root ([string]$Record.path)))
    if (-not $File.StartsWith([IO.Path]::GetFullPath($Root) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Rollback backup path escaped its root.' }
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { throw "Rollback backup file is missing: $($Record.path)" }
    $Info = Get-Item -LiteralPath $File
    $Digest = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Info.Length -ne [long]$Record.size -or $Digest -ne [string]$Record.sha256) { throw "Rollback backup integrity check failed: $($Record.path)" }
  }
}

function Invoke-Rollback {
  if (-not (Test-Path -LiteralPath $Backups -PathType Container)) { throw 'No rollback backups are available.' }
  if ($BackupId -and $BackupId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'BackupId contains unsafe characters.' }
  $Selected = if ($BackupId) { Join-Path $Backups $BackupId } else { Get-ChildItem -LiteralPath $Backups -Directory | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName }
  if (-not $Selected -or -not (Test-Path -LiteralPath (Join-Path $Selected 'backup-state.json') -PathType Leaf)) { throw "Rollback backup not found: $BackupId" }
  Test-BackupManifest $Selected
  $Required = 'lifecycle-validate.exe','devcycle.exe','infrascout.exe','fleetctl.exe','releaseguard.exe','suitectl.ps1','install-suite.ps1'
  foreach ($Name in $Required) { if (-not (Test-Path -LiteralPath (Join-Path $Selected "bin\$Name") -PathType Leaf)) { throw "Rollback backup is incomplete: $Name" } }
  $WasRunning = $false
  foreach ($Name in 'devcycle','infrascout','fleetscope','fleet-agent','releaseguard') { if (Managed-Process $Name) { $WasRunning = $true; break } }
  if ($WasRunning) { Stop-Suite }
  $RecoveryId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-rollback-from-' + ($SuiteVersion -replace '[^a-zA-Z0-9._-]','_')
  Copy-InstallSnapshot (Join-Path $Backups $RecoveryId) 'rollback-recovery'
  foreach ($Name in $Required) { Copy-Item -LiteralPath (Join-Path $Selected "bin\$Name") -Destination (Join-Path $Bin $Name) -Force }
  foreach ($Name in 'suite-version','suite-manifest.json','install-state.json') {
    $Path = Join-Path $Selected "config\$Name"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Copy-Item -LiteralPath $Path -Destination (Join-Path $Config $Name) -Force }
  }
  $Restored = Get-Content -LiteralPath (Join-Path $Selected 'backup-state.json') -Raw | ConvertFrom-Json
  if (-not (Test-Path -LiteralPath $VersionPath -PathType Leaf)) { [IO.File]::WriteAllText($VersionPath, [string]$Restored.previousVersion, (New-Object Text.UTF8Encoding($false))) }
  Write-Host "Rolled back to backup $(Split-Path -Leaf $Selected). Current-version recovery backup: $RecoveryId"
  if ($WasRunning) { & (Join-Path $Bin 'suitectl.ps1') start -SuiteHome $SuiteHome }
}

function Invoke-Uninstall {
  Stop-Suite
  if ($IsWindowsHost) { Disable-Autostart }
  $State = [ordered]@{ schemaVersion='ai-devops.uninstall-state/v1'; uninstalledAt=(Get-Date).ToUniversalTime().ToString('o'); suiteVersion=$SuiteVersion; dataPreserved=$true; suiteHome=$SuiteHome }
  New-Item -ItemType Directory -Force -Path $Config | Out-Null
  [IO.File]::WriteAllText((Join-Path $Config 'uninstall-state.json'), ($State | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
  foreach ($Name in 'lifecycle-validate.exe','devcycle.exe','infrascout.exe','fleetctl.exe','releaseguard.exe','install-suite.ps1','suitectl.ps1') { Remove-Item -LiteralPath (Join-Path $Bin $Name) -Force -ErrorAction SilentlyContinue }
  Write-Host "Binaries removed. Data, configuration, logs, protocols, and backups remain in $SuiteHome"
  Write-Host "To delete them explicitly, reinstall the controller and run: suitectl purge -ConfirmPurge `"$SuiteHome`""
}

function Invoke-Purge {
  if (-not $ConfirmPurge -or -not ([IO.Path]::GetFullPath($ConfirmPurge).Equals($SuiteHome, [StringComparison]::OrdinalIgnoreCase))) { throw "Purge requires -ConfirmPurge with the exact suite path: $SuiteHome" }
  $Root = [IO.Path]::GetPathRoot($SuiteHome)
  if ($SuiteHome.TrimEnd('\').Equals($Root.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to purge a filesystem root.' }
  $Item = Get-Item -LiteralPath $SuiteHome -Force
  if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to purge a reparse point.' }
  Stop-Suite
  if ($IsWindowsHost) { Disable-Autostart }
  Remove-Item -LiteralPath $SuiteHome -Recurse -Force
  Write-Host "Purged suite binaries and data: $SuiteHome"
}

switch ($Command) {
  'init' { Initialize-Suite }
  'start' { Start-Suite }
  'stop' { Stop-Suite }
  'restart' { Stop-Suite; Start-Suite }
  'status' { Show-Status }
  'open' { Open-Suite }
  'logs' { Show-Logs }
  'doctor' { Invoke-Doctor; if ($script:DoctorFailed) { exit 1 } }
  'enable' { Enable-Autostart }
  'disable' { Disable-Autostart }
  'version' { Show-Version }
  'upgrade' { Invoke-Upgrade }
  'rollback' { Invoke-Rollback }
  'uninstall' { Invoke-Uninstall }
  'purge' { Invoke-Purge }
}
