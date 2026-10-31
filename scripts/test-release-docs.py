#!/usr/bin/env python3
"""Exercise the actual offline archive against README's local-link closure."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / filename)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class DocumentationArchiveTests(unittest.TestCase):
    def test_readme_links_survive_archive_and_platform_assets_remain_intact(self):
        builder = module('documentation_bundle', 'build-offline-bundle.py')
        checker = module('documentation_links', 'check-docs.py')
        manifest = json.loads((ROOT / 'suite-manifest.json').read_text(encoding='utf-8'))
        manifest = copy.deepcopy(manifest)
        manifest['sources'] = []
        manifest['channel'] = 'development'
        payload = b'documentation-test fixture; never executed as a product'
        digest = hashlib.sha256(payload).hexdigest()
        for component in manifest['components']:
            for asset in component['assets'].values():
                asset['sha256'] = digest
        manifest['protocol']['sha256'] = digest
        with tempfile.TemporaryDirectory(prefix='suite-doc-archive-') as temporary:
            work = Path(temporary)
            fixture = work / 'fixture'
            fixture.write_bytes(payload)
            builder.obtain = lambda *args, **kwargs: fixture
            archive = builder.build(manifest, 'windows-amd64', work, work / 'cache')
            with zipfile.ZipFile(archive) as bundle:
                names = set(bundle.namelist())
                prefix = 'ai-devops-open-suite/'
                queue, visited, targets = [ROOT / 'README.md'], set(), set()
                while queue:
                    markdown = queue.pop()
                    if markdown in visited:
                        continue
                    visited.add(markdown)
                    for match in checker.LINK.finditer(markdown.read_text(encoding='utf-8')):
                        target = checker.local_target(markdown, match.group(1))
                        if target is None:
                            continue
                        relative = target.relative_to(ROOT).as_posix()
                        targets.add(relative)
                        member = prefix + relative
                        if target.is_dir():
                            self.assertTrue(any(name.startswith(member.rstrip('/') + '/') for name in names), relative)
                        else:
                            self.assertIn(member, names, f'{markdown.name}: {relative}')
                            self.assertEqual(bundle.read(member), target.read_bytes(), relative)
                        if target.suffix == '.md':
                            queue.append(target)
                self.assertGreaterEqual(len(targets), 26)
                for component in manifest['components']:
                    name = component['assets']['windows-amd64']['name']
                    self.assertEqual(bundle.read(prefix + 'assets/windows-amd64/' + name), payload)


if __name__ == '__main__':
    unittest.main()
