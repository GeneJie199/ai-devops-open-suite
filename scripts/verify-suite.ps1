param(
  [switch]$SkipTests,
  [switch]$SkipE2E
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Modules = @('lifecycle-spec','ai-dev-cycle-manager','infrastructure-discovery','fleet-observability','release-validation')
$Processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$Work = Join-Path $TempRoot ("ai-devops-suite-e2e-" + [guid]::NewGuid().ToString('N'))
$OldFleetToken = $env:FLEET_TOKEN
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Invoke-External([string]$File, [string[]]$Arguments, [switch]$Quiet) {
	if ($Quiet) { & $File @Arguments | Out-Null } else { & $File @Arguments }
  if ($LASTEXITCODE -ne 0) { throw "$File exited with code $LASTEXITCODE" }
}

function Wait-Http([string]$Url) {
  for ($attempt = 0; $attempt -lt 80; $attempt++) {
    try { Invoke-RestMethod -Uri $Url -TimeoutSec 1 | Out-Null; return } catch { Start-Sleep -Milliseconds 100 }
  }
  throw "service did not become ready: $Url"
}

function Invoke-Json([string]$Method, [string]$Url, $Body = $null) {
  $params = @{ Method = $Method; Uri = $Url; TimeoutSec = 10 }
  if ($null -ne $Body) {
    $params.ContentType = 'application/json'
    $params.Body = $Body | ConvertTo-Json -Depth 30 -Compress
  }
  Invoke-RestMethod @params
}

function Write-Utf8([string]$Path, [string]$Value) {
  [IO.File]::WriteAllText($Path, $Value, $Utf8NoBom)
}

try {
  New-Item -ItemType Directory -Force $Work | Out-Null

  if (-not $SkipTests) {
    Write-Host '[1/7] Test every module'
    foreach ($Module in $Modules) {
      Push-Location (Join-Path $Root $Module)
      try {
        Invoke-External go @('test','./...')
        Invoke-External go @('vet','./...')
      } finally { Pop-Location }
    }
  } else {
    Write-Host '[1/7] Unit tests skipped by request'
  }

  Write-Host '[2/7] Build product binaries'
  $Dist = Join-Path $Root 'dist'
  New-Item -ItemType Directory -Force $Dist | Out-Null
  $Targets = @(
    @('lifecycle-spec','./cmd/lifecycle-validate','lifecycle-validate.exe'),
    @('ai-dev-cycle-manager','./cmd/devcycle','devcycle.exe'),
    @('infrastructure-discovery','./cmd/infrascout','infrascout.exe'),
    @('fleet-observability','./cmd/fleetctl','fleetctl.exe'),
    @('release-validation','./cmd/releaseguard','releaseguard.exe')
  )
  foreach ($Target in $Targets) {
    Push-Location (Join-Path $Root $Target[0])
    try { Invoke-External go @('build','-trimpath','-o',(Join-Path $Dist $Target[2]),$Target[1]) } finally { Pop-Location }
  }
  if ($SkipE2E) {
    Write-Host "Build completed; binaries are in $Dist"
    return
  }

  $DevPort = 19000 + (Get-Random -Minimum 0 -Maximum 300)
  $FleetPort = $DevPort + 400
  $DevBase = "http://127.0.0.1:$DevPort"
  $FleetBase = "http://127.0.0.1:$FleetPort"
  $Devcycle = Join-Path $Dist 'devcycle.exe'
  $InfraScout = Join-Path $Dist 'infrascout.exe'
  $FleetCtl = Join-Path $Dist 'fleetctl.exe'
  $ReleaseGuard = Join-Path $Dist 'releaseguard.exe'
  $LifecycleValidate = Join-Path $Dist 'lifecycle-validate.exe'

  Write-Host '[3/7] Create a source-pinned release candidate through DevCycle'
  $SourceRepo = Join-Path $Work 'source-repo'
  New-Item -ItemType Directory -Force $SourceRepo | Out-Null
	Write-Utf8 (Join-Path $SourceRepo 'README.md') "# Suite E2E source`n"
  Invoke-External git @('-C',$SourceRepo,'init','-q')
  Invoke-External git @('-C',$SourceRepo,'config','user.email','suite-e2e@example.invalid')
  Invoke-External git @('-C',$SourceRepo,'config','user.name','Suite E2E')
  Invoke-External git @('-C',$SourceRepo,'add','README.md')
  Invoke-External git @('-C',$SourceRepo,'commit','-q','-m','initial source')

  $DevProcess = Start-Process -FilePath $Devcycle -ArgumentList @('serve','--db',(Join-Path $Work 'devcycle.db'),'--addr',"127.0.0.1:$DevPort") -RedirectStandardOutput (Join-Path $Work 'devcycle.out.log') -RedirectStandardError (Join-Path $Work 'devcycle.err.log') -PassThru -WindowStyle Hidden
  $Processes.Add($DevProcess)
  Wait-Http "$DevBase/api/requirements"
  $Requirement = Invoke-Json POST "$DevBase/api/requirements" @{ title='Suite delivery'; description='Cross-module verification' }
  $Criterion = Invoke-Json POST "$DevBase/api/requirements/$($Requirement.id)/criteria" @{ description='All suite checks pass with evidence' }
  Invoke-Json PATCH "$DevBase/api/criteria/$($Criterion.id)" @{ satisfied=$true; evidenceTitle='suite E2E verification'; evidenceNote='automated cross-module acceptance' } | Out-Null
  $Task = Invoke-Json POST "$DevBase/api/tasks" @{ requirementId=$Requirement.id; title='Verify suite source and runtime' }
  $Worktree = Join-Path $Work 'source-worktree'
  Invoke-Json POST "$DevBase/api/tasks/$($Task.id)/worktree" @{ repositoryPath=$SourceRepo; branch='suite/e2e'; worktreePath=$Worktree } | Out-Null
  Invoke-Json PATCH "$DevBase/api/tasks/$($Task.id)" @{ status='done' } | Out-Null
  $Candidate = Invoke-Json GET "$DevBase/api/requirements/$($Requirement.id)/release-candidate"
  $CandidatePath = Join-Path $Work 'candidate.json'
	Write-Utf8 $CandidatePath ($Candidate | ConvertTo-Json -Depth 50)
  Invoke-External $LifecycleValidate @('release-candidate.json',$CandidatePath)
  if (-not $Candidate.readiness.ready -or $Candidate.sources.Count -ne 1 -or -not $Candidate.sources[0].clean) { throw 'DevCycle candidate is not source-pinned and ready' }

  Write-Host '[4/7] Capture InfraScout baseline and zero-drift evidence'
  $InfraState = Join-Path $Work 'infra'
  $Fixture = Join-Path $Root 'infrastructure-discovery\testdata\host-sample'
  Invoke-External $InfraScout @('baseline','--fixture',$Fixture,'--state-dir',$InfraState) -Quiet
  Invoke-External $InfraScout @('check','--fixture',$Fixture,'--state-dir',$InfraState,'--fail-on','never') -Quiet

  Write-Host '[5/7] Run the FleetScope native Agent and persist metric samples'
  $env:FLEET_TOKEN = 'suite-e2e-bootstrap-token'
  $FleetProcess = Start-Process -FilePath $FleetCtl -ArgumentList @('serve','--addr',"127.0.0.1:$FleetPort",'--data',(Join-Path $Work 'fleet')) -RedirectStandardOutput (Join-Path $Work 'fleet.out.log') -RedirectStandardError (Join-Path $Work 'fleet.err.log') -PassThru -WindowStyle Hidden
  $Processes.Add($FleetProcess)
  Wait-Http "$FleetBase/api/v1/health"
	$AgentProcess = Start-Process -FilePath $FleetCtl -ArgumentList @('agent','--center',$FleetBase,'--node','suite-e2e','--interval','1s','--report-interval','1s','--collector-jitter','0s','--inventory',(Join-Path $InfraState 'inventory.json'),'--drift',(Join-Path $InfraState 'drift.json'),'--label','version=0.3.0-rc.1','--spool-dir',(Join-Path $Work 'agent-spool'),'--credential-file',(Join-Path $Work 'agent-credential.json')) -RedirectStandardOutput (Join-Path $Work 'agent.out.log') -RedirectStandardError (Join-Path $Work 'agent.err.log') -PassThru -WindowStyle Hidden
  $Processes.Add($AgentProcess)
  Wait-Http "$FleetBase/api/v1/nodes/suite-e2e"
  Start-Sleep -Seconds 3
  $NodeReport = Join-Path $Work 'fleet\nodes\suite-e2e.json'
  Invoke-External $LifecycleValidate @('fleet-node-report.json',$NodeReport)

  Write-Host '[6/7] Gate candidate, drift, native metrics, fleet state, and observation'
  $Plan = @{
    release_id = 'suite-e2e'
    version = '0.3.0-rc.1'
    candidate_file = $CandidatePath
    recovery_checks = @(@{ name='previous binary retained'; type='file'; path=$ReleaseGuard })
    checks = @(@{ name='InfraScout inventory'; type='file'; path=(Join-Path $InfraState 'inventory.json') })
    drift_file = Join-Path $InfraState 'drift.json'
    fleet = @{ center_url=$FleetBase; nodes=@('suite-e2e'); version_label='version'; max_age_seconds=120 }
    metrics = @(@{ name='Agent memory regression'; metric='agent_memory_bytes'; node='suite-e2e'; aggregate='avg'; series_reduce='max'; baseline_seconds=60; direction='lower'; max_regression_percent=1000 })
    observation = @{ seconds=3; poll_seconds=1; max_critical_alerts=0 }
    rollback = @('Stop suite services','Restore the previous binaries','Re-run health checks')
  }
  $PlanPath = Join-Path $Work 'release-plan.json'
	Write-Utf8 $PlanPath ($Plan | ConvertTo-Json -Depth 30)
  $ReportPath = Join-Path $Work 'release-report.json'
  Invoke-External $ReleaseGuard @('check','--plan',$PlanPath,'--state',(Join-Path $Work 'releaseguard-runs.db'),'--out',$ReportPath) -Quiet
  Invoke-External $LifecycleValidate @('release-validation-report.json',$ReportPath)
  $Report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
  if ($Report.decision -ne 'GO') { throw "suite decision was $($Report.decision)" }
  if (-not $Report.manifest.candidate.ready -or -not $Report.manifest.fleet_after.nodes[0].match) { throw 'cross-module evidence did not match' }
  if ($Report.manifest.metrics.Count -ne 1 -or $Report.manifest.metrics[0].after.samples -lt 1) { throw 'native metric observation was not proven' }

  Write-Host '[7/7] All runtime contracts validated'
  Write-Host "AI DevOps Open Suite verification passed: GO, $($Report.results.Count) checks, $($Report.observation.samples.Count) observation samples"
} finally {
  foreach ($Process in $Processes) {
    if ($null -ne $Process -and -not $Process.HasExited) { Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue }
  }
  if ($null -eq $OldFleetToken) { Remove-Item Env:FLEET_TOKEN -ErrorAction SilentlyContinue } else { $env:FLEET_TOKEN = $OldFleetToken }
  $ResolvedWork = [IO.Path]::GetFullPath($Work)
  if ($ResolvedWork.StartsWith($TempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $ResolvedWork -Leaf).StartsWith('ai-devops-suite-e2e-')) {
    Remove-Item -LiteralPath $ResolvedWork -Recurse -Force -ErrorAction SilentlyContinue
  }
}
