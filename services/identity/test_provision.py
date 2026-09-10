from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import os
from .provision import provision
from .runtime import load_config


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        env = patch.dict(os.environ, {'SMTP_HOST':'smtp.example.invalid', 'SMTP_USER':'test', 'SMTP_PASSWORD':'synthetic-password', 'SMTP_PORT':'465', 'SMTP_SECURITY':'ssl'})
        env.start()
        self.addCleanup(env.stop)
        (self.root / 'bliss.database.env').write_text('APP_DB_NAME=dev_bliss_db\nAPP_DB_USER=test\nAPP_DB_PASSWORD=synthetic\nAPP_DB_HOST=127.0.0.1\nAPP_DB_PORT=3306\n')

    def prepare(self):
        return provision('bliss', self.root, self.root,
                         'https://example.invalid/api/auth', ['google-test'], ['apple-test'],
                         'sender@example.invalid', 'tester@example.invalid')

    def test_prepares_without_connecting_and_never_overwrites(self):
        self.assertFalse(self.prepare()['activated'])
        config = self.root / 'bliss.identity.env'
        original = config.read_bytes()
        self.assertNotIn(b'synthetic-password', original)
        self.assertNotIn(b'SMTP_USER=', original)
        self.assertNotIn(b'SMTP_PASSWORD=', original)
        identity = load_config('bliss', config, self.root / 'bliss.database.env')
        self.assertEqual(identity.config['smtp_security'], 'ssl')
        self.assertEqual(identity.config['mail_allowlist'], ['tester@example.invalid'])
        identity.engine.dispose()
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertEqual(config.read_bytes(), original)

    def test_wrong_environment_writes_nothing(self):
        db = self.root / 'bliss.database.env'
        db.write_text(db.read_text().replace('dev_bliss_db', 'prod_bliss_db'))
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertFalse((self.root / 'bliss.identity.env').exists())
        self.assertEqual(list(self.root.glob('*.key')), [])

    def test_missing_smtp_environment_writes_nothing(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ValueError):
                self.prepare()
        self.assertEqual(list(self.root.glob('*.key')), [])

    def test_runtime_validation_failure_removes_only_new_files(self):
        db = self.root / 'bliss.database.env'
        db.write_text('APP_DB_NAME=dev_bliss_db\n')
        with self.assertRaises(KeyError):
            self.prepare()
        self.assertTrue(db.exists())
        self.assertFalse((self.root / 'bliss.identity.env').exists())
        self.assertEqual(list(self.root.glob('*.key')), [])


if __name__ == '__main__':
    unittest.main()
