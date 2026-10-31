import importlib.util,json,pathlib,shutil,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('guard',ROOT/'scripts/license-guard.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)

class LicenseGuardTest(unittest.TestCase):
    def fixture(self):
        temporary=tempfile.TemporaryDirectory();self.addCleanup(temporary.cleanup);root=pathlib.Path(temporary.name)
        for name in ['LICENSE','NOTICE','LICENSE_POLICY.md','COMMERCIAL_LICENSE.md','COMMERCIALIZATION.md','TRADEMARK_POLICY.md','CONTRIBUTOR_POLICY.md','LICENSING_HISTORY.md','THIRD_PARTY_NOTICES.md','LICENSE_METADATA.json','README.md','third-party.cdx.json']:
            shutil.copy2(ROOT/name,root/name)
        shutil.copytree(ROOT/'LICENSES',root/'LICENSES')
        shutil.copy2(ROOT/'third-party-inventory.json',root/'third-party-inventory.json')
        return root
    def test_license_metadata_mismatch(self):
        root=self.fixture();self.assertFalse(guard.check(root));(root/'README.md').write_text('wrong license',encoding='utf-8');self.assertIn('README license mismatch',guard.check(root))
    def test_tampered_dependency_notice(self):
        root=self.fixture();inventory=json.loads((root/'third-party-inventory.json').read_text(encoding='utf-8'));item=next(m['licenseFiles'][0] for m in inventory['modules'] if m['licenseFiles']);target=root/item['path'];target.chmod(0o644);target.write_text('tampered',encoding='utf-8');self.assertTrue(any('evidence mismatch' in e for e in guard.check(root)))
    def test_standard_full_license_required(self):
        root=self.fixture();(root/'LICENSE').write_text('AGPL summary is not a license',encoding='utf-8');self.assertTrue(any('AGPL text' in e for e in guard.check(root)))

if __name__=='__main__':unittest.main()
