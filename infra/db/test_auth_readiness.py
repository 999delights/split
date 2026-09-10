import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('readiness', Path(__file__).with_name('auth_readiness.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReadinessTests(unittest.TestCase):
    def test_missing_configuration_does_not_connect(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(module.subprocess, 'run') as run:
            report = module.inspect('statz', Path(folder))
            self.assertIn('SMTP_PASSWORD', report['missing_settings'])
            self.assertEqual(report['database_status'], 'not_checked')
            run.assert_not_called()

    def test_wrong_database_never_connects_and_secrets_never_escape(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(module.subprocess, 'run') as run:
            root = Path(folder)
            (root / 'statz.database.env').write_text('APP_DB_NAME=prod_statz_db\nAPP_DB_PASSWORD=private-db-password\n')
            (root / 'statz.identity.env').write_text('SMTP_PASSWORD=private-smtp-password\n')
            report = module.inspect('statz', root)
            self.assertFalse(report['database_matches'])
            self.assertNotIn('private-', json.dumps(report))
            run.assert_not_called()

    def test_failed_database_command_output_is_suppressed(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(module.subprocess, 'run') as run:
            root = Path(folder)
            (root / 'statz.database.env').write_text('APP_DB_NAME=dev_statz_db\n')
            run.return_value.returncode = 1
            run.return_value.stderr = 'password=do-not-print'
            report = module.inspect('statz', root)
            self.assertEqual(report['database_status'], 'check_failed')
            self.assertNotIn('do-not-print', json.dumps(report))
            self.assertIn('db:status', run.call_args.args[0])


if __name__ == '__main__':
    unittest.main()
