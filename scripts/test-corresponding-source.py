#!/usr/bin/env python3
"""Exercise the source helper against isolated committed fixtures; no network."""
from pathlib import Path
import json
import os
import runpy
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
import zipfile

HELPER = Path(__file__).with_name('package-corresponding-source.py')


class CorrespondingSourceTest(unittest.TestCase):
    def run_cmd(self, args, cwd, env=None, check=True):
        return subprocess.run(args, cwd=cwd, env=env, check=check, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def fixture(self, root, go=False):
        repo = root / 'repo'
        (repo / 'scripts').mkdir(parents=True)
        shutil.copy2(HELPER, repo / 'scripts' / HELPER.name)
        (repo / 'LICENSE_METADATA.json').write_text(json.dumps({
            'sourceLicense': 'AGPL-3.0-only', 'sourceVersion': '2.0.0-rc.1'}))
        (repo / 'LICENSE').write_text('test fixture license\n')
        (repo / 'exact.txt').write_bytes(b'committed source\n')
        env = dict(os.environ, GOTOOLCHAIN='local', GOSUMDB='off', GOWORK='off')
        if go:
            proxy = root / 'proxy' / 'example.com' / 'library' / '@v'
            proxy.mkdir(parents=True)
            mod = b'module example.com/library\n\ngo 1.22\n'
            (proxy / 'v1.0.0.mod').write_bytes(mod)
            (proxy / 'v1.0.0.info').write_text('{"Version":"v1.0.0","Time":"2026-01-01T00:00:00Z"}')
            (proxy / 'list').write_text('v1.0.0\n')
            with zipfile.ZipFile(proxy / 'v1.0.0.zip', 'w') as archive:
                archive.writestr('example.com/library@v1.0.0/go.mod', mod)
                archive.writestr('example.com/library@v1.0.0/library.go', 'package library\nfunc Value() string { return "vendored-" }\n')
                archive.writestr('example.com/library@v1.0.0/LICENSE', 'fixture dependency license\n')
            env.update(GOPROXY=(root / 'proxy').as_uri(), GOMODCACHE=str(root / 'download-cache'))
            (repo / 'go.mod').write_text('module github.com/GeneJie199/ai-dev-cycle-manager\n\ngo 1.22\n\nrequire example.com/library v1.0.0\n')
            command = repo / 'cmd' / 'devcycle'
            command.mkdir(parents=True)
            (command / 'main.go').write_text('package main\nimport ("fmt"; "example.com/library")\nvar version = "dev"\nfunc main() { fmt.Println(library.Value()+version) }\n')
            self.run_cmd(['go', 'mod', 'tidy'], repo, env)
        self.run_cmd(['git', 'init', '-q'], repo)
        self.run_cmd(['git', 'add', '.'], repo)
        self.run_cmd(['git', '-c', 'user.name=Source Test', '-c', 'user.email=source@example.invalid',
                      'commit', '-qm', 'source fixture'], repo)
        return repo, env

    def package(self, repo, output, env, check=True):
        return self.run_cmd([sys.executable, str(repo / 'scripts' / HELPER.name),
                             '--output', str(output)], repo, env, check)

    def test_exact_head_and_dirty_rejection(self):
        with tempfile.TemporaryDirectory(prefix='source-test-') as directory:
            root = Path(directory)
            repo, env = self.fixture(root)
            (repo / 'untracked.txt').write_text('must not enter source archive')
            output = root / 'source.tar.gz'
            self.package(repo, output, env)
            with tarfile.open(output) as archive:
                self.assertNotIn('untracked.txt', archive.getnames())
                self.assertEqual(archive.extractfile('exact.txt').read(), subprocess.check_output(
                    ['git', 'show', 'HEAD:exact.txt'], cwd=repo))
                info = json.load(archive.extractfile('SOURCE_PROVENANCE.json'))
                self.assertEqual(info['revision'], self.run_cmd(['git', 'rev-parse', 'HEAD'], repo).stdout.strip())
                self.assertEqual(info['buildArgs'], [])
                self.assertIn('Script-only Suite launcher', info['build'])
            (repo / 'exact.txt').write_text('dirty')
            result = self.package(repo, root / 'dirty.tar.gz', env, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('clean committed checkout', result.stderr)
            self.assertFalse((root / 'dirty.tar.gz').exists())

    def test_vendored_offline_build_from_archived_head(self):
        with tempfile.TemporaryDirectory(prefix='source-go-test-') as directory:
            root = Path(directory)
            repo, env = self.fixture(root, go=True)
            # This untracked import would break vendoring from the live checkout.
            (repo / 'cmd' / 'devcycle' / 'untracked.go').write_text('package main\nimport _ "invalid.example/untracked"\n')
            output = root / 'source.tar.gz'
            self.package(repo, output, env)
            extracted = root / 'extracted'
            with tarfile.open(output) as archive:
                self.assertIn('vendor/example.com/library/library.go', archive.getnames())
                self.assertIn('vendor/example.com/library/LICENSE', archive.getnames())
                self.assertNotIn('cmd/devcycle/untracked.go', archive.getnames())
                archive.extractall(extracted, filter='data')
            info = json.loads((extracted / 'SOURCE_PROVENANCE.json').read_text())
            offline = dict(env, GOPROXY='off', GOSUMDB='off', GOMODCACHE=str(root / 'offline-empty-cache'),
                           **info['buildEnvironment'])
            args = info['buildArgs'][:]
            if os.name == 'nt':
                args[args.index('-o') + 1] += '.exe'
            self.run_cmd(args, extracted, offline)
            binary = extracted / args[args.index('-o') + 1]
            self.assertTrue(binary.is_file())
            self.assertEqual(self.run_cmd([str(binary)], extracted, offline).stdout.strip(),
                             'vendored-2.0.0-rc.1')
            self.assertFalse((root / 'offline-empty-cache').exists())

    def test_each_product_build_recipe(self):
        helper = runpy.run_path(str(HELPER))
        with tempfile.TemporaryDirectory(prefix='source-recipes-') as directory:
            snapshot = Path(directory)
            (snapshot / 'LICENSE_METADATA.json').write_text('{"sourceLicense":"AGPL-3.0-only","sourceVersion":"2.0.0-rc.1"}')
            for module, (binary, symbol) in helper['PRODUCTS'].items():
                with self.subTest(module=module):
                    (snapshot / 'go.mod').write_text('module github.com/GeneJie199/' + module + '\n')
                    info = helper['provenance'](snapshot, 'a' * 40)
                    self.assertEqual(info['buildArgs'][-1], './cmd/' + binary)
                    self.assertEqual(info['buildArgs'][-2], 'dist/' + binary)
                    flags = info['buildArgs'][info['buildArgs'].index('-ldflags') + 1]
                    self.assertEqual(flags, '-s -w' + (' -X ' + symbol + '=2.0.0-rc.1' if symbol else ''))


if __name__ == '__main__':
    unittest.main()
