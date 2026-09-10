import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('db',Path(__file__).with_name('db.py'))
db=importlib.util.module_from_spec(spec);spec.loader.exec_module(db)
class LedgerTests(unittest.TestCase):
 def test_second_run_is_noop(self):
  self.assertEqual(db.reconcile([('001_test','abc','SELECT 1')],{'001_test':'abc'}),[])
 def test_changed_applied_sql_rejected(self):
  with self.assertRaisesRegex(ValueError,'checksum'):db.reconcile([('001_test','changed','')],{'001_test':'abc'})
 def test_unknown_history_never_reapplied(self):
  with self.assertRaisesRegex(ValueError,'unadopted'):db.reconcile([],{'001_legacy':'abc'})
 def test_null_legacy_checksum_rejected(self):
  with self.assertRaisesRegex(ValueError,'checksum'):db.reconcile([('001_test','abc','')],{'001_test':None})
if __name__=='__main__':unittest.main()
