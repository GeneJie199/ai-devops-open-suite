#!/usr/bin/env python3
"""Build all advertised targets from local v2 source and an offline development bundle.

Uses the existing bundle builder and installer; never modifies the stable manifest,
creates tags, publishes releases or substitutes unbuilt digest placeholders.
"""
from pathlib import Path
import argparse,datetime,hashlib,importlib.util,io,json,os,re,subprocess,tarfile
from suite_manifest import PLATFORMS

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'.qa/v2-build'
VERSION='2.0.0-dev'

def run(args,cwd,env=None):
    subprocess.run(args,cwd=cwd,env=env,check=True)

def clean_revision(repo):
    """Never label working-tree builds as the committed corresponding source."""
    status=subprocess.check_output(['git','status','--porcelain','--untracked-files=all'],cwd=repo,text=True)
    if status.strip():
        raise RuntimeError(f'Commit or remove source changes before building: {repo}')
    return subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()

def verify_revisions(revisions):
    for repo,revision in revisions.items():
        if clean_revision(repo)!=revision:
            raise RuntimeError(f'Source revision changed during build: {repo}')

def parse_args(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version',default=VERSION)
    parser.add_argument('--platform',choices=PLATFORMS,default='windows-amd64')
    args=parser.parse_args(argv)
    if not re.fullmatch(r'2\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?',args.version):
        parser.error('--version must be a v2 version without a leading v')
    return args

def main():
    args=parse_args()
    version=args.version
    manifest=json.loads((ROOT/'suite-manifest.json').read_text(encoding='utf-8'))
    repos=[ROOT,ROOT.parent/manifest['protocol']['repository']]+[ROOT.parent/item['repository'] for item in manifest['components']]
    revisions={repo:clean_revision(repo) for repo in repos}
    WORK.mkdir(parents=True,exist_ok=True)
    manifest.update(suiteVersion=version,channel='development',generatedAt=datetime.datetime.now(datetime.timezone.utc).isoformat())
    records=[]
    for component in manifest['components']:
        repo=ROOT.parent/component['repository'];component['version']=version;component['tag']='v'+version
        command=component['id']
        version_flag='github.com/GeneJie199/infrastructure-discovery/pkg/infrascout.Version' if command=='infrascout' else 'main.version'
        for platform,asset in component['assets'].items():
            goos,arch=platform.split('-');name=command+'-'+platform+('.exe' if goos=='windows' else '')
            target=WORK/'cache'/component['repository']/component['tag']/name;target.parent.mkdir(parents=True,exist_ok=True)
            env={**os.environ,'GOTOOLCHAIN':'go1.27.3','GOOS':goos,'GOARCH':arch,'CGO_ENABLED':'0'}
            print('BUILD',component['repository'],platform,flush=True)
            run(['go','build','-trimpath','-ldflags',f'-s -w -X {version_flag}={version}','-o',str(target),'./cmd/'+command],repo,env)
            asset.update(name=name,sha256=hashlib.sha256(target.read_bytes()).hexdigest())
            records.append({'component':command,'platform':platform,'sha256':asset['sha256'],'result':'build-passed'})
    protocol=manifest['protocol'];protocol.update(version=version,tag='v'+version,asset='lifecycle-spec-v'+version+'.tar.gz')
    repo=ROOT.parent/'lifecycle-spec';archive=WORK/'cache'/protocol['repository']/protocol['tag']/protocol['asset'];archive.parent.mkdir(parents=True,exist_ok=True)
    paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=repo).decode('utf-8').split('\0')
    with tarfile.open(archive,'w:gz') as tar:
        for relative in sorted(set(paths)):
            if relative and (repo/relative).is_file():tar.add(repo/relative,arcname='lifecycle-spec/'+relative,recursive=False)
    protocol['sha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    manifest['sources']=[]
    source_repos=[ROOT]+[ROOT.parent/item['repository'] for item in manifest['components']]
    for repo in source_repos:
        slug='ai-devops-open-suite' if repo==ROOT else repo.name
        verify_revisions(revisions)
        revision=revisions[repo]
        source=WORK/'cache'/slug/('v'+version)/(slug+'-'+revision[:12]+'-source.tar.gz');source.parent.mkdir(parents=True,exist_ok=True)
        committed_source=subprocess.check_output(['git','archive','--format=tar',revision],cwd=repo)
        vendor=WORK/'vendor'/slug
        if (repo/'go.mod').exists():
            print('SOURCE',slug,'including vendored build dependencies',flush=True)
            run(['go','mod','vendor','-o',str(vendor)],repo,{**os.environ,'GOTOOLCHAIN':'go1.27.3'})
        with tarfile.open(source,'w:gz') as tar:
            with tarfile.open(fileobj=io.BytesIO(committed_source),mode='r:') as committed:
                for member in committed.getmembers():
                    content=committed.extractfile(member) if member.isfile() else None
                    member.name=slug+'/'+member.name
                    tar.addfile(member,content)
            if vendor.is_dir():tar.add(vendor,arcname=slug+'/vendor')
        manifest['sources'].append({'repository':slug,'tag':'v'+version,'revision':revision,'asset':source.name,'sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
    verify_revisions(revisions)
    for platform in manifest['platforms'].values():platform['verificationLevel']='build-tested'
    manifest['platforms']['windows-amd64']['verificationLevel']='build-tested'
    path=WORK/'suite-manifest.json';path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    (WORK/'cross-build-report.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
    run(['python',str(ROOT/'scripts/build-offline-bundle.py'),'--manifest',str(path),'--platform',args.platform,'--output',str(WORK),'--cache',str(WORK/'cache')],ROOT)
    extension='zip' if args.platform.startswith('windows-') else 'tar.gz'
    run(['python',str(ROOT/'scripts/verify-offline-bundle.py'),str(WORK/f'ai-devops-open-suite-full-offline-v{version}-{args.platform}.{extension}')],ROOT)

if __name__=='__main__':main()
