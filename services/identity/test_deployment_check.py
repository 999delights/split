from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from .deployment_check import check


class DeploymentCheckTests(unittest.TestCase):
    def test_rejects_other_environments_before_loading(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'identity.env'
            for environment in ('staging', 'production', ''):
                path.write_text('APP_ENV=' + environment)
                with patch('services.identity.deployment_check.load_config') as load:
                    with self.assertRaises(ValueError):
                        check(path, 'unused')
                    load.assert_not_called()

    def test_development_validates_without_connecting(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'identity.env'
            path.write_text('APP_ENV=development')
            with patch('services.identity.deployment_check.load_config') as load:
                check(path, 'database.env')
                load.assert_called_once_with('split', path, 'database.env')
                load.return_value.engine.connect.assert_not_called()
                load.return_value.engine.dispose.assert_called_once()
