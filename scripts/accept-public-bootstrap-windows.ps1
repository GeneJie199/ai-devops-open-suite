[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ReleaseUrl,
    [Parameter(Mandatory=$true)][string]$TargetVersion
)

$ErrorActionPreference = 'Stop'
if ($ReleaseUrl -notmatch '^https://github\.com/GeneJie199/ai-devops-open-suite/releases/download/v[0-9A-Za-z.-]+$') {
    throw 'ReleaseUrl must be an immutable AI DevOps Open Suite GitHub release URL.'
}
if ($TargetVersion -notmatch '^[0-9][0-9A-Za-z.-]+$') { throw 'TargetVersion is invalid.' }

$Repository = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$Work = Join-Path ([IO.Path]::GetTempPath()) ('ai-devops-public-bootstrap-accept-' + [guid]::NewGuid().ToString('N'))
$Prefix = Join-Path $Work 'install'
$Controller = Join-Path $Prefix 'bin\suitectl.ps1'

$Listeners = @()
try {
    foreach ($Index in 1..4) {
        $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
        $Listener.Start()
        $Listeners += $Listener
    }
    $Ports = @($Listeners | ForEach-Object { ([Net.IPEndPoint]$_.LocalEndpoint).Port })
} finally {
    $Listeners | ForEach-Object { $_.Stop() }
}

$Saved = @{
    AI_DEVOPS_RELEASE_URL = $env:AI_DEVOPS_RELEASE_URL
    AI_DEVOPS_DEVCYCLE_PORT = $env:AI_DEVOPS_DEVCYCLE_PORT
    AI_DEVOPS_INFRASCOUT_PORT = $env:AI_DEVOPS_INFRASCOUT_PORT
    AI_DEVOPS_FLEETSCOPE_PORT = $env:AI_DEVOPS_FLEETSCOPE_PORT
    AI_DEVOPS_RELEASEGUARD_PORT = $env:AI_DEVOPS_RELEASEGUARD_PORT
}

try {
    $env:AI_DEVOPS_RELEASE_URL = $ReleaseUrl
    $env:AI_DEVOPS_DEVCYCLE_PORT = $Ports[0]
    $env:AI_DEVOPS_INFRASCOUT_PORT = $Ports[1]
    $env:AI_DEVOPS_FLEETSCOPE_PORT = $Ports[2]
    $env:AI_DEVOPS_RELEASEGUARD_PORT = $Ports[3]
    & (Join-Path $Repository 'scripts\bootstrap.ps1') -Prefix $Prefix -NoStart
    & $Controller start -SuiteHome $Prefix | Out-Host
    & $Controller doctor -SuiteHome $Prefix | Out-Host

    $State = Get-Content -LiteralPath (Join-Path $Prefix 'config\install-state.json') -Raw | ConvertFrom-Json
    $Status = & $Controller status -SuiteHome $Prefix | Out-String
    if ($State.suiteVersion -ne $TargetVersion -or $State.source -ne 'online' -or @($State.components).Count -ne 5) { throw 'Public bootstrap installation state is invalid.' }
    if ($Status -notmatch 'DevCycle\s+ready' -or $Status -notmatch 'ReleaseGuard\s+ready') { throw 'Public bootstrap runtime is not ready.' }
    if (-not (Test-Path -LiteralPath (Join-Path $Prefix 'data\fleetscope\agent-identity.json') -PathType Leaf)) { throw 'Public bootstrap did not create the local Agent identity.' }

    & $Controller purge -SuiteHome $Prefix -ConfirmPurge $Prefix | Out-Host
    [ordered]@{
        schema = 'ai-devops.public-bootstrap-acceptance/v1'
        platform = 'windows-amd64'
        target = $State.suiteVersion
        source = $State.source
        components = @($State.components).Count
        runtime = 'passed'
        doctor = 'passed'
        agent = 'passed'
        cleanup = -not (Test-Path -LiteralPath $Prefix)
        ports = $Ports
    } | ConvertTo-Json -Compress
} finally {
    foreach ($Name in $Saved.Keys) {
        if ($null -eq $Saved[$Name]) { Remove-Item "Env:$Name" -ErrorAction SilentlyContinue } else { Set-Item "Env:$Name" $Saved[$Name] }
    }
    if (Test-Path -LiteralPath $Controller -PathType Leaf) {
        try { & $Controller purge -SuiteHome $Prefix -ConfirmPurge $Prefix *> $null } catch {}
    }
    $Resolved = [IO.Path]::GetFullPath($Work)
    if ((Test-Path -LiteralPath $Resolved) -and $Resolved.StartsWith($TempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $Resolved).StartsWith('ai-devops-public-bootstrap-accept-')) {
        [IO.Directory]::Delete($Resolved, $true)
    }
}
