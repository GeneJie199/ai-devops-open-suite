#!/usr/bin/env python3
"""Regression coverage for source identity and offline source acquisition."""
import hashlib
import importlib.util
import io
import pathlib
import subprocess
import tempfile
import unittest
from unittest import mock

from suite_manifest import ManifestError, load_manifest

ROOT = pathlib.Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / (name + '.py'))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


development = module('build-v2-development')
offline = module('build-offline-bundle')
verifier = module('verify-offline-bundle')


class SourceIntegrityTest(unittest.TestCase):
    def test_development_builder_version_and_platform_options(self):
        defaults = development.parse_args([])
        self.assertEqual((defaults.version, defaults.platform), ('2.0.0-dev', 'windows-amd64'))
        for platform in ('linux-amd64', 'darwin-arm64'):
            args = development.parse_args(['--version', '2.0.0-rc.1', '--platform', platform])
            self.assertEqual((args.version, args.platform), ('2.0.0-rc.1', platform))

    def test_dirty_or_changed_source_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = pathlib.Path(temporary)
            def git(*args):
                return subprocess.check_output(['git', *args], cwd=repo, stderr=subprocess.DEVNULL)
            git('init')
            (repo / 'source.txt').write_text('committed')
            git('add', '.')
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-m', 'initial')
            revision = development.clean_revision(repo)
            development.verify_revisions({repo: revision})
            (repo / 'source.txt').write_text('changed')
            with self.assertRaisesRegex(RuntimeError, 'source changes'):
                development.clean_revision(repo)
            git('checkout', '--', 'source.txt')
            (repo / 'untracked.go').write_text('package example')
            with self.assertRaisesRegex(RuntimeError, 'source changes'):
                development.clean_revision(repo)
            (repo / 'untracked.go').unlink()
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '--allow-empty', '-m', 'next')
            with self.assertRaisesRegex(RuntimeError, 'revision changed'):
                development.verify_revisions({repo: revision})

    def build_fixture(self, temporary, channel):
        manifest = load_manifest(ROOT / 'suite-manifest.json')
        manifest['channel'] = channel
        cache = pathlib.Path(temporary) / 'cache'
        output = pathlib.Path(temporary) / 'output'
        output.mkdir()
        payload = b'fixture binary or protocol'
        digest = hashlib.sha256(payload).hexdigest()
        assets = [(c['repository'], c['tag'], c['assets']['windows-amd64']) for c in manifest['components']]
        protocol = manifest['protocol']
        assets.append((protocol['repository'], protocol['tag'], {'name': protocol['asset'], 'sha256': digest}))
        protocol['sha256'] = digest
        for repository, tag, asset in assets:
            asset['sha256'] = digest
            target = cache / repository / tag / asset['name']
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(payload)
        source = b'published corresponding source fixture'
        manifest['sources'] = [{'repository': 'release-validation', 'tag': 'v2.0.0-rc.1', 'revision': 'a' * 40,
                                'asset': 'source.tar.gz', 'sha256': hashlib.sha256(source).hexdigest()}]
        return manifest, cache, output, source

    def test_published_source_download_is_verified_and_bundled(self):
        with tempfile.TemporaryDirectory() as temporary:
            manifest, cache, output, source = self.build_fixture(temporary, 'prerelease')
            response = io.BytesIO(source)
            response.url = 'https://release-assets.githubusercontent.com/source'
            with mock.patch.object(offline.urllib.request, 'urlopen', return_value=response) as request:
                archive = offline.build(manifest, 'windows-amd64', output, cache)
            self.assertIn('/release-validation/releases/download/v2.0.0-rc.1/source.tar.gz', request.call_args.args[0].full_url)
            verifier.verify_archive(archive)

    def test_development_missing_source_never_downloads(self):
        with tempfile.TemporaryDirectory() as temporary:
            manifest, cache, output, _ = self.build_fixture(temporary, 'development')
            with mock.patch.object(offline.urllib.request, 'urlopen') as request:
                with self.assertRaises(ManifestError):
                    offline.build(manifest, 'windows-amd64', output, cache)
                request.assert_not_called()

    def test_published_source_bad_hash_or_host_is_rejected(self):
        for url, payload in [('https://release-assets.githubusercontent.com/source', b'tampered'),
                             ('https://untrusted.example/source', b'anything')]:
            with self.subTest(url=url), tempfile.TemporaryDirectory() as temporary:
                manifest, cache, output, _ = self.build_fixture(temporary, 'prerelease')
                response = io.BytesIO(payload)
                response.url = url
                with mock.patch.object(offline.urllib.request, 'urlopen', return_value=response):
                    with self.assertRaises(ManifestError):
                        offline.build(manifest, 'windows-amd64', output, cache)
                self.assertFalse(list(output.glob('*.zip')))
                self.assertFalse(list(cache.rglob('*.part')))


if __name__ == '__main__':
    unittest.main()
