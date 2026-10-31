#!/usr/bin/env python3

from __future__ import annotations

import copy
import pathlib
import unittest

from suite_manifest import ManifestError, load_manifest, render_index, validate_manifest


ROOT = pathlib.Path(__file__).resolve().parent.parent


class SuiteManifestTest(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = load_manifest(ROOT / "suite-manifest.json")

    def test_every_index_is_deterministic_and_complete(self) -> None:
        for platform in self.manifest["platforms"]:
            index = render_index(self.manifest, platform)
            self.assertTrue(index.startswith("suite|ai-devops.suite-manifest/v1|"))
            self.assertEqual(index.count("\n"), len(self.manifest["components"]) + 2)

    def test_path_traversal_asset_is_rejected(self) -> None:
        value = copy.deepcopy(self.manifest)
        value["components"][0]["assets"]["linux-amd64"]["name"] = "../payload"
        with self.assertRaises(ManifestError):
            validate_manifest(value)

    def test_missing_platform_is_rejected(self) -> None:
        value = copy.deepcopy(self.manifest)
        del value["components"][0]["assets"]["darwin-arm64"]
        with self.assertRaises(ManifestError):
            validate_manifest(value)

    def test_invalid_digest_is_rejected(self) -> None:
        value = copy.deepcopy(self.manifest)
        value["protocol"]["sha256"] = "not-a-digest"
        with self.assertRaises(ManifestError):
            validate_manifest(value)

    def test_source_archive_traversal_is_rejected(self) -> None:
        value = copy.deepcopy(self.manifest)
        value["sources"] = [{"repository":"devcycle","tag":"v2.0.0-dev","revision":"a"*40,"asset":"../source.tar.gz","sha256":"0"*64}]
        with self.assertRaises(ManifestError):
            validate_manifest(value)


if __name__ == "__main__":
    unittest.main()
