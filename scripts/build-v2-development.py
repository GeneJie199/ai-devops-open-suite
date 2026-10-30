#!/usr/bin/env python3
"""Build all advertised targets from local v2 source and an offline development bundle.

Uses the existing bundle builder and installer; never modifies the stable manifest,
creates tags, publishes releases or substitutes unbuilt digest placeholders.
"""
from pathlib import Path
import datetime,hashlib,importlib.util,json,os,subprocess,tarfile

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'.qa/v2-build'
VERSION='2.0.0-dev'

def run(args,cwd,env=None):
    subprocess.run(args,cwd=cwd,env=env,check=True)

def main():
    WORK.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((ROOT/'suite-manifest.json').read_text(encoding='utf-8'))
    manifest.update(suiteVersion=VERSION,channel='development',generatedAt=datetime.datetime.now(datetime.timezone.utc).isoformat())
    records=[]
    for component in manifest['components']:
        repo=ROOT.parent/component['repository'];component['version']=VERSION;component['tag']='v'+VERSION
        command=component['id']
        version_flag='github.com/GeneJie199/infrastructure-discovery/pkg/infrascout.Version' if command=='infrascout' else 'main.version'
        for platform,asset in component['assets'].items():
            goos,arch=platform.split('-');name=command+'-'+platform+('.exe' if goos=='windows' else '')
            target=WORK/'cache'/component['repository']/component['tag']/name;target.parent.mkdir(parents=True,exist_ok=True)
            env={**os.environ,'GOTOOLCHAIN':'go1.27.3','GOOS':goos,'GOARCH':arch,'CGO_ENABLED':'0'}
            print('BUILD',component['repository'],platform,flush=True)
            run(['go','build','-trimpath','-ldflags',f'-X {version_flag}={VERSION}','-o',str(target),'./cmd/'+command],repo,env)
            asset.update(name=name,sha256=hashlib.sha256(target.read_bytes()).hexdigest())
            records.append({'component':command,'platform':platform,'sha256':asset['sha256'],'result':'build-passed'})
    protocol=manifest['protocol'];protocol.update(version=VERSION,tag='v'+VERSION,asset='lifecycle-spec-v'+VERSION+'.tar.gz')
    repo=ROOT.parent/'lifecycle-spec';archive=WORK/'cache'/protocol['repository']/protocol['tag']/protocol['asset'];archive.parent.mkdir(parents=True,exist_ok=True)
    paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=repo).decode('utf-8').split('\0')
    with tarfile.open(archive,'w:gz') as tar:
        for relative in sorted(set(paths)):
            if relative and (repo/relative).is_file():tar.add(repo/relative,arcname='lifecycle-spec/'+relative,recursive=False)
    protocol['sha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    for platform in manifest['platforms'].values():platform['verificationLevel']='build-tested'
    manifest['platforms']['windows-amd64']['verificationLevel']='build-tested'
    path=WORK/'suite-manifest.json';path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    (WORK/'cross-build-report.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
    run(['python',str(ROOT/'scripts/build-offline-bundle.py'),'--manifest',str(path),'--platform','windows-amd64','--output',str(WORK),'--cache',str(WORK/'cache')],ROOT)
    run(['python',str(ROOT/'scripts/verify-offline-bundle.py'),str(WORK/f'ai-devops-open-suite-full-offline-v{VERSION}-windows-amd64.zip')],ROOT)

if __name__=='__main__':main()
