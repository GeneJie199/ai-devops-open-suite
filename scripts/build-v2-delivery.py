#!/usr/bin/env python3
"""Assemble the auditable C0 delivery from clean, CI-verified source and machine reports."""
from pathlib import Path
import datetime,hashlib,json,subprocess,zipfile

ROOT=Path(__file__).resolve().parents[1]
QA=ROOT/'.qa'
REPOS={'ai-devops-open-suite':ROOT,**{name:ROOT.parent/name for name in ['ai-dev-cycle-manager','infrastructure-discovery','fleet-observability','release-validation','lifecycle-spec']}}

def command(args,cwd):return subprocess.check_output(args,cwd=cwd,text=True,encoding='utf-8').strip()
def digest(path):
    value=hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda:source.read(1024*1024),b''):value.update(block)
    return value.hexdigest()

def main():
    stage=QA/'delivery-stage';stage.mkdir(parents=True,exist_ok=True)
    ci=json.loads((QA/'final-ci.json').read_text(encoding='utf-8'))
    lookup={item['repository']:item for item in ci}
    metadata={'name':'AI-DEV-V2-C0','generatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'edition':'Community development; not GA','license':'AGPL-3.0-only','repositories':[],'missions':[],'risks':'docs/v2-known-risks.md'}
    payload={}
    commits=[];changes={}
    for name,repo in REPOS.items():
        head=command(['git','rev-parse','HEAD'],repo)
        if command(['git','status','--porcelain'],repo):raise RuntimeError('uncommitted source: '+name)
        run=lookup.get(name)
        if not run or run['head']!=head or run['run']['conclusion']!='success':raise RuntimeError('exact-HEAD CI not successful: '+name)
        target=stage/(name+'-snapshot.zip')
        subprocess.run(['git','archive','--format=zip','--output='+str(target),'HEAD'],cwd=repo,check=True)
        payload['snapshot/'+target.name]=target
        entries=[]
        for line in command(['git','log','--reverse','--format=%H%x09%s','origin/main..HEAD'],repo).splitlines():
            sha,title=line.split('\t',1);entry={'repository':name,'sha':sha,'subject':title};commits.append(entry);entries.append(sha)
        changes[name]=command(['git','diff','--name-status','origin/main','HEAD'],repo).splitlines()
        metadata['repositories'].append({'repository':name,'head':head,'branch':command(['git','branch','--show-current'],repo),'baseline':command(['git','rev-parse','origin/main'],repo),'ci':run['run'],'pullRequest':run['url'],'commits':entries,'snapshotSHA256':digest(target)})
    bundle=QA/'v2-build/ai-devops-open-suite-full-offline-v2.0.0-dev-windows-amd64.zip'
    if not bundle.is_file():raise RuntimeError('missing development offline artifact')
    payload['artifacts/'+bundle.name]=bundle
    metadata['offlineArtifact']={'file':bundle.name,'sha256':digest(bundle),'nativeAcceptance':'Windows amd64; other platforms build-tested'}
    for name in ['suite-manifest.json','cross-build-report.json','verified-cross-builds.json']:
        payload['artifacts/'+name]=QA/'v2-build'/name
    for name in ['V2_MASTER_PLAN.md','V2_ARCHITECTURE.md','AI_TEAM_RUNTIME.md','MODEL_ROUTING.md','PROJECT_MEMORY.md','RISK_MODEL.md','V2_ACCEPTANCE.md','COMMERCIALIZATION.md','LICENSE_POLICY.md','COMMERCIAL_LICENSE.md','TRADEMARK_POLICY.md','CONTRIBUTOR_POLICY.md','THIRD_PARTY_NOTICES.md','LICENSING_HISTORY.md','LICENSE_METADATA.json','NOTICE','LICENSE','third-party-inventory.json','third-party.cdx.json']:
        payload['docs/'+name]=ROOT/name
    for path in (ROOT/'docs').glob('v2-*.md'):payload['docs/'+path.name]=path
    for path in QA.glob('*.log'):payload['reports/history/'+path.name]=path
    for path in QA.glob('ci-*.json'):payload['reports/ci/'+path.name]=path
    for path in QA.glob('final-*.json'):payload['reports/'+path.name]=path
    for path in QA.glob('ui-*.png'):payload['reports/ui/'+path.name]=path
    if (QA/'ui-report.json').exists():payload['reports/ui/ui-report.json']=QA/'ui-report.json'
    for directory in QA.glob('real-mission*'):
        if not directory.is_dir():continue
        for path in directory.glob('*.json'):payload['reports/missions/'+directory.name+'/'+path.name]=path
        for path in (directory/'devcycle-sessions').glob('*.log'):payload['reports/missions/'+directory.name+'/sessions/'+path.name]=path
        final=directory/'mission-final.json'
        if final.is_file():
            m=json.loads(final.read_text(encoding='utf-8-sig'));metadata['missions'].append({'id':m['id'],'state':m['state'],'directory':directory.name,'executions':len(m['executions']),'risk':m['risk']})
    # Include final component-local reports without SQLite, credentials, caches or worktrees.
    component=REPOS['ai-dev-cycle-manager']
    for path in (component/'.qa').glob('*.log'):payload['reports/devcycle/'+path.name]=path
    for name,value in [('commits.json',commits),('changed-files.json',changes),('delivery.json',metadata)]:
        path=stage/name;path.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');payload[name]=path
    report=stage/'START_HERE.md'
    report.write_text('# AI DevOps v2 C0 delivery\n\nDevelopment foundation; not GA. Start with docs/V2_ACCEPTANCE.md, then delivery.json for exact revisions and CI.\n\n- snapshot/: six clean source snapshots\n- artifacts/: Windows offline installer, embedded corresponding source/dependencies and cross-build digests\n- docs/: architecture/runtime/routing/memory/risk/licensing/commercial policies\n- reports/: real mission, review, security, install/upgrade/rollback and UI evidence; earlier failures remain labeled in history\n- commits.json and changed-files.json: complete auditable change lists\n- SHA256SUMS.json: every payload digest (manifest excludes itself)\n\nHistorical public v1 artifacts do not receive the development branch security fixes. See docs/v2-known-risks.md. No production approval or deployment was performed.\n',encoding='utf-8')
    payload['START_HERE.md']=report
    hashes=[{'path':name,'size':path.stat().st_size,'sha256':digest(path)} for name,path in sorted(payload.items())]
    manifest=stage/'SHA256SUMS.json';manifest.write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8');payload['SHA256SUMS.json']=manifest
    archive=ROOT/'AI-DEV-V2-C0-DELIVERY.zip'
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as output:
        for name,path in sorted(payload.items()):output.write(path,name)
    with zipfile.ZipFile(archive) as check:
        if check.testzip() is not None:raise RuntimeError('ZIP integrity failure')
        for item in hashes:
            if hashlib.sha256(check.read(item['path'])).hexdigest()!=item['sha256']:raise RuntimeError('payload digest mismatch: '+item['path'])
    sha=digest(archive);(ROOT/'AI-DEV-V2-C0-DELIVERY.zip.sha256').write_text(sha+'  '+archive.name+'\n',encoding='ascii')
    print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'sha256':sha,'payloads':len(payload),'commits':len(commits)},ensure_ascii=False))

if __name__=='__main__':main()
