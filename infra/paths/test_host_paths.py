"""host_paths.py against the cases hostPaths.test.cjs also runs (cases.json), so both readers agree."""
import json
import os
import unittest
from pathlib import Path
from unittest.mock import patch

from infra.paths.host_paths import host_path, host_tool

CASES = json.loads(Path(__file__).with_name('cases.json').read_text(encoding='utf-8'))


def resolve(case):
    options = {'env': case['env'], 'platform': case['platform']}
    if 'tool' in case:
        return host_tool(case['tool'], **options)
    return host_path(case['root'], *case['parts'], **options)


class HostPathsTest(unittest.TestCase):
    def test_cases(self):
        for case in CASES:
            with self.subTest(case['about']):
                if 'error' in case:
                    with self.assertRaises((RuntimeError, ValueError)) as caught:
                        resolve(case)
                    for word in case['error']:
                        self.assertIn(word, str(caught.exception))
                else:
                    self.assertEqual(resolve(case), case['expect'])

    def test_reads_the_process_environment_on_each_call(self):
        with patch.dict(os.environ, {'TD_SECRETS_ROOT': os.path.join('fixture', 'vault')}):
            self.assertEqual(host_path('secrets', 'development'), os.path.join('fixture', 'vault', 'development'))


if __name__ == '__main__':
    unittest.main()
