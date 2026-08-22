param(
  [string]$SuiteSourceRoot = $(Split-Path -Parent $PSScriptRoot),
  [string]$Work = ''
)

$ErrorActionPreference = 'Stop'
$SuiteSourceRoot = [IO.Path]::GetFullPath($SuiteSourceRoot)
$Installer = Join-Path $SuiteSourceRoot 'scripts\install-suite.ps1'
$FallbackController = Join-Path $SuiteSourceRoot 'scripts\suitectl.ps1'
$Manifest = Join-Path $SuiteSourceRoot 'suite-manifest.json'
foreach ($Required in $Installer,$FallbackController,$Manifest) { if (-not (Test-Path -LiteralPath $Required -PathType Leaf)) { throw "Suite source is incomplete: $Required" } }
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if (-not $Work) { $Work = Join-Path ([IO.Path]::GetTempPath()) ('ai-devops-online-' + [guid]::NewGuid().ToString('N')) }
$Work = [IO.Path]::GetFullPath($Work)
if (-not $Work.StartsWith(($TempRoot + 'ai-devops-online-'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Acceptance work directory must be an ai-devops-online-* path under the system temporary directory.' }
$Controller = Join-Path $Work 'bin\suitectl.ps1'

function Free-Port {
  $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
  try { $Listener.Start(); return ([Net.IPEndPoint]$Listener.LocalEndpoint).Port } finally { $Listener.Stop() }
}

$Saved = @{
  AI_DEVOPS_DEVCYCLE_PORT = $env:AI_DEVOPS_DEVCYCLE_PORT
  AI_DEVOPS_INFRASCOUT_PORT = $env:AI_DEVOPS_INFRASCOUT_PORT
  AI_DEVOPS_FLEETSCOPE_PORT = $env:AI_DEVOPS_FLEETSCOPE_PORT
  AI_DEVOPS_RELEASEGUARD_PORT = $env:AI_DEVOPS_RELEASEGUARD_PORT
}
try {
  $Ports = @(Free-Port; Free-Port; Free-Port; Free-Port)
  $env:AI_DEVOPS_DEVCYCLE_PORT = $Ports[0]
  $env:AI_DEVOPS_INFRASCOUT_PORT = $Ports[1]
  $env:AI_DEVOPS_FLEETSCOPE_PORT = $Ports[2]
  $env:AI_DEVOPS_RELEASEGUARD_PORT = $Ports[3]
  & $Installer -Prefix $Work -ManifestPath $Manifest | Out-Host
  $State = Get-Content -LiteralPath (Join-Path $Work 'config\install-state.json') -Raw | ConvertFrom-Json
  if ($State.schemaVersion -ne 'ai-devops.install-state/v1' -or $State.source -ne 'online' -or @($State.components).Count -ne 5) { throw 'Online install state is invalid.' }
  & $Controller doctor -SuiteHome $Work | Out-Host
  & $Controller purge -SuiteHome $Work -ConfirmPurge $Work | Out-Host
  [ordered]@{ platform='windows-amd64'; source='online'; components=5; doctor='passed'; purge='passed'; ports=$Ports } | ConvertTo-Json -Compress
} finally {
  foreach ($Name in $Saved.Keys) {
    if ($null -eq $Saved[$Name]) { Remove-Item "Env:$Name" -ErrorAction SilentlyContinue } else { Set-Item "Env:$Name" $Saved[$Name] }
  }
  if (Test-Path -LiteralPath $Work) {
    try { & $FallbackController purge -SuiteHome $Work -ConfirmPurge $Work *> $null } catch {}
  }
}
