#!/usr/bin/env python3
"""Collect reproducible license evidence from downloaded Go modules and vendored assets.

No network access: run go mod download separately when authorized. Unknown results warn.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]

def copy_notice(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists(): target.chmod(0o644)
    target.write_bytes(source.read_bytes())

def json_stream(raw):
    decoder = json.JSONDecoder()
    while raw.strip():
        raw = raw.lstrip()
        value, end = decoder.raw_decode(raw)
        yield value
        raw = raw[end:]

def identify(text):
    if 'GNU AFFERO GENERAL PUBLIC LICENSE' in text: return 'AGPL-3.0-only'
    if 'Apache License' in text and 'Version 2.0' in text: return 'Apache-2.0'
    if 'Mozilla Public License' in text and '2.0' in text: return 'MPL-2.0'
    if 'Permission is hereby granted, free of charge' in text: return 'MIT'
    if 'ISC License' in text: return 'ISC'
    if 'Redistribution and use in source and binary forms' in text:
        return 'BSD-3-Clause' if ('Neither the name' in text or 'Neither the names' in text) else 'BSD-2-Clause'
    if 'public domain' in text.lower(): return 'LicenseRef-Public-Domain-Review'
    return 'NOASSERTION'

def collect(repos, output):
    output.mkdir(parents=True, exist_ok=True)
    modules = {}
    warnings = []
    for repo in repos:
        if not (repo/'go.mod').exists(): continue
        raw = subprocess.check_output(['go','list','-m','-json','all'],cwd=repo,text=True,encoding='utf-8')
        for mod in json_stream(raw):
            if mod.get('Main'): continue
            key = mod['Path']+'@'+mod.get('Version','unknown')
            entry = modules.setdefault(key, {'module':mod['Path'],'version':mod.get('Version'),'usedBy':[],'licenseFiles':[],'license':'NOASSERTION'})
            entry['usedBy'].append(repo.name)
            if entry['licenseFiles']: continue
            directory = pathlib.Path(mod.get('Dir','__missing_module__'))
            if not directory.is_dir():
                warnings.append(f'{key}: source unavailable; run go mod download for notice collection')
                continue
            safe = re.sub(r'[^A-Za-z0-9._-]','_',key)
            for file in sorted(directory.rglob('*')):
                if not file.is_file() or file.suffix.lower() in {'.go','.c','.h','.cc','.cpp','.js','.ts','.py','.java','.json','.yaml','.yml','.sum','.mod','.sh'} or not re.match(r'^(LICENSE|LICENCE|COPYING|NOTICE|COPYRIGHT|AUTHORS|PATENTS)([._-].*)?$',file.name,re.I): continue
                relative = file.relative_to(directory)
                target = output/'LICENSES'/'third-party'/safe/relative
                target.parent.mkdir(parents=True,exist_ok=True)
                copy_notice(file,target)
                data = file.read_bytes()
                found = identify(data.decode('utf-8',errors='replace'))
                if entry['license']=='NOASSERTION' and found!='NOASSERTION': entry['license']=found
                entry['licenseFiles'].append({'path':target.relative_to(output).as_posix(),'sha256':hashlib.sha256(data).hexdigest()})
            if entry['license']=='NOASSERTION': warnings.append(f'{key}: license identification needs review')
    for repo in repos:
        for file in repo.glob('internal/web/static/vendor/*LICENSE*'):
            target=output/'LICENSES'/'third-party'/repo.name/file.name
            target.parent.mkdir(parents=True,exist_ok=True);copy_notice(file,target)
            key=repo.name+'/vendored-lucide'
            modules[key]={'module':'lucide+feather','version':'vendored','usedBy':[repo.name],'license':'ISC AND MIT','licenseFiles':[{'path':target.relative_to(output).as_posix(),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}]}
    goroot=pathlib.Path(subprocess.check_output(['go','env','GOROOT'],text=True,encoding='utf-8').strip())
    for name in ['LICENSE','PATENTS']:
        if (goroot/name).is_file():
            target=output/'LICENSES'/'third-party'/'go-runtime'/name;target.parent.mkdir(parents=True,exist_ok=True);copy_notice(goroot/name,target)
    inventory={'schemaVersion':'ai-devops.license-inventory/v1','projectLicense':'AGPL-3.0-only','modules':[modules[k] for k in sorted(modules)],'warnings':sorted(set(warnings)),'limitations':['Heuristic license identification; inspect preserved text and SPDX exceptions before public redistribution.','Dependency graph includes build/test dependencies; this is not a claim every module is linked into every binary.']}
    (output/'third-party-inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
    components=[]
    for entry in inventory['modules']:
        license=entry['license']; item={'type':'library','name':entry['module'],'version':entry['version'],'licenses':[{'license':{'name':license}}],'properties':[{'name':'license:evidence','value':json.dumps(entry['licenseFiles'])}]}
        components.append(item)
    sbom={'bomFormat':'CycloneDX','specVersion':'1.5','version':1,'metadata':{'component':{'type':'application','name':'ai-devops-open-suite','version':'2.0.0-dev','licenses':[{'license':{'id':'AGPL-3.0-only'}}]}},'components':components}
    (output/'third-party.cdx.json').write_text(json.dumps(sbom,indent=2)+'\n',encoding='utf-8')
    print(f'License evidence: {len(modules)} dependencies/assets; {len(set(warnings))} warnings')
    for warning in sorted(set(warnings)): print('WARNING:',warning)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=pathlib.Path,default=ROOT);parser.add_argument('repos',nargs='*',type=pathlib.Path);args=parser.parse_args()
    collect(args.repos or [ROOT.parent/name for name in ['ai-dev-cycle-manager','infrastructure-discovery','fleet-observability','release-validation','lifecycle-spec']],args.output)
