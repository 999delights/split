from pathlib import Path
import tempfile
import unittest
from .provision import provision
from .runtime import load_config


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.smtp = self.root / 'smtp.env'
        self.smtp.write_text("SMTP_HOST=smtp.example.invalid\nSMTP_USER=test\nSMTP_PASSWORD=synthetic-password\nSMTP_PORT=465\nSMTP_SECURE=true\n")
        (self.root / 'bliss.database.env').write_text('APP_DB_NAME=dev_bliss_db\nAPP_DB_USER=test\nAPP_DB_PASSWORD=synthetic\nAPP_DB_HOST=127.0.0.1\nAPP_DB_PORT=3306\n')

    def prepare(self):
        return provision('bliss', self.root, self.root, self.smtp,
                         'https://example.invalid/api/auth', ['google-test'], ['apple-test'],
                         'sender@example.invalid', 'tester@example.invalid')

    def test_prepares_without_connecting_and_never_overwrites(self):
        self.assertFalse(self.prepare()['activated'])
        config = self.root / 'bliss.identity.env'
        original = config.read_bytes()
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

    def test_invalid_tls_source_writes_nothing(self):
        with self.smtp.open('a') as f:
            f.write('SMTP_ALLOW_INVALID_CERTS=true\n')
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertEqual(list(self.root.glob('*.key')), [])

    def test_runtime_validation_failure_removes_only_new_files(self):
        db = self.root / 'bliss.database.env'
        db.write_text('APP_DB_NAME=dev_bliss_db\n')
        with self.assertRaises(KeyError):
            self.prepare()
        self.assertTrue(db.exists())
        self.assertTrue(self.smtp.exists())
        self.assertFalse((self.root / 'bliss.identity.env').exists())
        self.assertEqual(list(self.root.glob('*.key')), [])


if __name__ == '__main__':
    unittest.main()
